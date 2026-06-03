import os
import json
import sqlite3
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from wakeonlan import send_magic_packet


load_dotenv()

DB_PATH = Path("edge_queue.sqlite3")

EDGE_DRY_RUN = os.getenv("EDGE_DRY_RUN", "true").lower() == "true"
HOST_CHECK_URL = os.getenv("HOST_CHECK_URL", "http://127.0.0.1:3010")

PROXMOX_WAKE_MAC = os.getenv("PROXMOX_WAKE_MAC", "")
PROXMOX_WAKE_BROADCAST = os.getenv("PROXMOX_WAKE_BROADCAST", "192.168.0.255")
PROXMOX_WAKE_PORT = int(os.getenv("PROXMOX_WAKE_PORT", "9"))

AI_PLATFORM_BASE_URL = os.getenv("AI_PLATFORM_BASE_URL", "http://127.0.0.1:3010")
AI_PLATFORM_EDGE_INGEST_URL = os.getenv(
    "AI_PLATFORM_EDGE_INGEST_URL",
    f"{AI_PLATFORM_BASE_URL.rstrip()}/api/backend/internal/edge/jobs",
)
EDGE_SHARED_SECRET = os.getenv("EDGE_SHARED_SECRET", "")
EDGE_FORWARD_JOBS = os.getenv("EDGE_FORWARD_JOBS", "false").lower() == "true"
EDGE_WAKE_ENABLED = os.getenv("EDGE_WAKE_ENABLED", "false").lower() == "true"
HEARTBEAT_SHARED_SECRET = os.getenv("HEARTBEAT_SHARED_SECRET", "")

WORKER_START_ENABLED = os.getenv("WORKER_START_ENABLED", "false").lower() == "true"
WORKER_START_DRY_RUN = os.getenv("WORKER_START_DRY_RUN", "true").lower() == "true"
WORKER_START_SSH_HOST = os.getenv("WORKER_START_SSH_HOST", "")
WORKER_START_SSH_USER = os.getenv("WORKER_START_SSH_USER", "root")
WORKER_START_SSH_KEY = os.getenv("WORKER_START_SSH_KEY", "")
WORKER_START_COMMAND = os.getenv("WORKER_START_COMMAND", "/usr/local/sbin/ai-platform-start-worker")

app = FastAPI(
    title="Edge Queue Controller",
    version="0.1.0",
    description="Always-on edge queue and future Wake-on-LAN controller.",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS jobs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                job_type TEXT NOT NULL,
                prompt TEXT NOT NULL,
                requested_model TEXT,
                status TEXT NOT NULL DEFAULT 'queued',
                attempts INTEGER NOT NULL DEFAULT 0,
                last_error TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                forwarded_at TEXT
            )
            """
        )
        conn.commit()


class CreateEdgeJobRequest(BaseModel):
    job_type: str = Field(default="ollama_chat", min_length=1)
    prompt: str = Field(..., min_length=1)
    requested_model: str | None = Field(default="qwen2.5:0.5b")


def row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
    return dict(row)


async def host_is_online() -> tuple[bool, str]:
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(HOST_CHECK_URL)
            return response.status_code < 500, f"HTTP {response.status_code} from {HOST_CHECK_URL}"
    except Exception as exc:
        return False, repr(exc)


def wake_host() -> dict[str, Any]:
    if not PROXMOX_WAKE_MAC:
        return {
            "ok": False,
            "action": "wake_host",
            "reason": "PROXMOX_WAKE_MAC is not configured.",
        }

    if EDGE_DRY_RUN or not EDGE_WAKE_ENABLED:
        return {
            "ok": True,
            "dry_run": True,
            "wake_enabled": EDGE_WAKE_ENABLED,
            "action": "would_send_wake_on_lan",
            "mac": PROXMOX_WAKE_MAC,
            "broadcast": PROXMOX_WAKE_BROADCAST,
            "port": PROXMOX_WAKE_PORT,
        }

    send_magic_packet(
        PROXMOX_WAKE_MAC,
        ip_address=PROXMOX_WAKE_BROADCAST,
        port=PROXMOX_WAKE_PORT,
    )

    return {
        "ok": True,
        "dry_run": False,
        "action": "sent_wake_on_lan",
        "mac": PROXMOX_WAKE_MAC,
        "broadcast": PROXMOX_WAKE_BROADCAST,
        "port": PROXMOX_WAKE_PORT,
    }


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.get("/health")
async def health():
    online, detail = await host_is_online()

    return {
        "ok": True,
        "edge_dry_run": EDGE_DRY_RUN,
        "host_online": online,
        "host_check_url": HOST_CHECK_URL,
        "host_detail": detail,
        "time": utc_now(),
    }


@app.post("/jobs")
def create_job(payload: CreateEdgeJobRequest):
    now = utc_now()

    with db() as conn:
        cur = conn.execute(
            """
            INSERT INTO jobs (
                job_type,
                prompt,
                requested_model,
                status,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, 'queued', ?, ?)
            """,
            (
                payload.job_type,
                payload.prompt,
                payload.requested_model,
                now,
                now,
            ),
        )
        conn.commit()
        job_id = cur.lastrowid

        row = conn.execute("SELECT * FROM jobs WHERE id = ?", (job_id,)).fetchone()

    return {
        "ok": True,
        "job": row_to_dict(row),
    }


@app.get("/jobs")
def list_jobs():
    with db() as conn:
        rows = conn.execute(
            """
            SELECT * FROM jobs
            ORDER BY id DESC
            LIMIT 100
            """
        ).fetchall()

    return {
        "jobs": [row_to_dict(row) for row in rows],
    }


@app.get("/queue/summary")
def queue_summary():
    with db() as conn:
        rows = conn.execute(
            """
            SELECT status, COUNT(*) AS count
            FROM jobs
            GROUP BY status
            """
        ).fetchall()

        latest = conn.execute(
            """
            SELECT * FROM jobs
            ORDER BY id DESC
            LIMIT 10
            """
        ).fetchall()

    counts = {
        "queued": 0,
        "forwarded": 0,
        "failed": 0,
        "total": 0,
    }

    for row in rows:
        counts[row["status"]] = row["count"]
        counts["total"] += row["count"]

    return {
        "counts": counts,
        "latest_jobs": [row_to_dict(row) for row in latest],
    }


def start_host_worker() -> dict[str, Any]:
    if not WORKER_START_ENABLED:
        return {
            "action": "worker_start_skipped",
            "reason": "WORKER_START_ENABLED is false.",
        }

    if not WORKER_START_SSH_HOST:
        return {
            "action": "worker_start_failed",
            "reason": "WORKER_START_SSH_HOST is not configured.",
        }

    ssh_target = f"{WORKER_START_SSH_USER}@{WORKER_START_SSH_HOST}"

    cmd = [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=10",
    ]

    if WORKER_START_SSH_KEY:
        cmd.extend(["-i", WORKER_START_SSH_KEY])

    cmd.extend([ssh_target, WORKER_START_COMMAND])

    if WORKER_START_DRY_RUN:
        return {
            "action": "would_start_worker_over_ssh",
            "dry_run": True,
            "ssh_target": ssh_target,
            "command": WORKER_START_COMMAND,
        }

    try:
        completed = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=60,
            check=False,
        )
    except Exception as exc:
        return {
            "action": "worker_start_failed",
            "error": repr(exc),
        }

    return {
        "action": "worker_start_attempted",
        "returncode": completed.returncode,
        "stdout": completed.stdout[-2000:],
        "stderr": completed.stderr[-2000:],
    }


async def forward_edge_job(job: dict[str, Any]) -> dict[str, Any]:
    if not EDGE_FORWARD_JOBS:
        return {
            "job_id": job["id"],
            "action": "would_forward_job_to_ai_platform",
            "target": AI_PLATFORM_EDGE_INGEST_URL,
            "job_type": job["job_type"],
            "requested_model": job["requested_model"],
            "prompt_preview": job["prompt"][:120],
            "reason": "EDGE_FORWARD_JOBS is false.",
        }

    if not EDGE_SHARED_SECRET:
        return {
            "job_id": job["id"],
            "action": "not_forwarded",
            "target": AI_PLATFORM_EDGE_INGEST_URL,
            "reason": "EDGE_SHARED_SECRET is not configured on the edge controller.",
        }

    payload = {
        "job_type": job["job_type"],
        "requested_model": job["requested_model"],
        "prompt": job["prompt"],
        "edge_job_id": job["id"],
        "source": "laptop-edge-queue",
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                AI_PLATFORM_EDGE_INGEST_URL,
                headers={
                    "Content-Type": "application/json",
                    "X-Edge-Token": EDGE_SHARED_SECRET,
                },
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
    except Exception as exc:
        now = utc_now()
        with db() as conn:
            conn.execute(
                """
                UPDATE jobs
                SET
                  attempts = attempts + 1,
                  last_error = ?,
                  updated_at = ?
                WHERE id = ?
                """,
                (repr(exc), now, job["id"]),
            )
            conn.commit()

        return {
            "job_id": job["id"],
            "action": "forward_failed",
            "target": AI_PLATFORM_EDGE_INGEST_URL,
            "error": repr(exc),
        }

    now = utc_now()
    with db() as conn:
        conn.execute(
            """
            UPDATE jobs
            SET
              status = 'forwarded',
              attempts = attempts + 1,
              last_error = NULL,
              updated_at = ?,
              forwarded_at = ?
            WHERE id = ?
            """,
            (now, now, job["id"]),
        )
        conn.commit()

    return {
        "job_id": job["id"],
        "action": "forwarded_job_to_ai_platform",
        "target": AI_PLATFORM_EDGE_INGEST_URL,
        "host_job": data.get("job"),
    }




def select_best_worker_for_job(job: dict[str, Any]) -> dict[str, Any]:
    """
    Scheduler gate used by /tick.

    If no healthy/capable worker exists, the edge job stays queued.
    This is the first safety gate before true multi-worker routing.
    """
    init_worker_registry_db()

    requirements = estimate_job_requirements(job)

    with db() as conn:
        rows = conn.execute(
            """
            SELECT *
            FROM workers
            ORDER BY worker_id ASC
            """
        ).fetchall()

    workers = [worker_row_to_dict(row) for row in rows]

    candidates = []
    rejected = []

    for worker in workers:
        ok, score, reasons = score_worker_for_job(worker, requirements)

        item = {
            "worker_id": worker.get("worker_id"),
            "name": worker.get("name"),
            "target_name": worker.get("target_name"),
            "computed_health": worker.get("computed_health"),
            "score": score,
            "reasons": reasons,
        }

        if ok:
            candidates.append(item)
        else:
            rejected.append(item)

    candidates.sort(key=lambda item: item["score"])

    return {
        "requirements": requirements,
        "selected_worker": candidates[0] if candidates else None,
        "candidates": candidates,
        "rejected": rejected,
    }

@app.post("/tick")
async def tick():
    """
    Main edge scheduler tick.

    Legacy behavior:
      - Uses HOST_CHECK_URL / legacy 3010 path.

    Direct Ollama behavior, disabled by default:
      - EDGE_TICK_USE_DIRECT_OLLAMA=1 makes /tick use /tick/ollama-direct.
      - EDGE_TICK_AUTO_READY_WORKER=1 lets /tick call the guarded wake/start readiness path first.
      - Actual Ollama forwarding still requires EDGE_DIRECT_OLLAMA_FORWARD=1.
    """
    with db() as conn:
        queued_jobs = conn.execute(
            """
            SELECT * FROM jobs
            WHERE status = 'queued'
            ORDER BY id ASC
            LIMIT 25
            """
        ).fetchall()

    actions: list[dict[str, Any]] = []

    if not queued_jobs:
        online, detail = await host_is_online()

        return {
            "ok": True,
            "edge_dry_run": EDGE_DRY_RUN,
            "host_online": online,
            "host_detail": detail,
            "mode": "nothing_to_do",
            "actions": [
                {
                    "action": "nothing_to_do",
                    "reason": "No queued edge jobs.",
                }
            ],
        }

    use_direct_ollama = _parse_bool_env("EDGE_TICK_USE_DIRECT_OLLAMA", False)
    auto_ready_worker = _parse_bool_env("EDGE_TICK_AUTO_READY_WORKER", False)

    if use_direct_ollama:
        target_name = "llms_ollama"
        readiness_result = None
        worker_state = _power_lookup_worker_registry_state(target_name)

        actions.append(
            {
                "action": "direct_ollama_mode_selected",
                "queued_jobs": len(queued_jobs),
                "worker_state": worker_state,
                "auto_ready_worker": auto_ready_worker,
            }
        )

        if worker_state.get("computed_health") != "available":
            if auto_ready_worker:
                readiness_result = await power_execute_wake_and_start_worker(
                    target_name=target_name,
                    confirm="WAKE_AND_START_WORKER",
                    pause_after_start_minutes=10,
                    wait_worker_seconds=180,
                    wait_registry_seconds=180,
                )

                actions.append(
                    {
                        "action": "wake_and_start_before_direct_forward",
                        "ok": bool(readiness_result.get("ok")),
                        "executed": bool(readiness_result.get("executed")),
                        "result": readiness_result,
                    }
                )

                if not readiness_result.get("ok"):
                    return {
                        "ok": False,
                        "edge_dry_run": EDGE_DRY_RUN,
                        "mode": "direct_ollama",
                        "reason": "Worker was not ready and wake/start readiness failed.",
                        "actions": actions,
                    }
            else:
                actions.append(
                    {
                        "action": "kept_queued_worker_not_ready",
                        "reason": "EDGE_TICK_USE_DIRECT_OLLAMA=1, but worker is not available and EDGE_TICK_AUTO_READY_WORKER=0.",
                        "worker_state": worker_state,
                    }
                )

                return {
                    "ok": True,
                    "edge_dry_run": EDGE_DRY_RUN,
                    "mode": "direct_ollama",
                    "executed": False,
                    "actions": actions,
                }

        direct_result = await tick_ollama_direct(
            confirm="DIRECT_OLLAMA_FORWARD",
            limit=25,
            target_name=target_name,
        )

        actions.append(
            {
                "action": "direct_ollama_tick_result",
                "ok": bool(direct_result.get("ok")),
                "executed": bool(direct_result.get("executed")),
                "result": direct_result,
            }
        )

        return {
            "ok": bool(direct_result.get("ok")),
            "edge_dry_run": EDGE_DRY_RUN,
            "mode": "direct_ollama",
            "direct_forward_enabled": _parse_bool_env("EDGE_DIRECT_OLLAMA_FORWARD", False),
            "readiness_result": readiness_result,
            "actions": actions,
        }

    # -----------------------------------------------------------------
    # Legacy path. Kept for compatibility until direct mode fully replaces it.
    # -----------------------------------------------------------------
    online, detail = await host_is_online()

    if not online:
        wake_result = wake_host()
        actions.append(
            {
                "action": "host_offline",
                "queued_jobs": len(queued_jobs),
                "host_detail": detail,
                "wake": wake_result,
            }
        )

        return {
            "ok": True,
            "edge_dry_run": EDGE_DRY_RUN,
            "host_online": online,
            "host_detail": detail,
            "mode": "legacy_host_check",
            "actions": actions,
        }

    forwarded_any = False

    for row in queued_jobs:
        job = row_to_dict(row)

        scheduler = select_best_worker_for_job(job)
        selected_worker = scheduler.get("selected_worker")

        actions.append(
            {
                "job_id": job["id"],
                "action": "scheduler_decision",
                "job_type": job["job_type"],
                "requirements": scheduler.get("requirements"),
                "selected_worker": selected_worker,
                "rejected": scheduler.get("rejected", []),
            }
        )

        if not selected_worker:
            actions.append(
                {
                    "job_id": job["id"],
                    "action": "kept_queued",
                    "reason": "No healthy capable worker is currently available.",
                }
            )
            continue

        result = await forward_edge_job(job)
        actions.append(result)

        if result.get("action") == "forwarded_job_to_ai_platform":
            forwarded_any = True

    if forwarded_any:
        actions.append(start_host_worker())

    return {
        "ok": True,
        "edge_dry_run": EDGE_DRY_RUN,
        "host_online": online,
        "host_detail": detail,
        "mode": "legacy_host_check",
        "actions": actions,
    }


@app.post("/wake-test")
def wake_test():
    return wake_host()



# ============================================================
# Worker registry + scheduler preview
# ============================================================

def init_worker_registry_db() -> None:
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS workers (
                worker_id TEXT PRIMARY KEY,
                name TEXT,
                host_id TEXT,
                target_name TEXT,
                status TEXT NOT NULL DEFAULT 'online',
                capabilities_json TEXT NOT NULL DEFAULT '[]',
                current_jobs INTEGER NOT NULL DEFAULT 0,
                max_concurrent_jobs INTEGER NOT NULL DEFAULT 1,
                queue_depth INTEGER NOT NULL DEFAULT 0,
                cpu_percent REAL,
                ram_total_mb INTEGER,
                ram_free_mb INTEGER,
                gpu_name TEXT,
                vram_total_mb INTEGER,
                vram_free_mb INTEGER,
                consecutive_failures INTEGER NOT NULL DEFAULT 0,
                restart_attempts INTEGER NOT NULL DEFAULT 0,
                last_error TEXT,
                first_seen_at TEXT NOT NULL,
                last_heartbeat_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS worker_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                message TEXT,
                created_at TEXT NOT NULL
            )
            """
        )

        conn.commit()


class WorkerHeartbeatRequest(BaseModel):
    worker_id: str = Field(..., min_length=1, max_length=160)
    name: str | None = Field(default=None, max_length=160)
    host_id: str | None = Field(default=None, max_length=160)
    target_name: str | None = Field(default=None, max_length=160)
    status: str = Field(default="online", max_length=60)
    capabilities: list[str] = Field(default_factory=list)

    current_jobs: int = 0
    max_concurrent_jobs: int = 1
    queue_depth: int = 0

    cpu_percent: float | None = None
    ram_total_mb: int | None = None
    ram_free_mb: int | None = None

    gpu_name: str | None = None
    vram_total_mb: int | None = None
    vram_free_mb: int | None = None

    consecutive_failures: int = 0
    restart_attempts: int = 0
    last_error: str | None = None


def parse_iso_time(value: str | None):
    if not value:
        return None

    try:
        return datetime.fromisoformat(value)
    except Exception:
        return None


def worker_row_to_dict(row):
    """
    Convert a workers table row into API-safe JSON and compute health.
    Defensive version used by registry, remediation, and public status.
    """
    import json as _json
    import os as _os
    from datetime import datetime as _datetime, timezone as _timezone

    data = row_to_dict(row)

    raw_caps = data.get("capabilities_json")
    try:
        data["capabilities"] = _json.loads(raw_caps) if raw_caps else []
        if not isinstance(data["capabilities"], list):
            data["capabilities"] = []
    except Exception:
        data["capabilities"] = []

    data.pop("capabilities_json", None)

    heartbeat_age_seconds = None
    last_heartbeat_at = data.get("last_heartbeat_at")

    if last_heartbeat_at:
        try:
            text = str(last_heartbeat_at).replace("Z", "+00:00")
            parsed = _datetime.fromisoformat(text)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=_timezone.utc)
            heartbeat_age_seconds = max(0, int((_datetime.now(_timezone.utc) - parsed).total_seconds()))
        except Exception:
            heartbeat_age_seconds = None

    data["heartbeat_age_seconds"] = heartbeat_age_seconds

    status = str(data.get("status") or "").strip().lower()

    try:
        stale_after_seconds = int(
            globals().get(
                "WORKER_HEARTBEAT_STALE_SECONDS",
                _os.getenv("EDGE_WORKER_HEARTBEAT_STALE_SECONDS", "120"),
            )
        )
    except Exception:
        stale_after_seconds = 120

    try:
        current_jobs = int(data.get("current_jobs") or 0)
    except Exception:
        current_jobs = 0

    try:
        max_concurrent_jobs = int(data.get("max_concurrent_jobs") or 1)
    except Exception:
        max_concurrent_jobs = 1

    if max_concurrent_jobs < 1:
        max_concurrent_jobs = 1

    if status in ("disabled", "offline"):
        computed_health = status
    elif status == "unhealthy":
        computed_health = "unhealthy"
    elif heartbeat_age_seconds is None or heartbeat_age_seconds > stale_after_seconds:
        computed_health = "stale"
    elif current_jobs >= max_concurrent_jobs:
        computed_health = "busy"
    else:
        computed_health = "available"

    data["computed_health"] = computed_health

    return data


def estimate_job_requirements(job: dict[str, Any]) -> dict[str, Any]:
    job_type = job.get("job_type") or ""

    if job_type in ("ollama_chat", "companion_chat", "tts", "stt"):
        return {
            "required_capability": job_type if job_type != "companion_chat" else "ollama_chat",
            "required_cpu_cores": 1,
            "required_ram_mb": 512,
            "required_gpu": False,
            "required_vram_mb": 0,
        }

    if job_type in ("comfy_image", "comfy_video"):
        return {
            "required_capability": job_type,
            "required_cpu_cores": 2,
            "required_ram_mb": 4096,
            "required_gpu": True,
            "required_vram_mb": 8192 if job_type == "comfy_image" else 12288,
        }

    return {
        "required_capability": job_type,
        "required_cpu_cores": 1,
        "required_ram_mb": 512,
        "required_gpu": False,
        "required_vram_mb": 0,
    }


def score_worker_for_job(worker: dict[str, Any], requirements: dict[str, Any]) -> tuple[bool, int, list[str]]:
    reasons: list[str] = []

    capability = requirements["required_capability"]
    capabilities = worker.get("capabilities") or []

    if capability and capability not in capabilities:
        reasons.append(f"missing capability {capability!r}")

    if worker.get("computed_health") not in ("available", "busy"):
        reasons.append(f"worker health is {worker.get('computed_health')}")

    if worker.get("current_jobs", 0) >= worker.get("max_concurrent_jobs", 1):
        reasons.append("worker at max concurrency")

    ram_free = worker.get("ram_free_mb")
    if ram_free is not None and ram_free < requirements["required_ram_mb"]:
        reasons.append("not enough free RAM")

    if requirements["required_gpu"]:
        if not worker.get("gpu_name"):
            reasons.append("GPU required but worker has no GPU")
        elif worker.get("vram_free_mb") is not None and worker.get("vram_free_mb") < requirements["required_vram_mb"]:
            reasons.append("not enough free VRAM")

    if reasons:
        return False, 999999, reasons

    score = 0
    score += int(worker.get("queue_depth") or 0) * 100
    score += int(worker.get("current_jobs") or 0) * 50
    score += int(worker.get("consecutive_failures") or 0) * 200
    score += int(worker.get("restart_attempts") or 0) * 25

    ram_free = worker.get("ram_free_mb") or 0
    vram_free = worker.get("vram_free_mb") or 0

    score -= int(ram_free / 1000)
    score -= int(vram_free / 1000)

    return True, score, ["candidate"]


@app.post("/workers/heartbeat")
def worker_heartbeat(
    payload: WorkerHeartbeatRequest,
    x_heartbeat_token: str | None = Header(default=None, alias="X-Heartbeat-Token"),
):
    if not HEARTBEAT_SHARED_SECRET:
        raise HTTPException(status_code=500, detail="HEARTBEAT_SHARED_SECRET is not configured.")

    if not x_heartbeat_token or x_heartbeat_token != HEARTBEAT_SHARED_SECRET:
        raise HTTPException(status_code=401, detail="Invalid heartbeat token.")

    init_worker_registry_db()

    now = utc_now()
    capabilities_json = json.dumps(payload.capabilities)

    with db() as conn:
        existing = conn.execute(
            "SELECT worker_id FROM workers WHERE worker_id = ?",
            (payload.worker_id,),
        ).fetchone()

        if existing:
            conn.execute(
                """
                UPDATE workers
                SET
                    name = ?,
                    host_id = ?,
                    target_name = ?,
                    status = ?,
                    capabilities_json = ?,
                    current_jobs = ?,
                    max_concurrent_jobs = ?,
                    queue_depth = ?,
                    cpu_percent = ?,
                    ram_total_mb = ?,
                    ram_free_mb = ?,
                    gpu_name = ?,
                    vram_total_mb = ?,
                    vram_free_mb = ?,
                    last_error = ?,
                    last_heartbeat_at = ?,
                    updated_at = ?
                WHERE worker_id = ?
                """,
                (
                    payload.name,
                    payload.host_id,
                    payload.target_name,
                    payload.status,
                    capabilities_json,
                    payload.current_jobs,
                    payload.max_concurrent_jobs,
                    payload.queue_depth,
                    payload.cpu_percent,
                    payload.ram_total_mb,
                    payload.ram_free_mb,
                    payload.gpu_name,
                    payload.vram_total_mb,
                    payload.vram_free_mb,
                    payload.last_error,
                    now,
                    now,
                    payload.worker_id,
                ),
            )
        else:
            conn.execute(
                """
                INSERT INTO workers (
                    worker_id,
                    name,
                    host_id,
                    target_name,
                    status,
                    capabilities_json,
                    current_jobs,
                    max_concurrent_jobs,
                    queue_depth,
                    cpu_percent,
                    ram_total_mb,
                    ram_free_mb,
                    gpu_name,
                    vram_total_mb,
                    vram_free_mb,
                    consecutive_failures,
                    restart_attempts,
                    last_error,
                    first_seen_at,
                    last_heartbeat_at,
                    updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    payload.worker_id,
                    payload.name,
                    payload.host_id,
                    payload.target_name,
                    payload.status,
                    capabilities_json,
                    payload.current_jobs,
                    payload.max_concurrent_jobs,
                    payload.queue_depth,
                    payload.cpu_percent,
                    payload.ram_total_mb,
                    payload.ram_free_mb,
                    payload.gpu_name,
                    payload.vram_total_mb,
                    payload.vram_free_mb,
                    0,
                    0,
                    payload.last_error,
                    now,
                    now,
                    now,
                ),
            )

            conn.execute(
                """
                INSERT INTO worker_events (worker_id, event_type, message, created_at)
                VALUES (?, 'first_seen', 'Worker registered by heartbeat.', ?)
                """,
                (payload.worker_id, now),
            )

        conn.commit()

        row = conn.execute(
            "SELECT * FROM workers WHERE worker_id = ?",
            (payload.worker_id,),
        ).fetchone()

    return {
        "ok": True,
        "worker": worker_row_to_dict(row),
    }


@app.get("/workers/registry")
def workers_registry():
    init_worker_registry_db()

    with db() as conn:
        rows = conn.execute(
            """
            SELECT *
            FROM workers
            ORDER BY target_name, worker_id
            """
        ).fetchall()

    workers = [worker_row_to_dict(row) for row in rows]

    summary = {
        "total": len(workers),
        "available": sum(1 for w in workers if w.get("computed_health") == "available"),
        "busy": sum(1 for w in workers if w.get("computed_health") == "busy"),
        "stale": sum(1 for w in workers if w.get("computed_health") == "stale"),
        "unhealthy": sum(1 for w in workers if w.get("computed_health") == "unhealthy"),
        "disabled": sum(1 for w in workers if w.get("computed_health") == "disabled"),
        "offline": sum(1 for w in workers if w.get("computed_health") == "offline"),
    }

    return {
        "ok": True,
        "summary": summary,
        "workers": workers,
    }


@app.get("/scheduler/preview")
def scheduler_preview():
    init_worker_registry_db()

    with db() as conn:
        job_rows = conn.execute(
            """
            SELECT *
            FROM jobs
            WHERE status = 'queued'
            ORDER BY id ASC
            LIMIT 25
            """
        ).fetchall()

        worker_rows = conn.execute(
            """
            SELECT *
            FROM workers
            ORDER BY worker_id ASC
            """
        ).fetchall()

    workers = [worker_row_to_dict(row) for row in worker_rows]

    plans = []

    for job_row in job_rows:
        job = row_to_dict(job_row)
        requirements = estimate_job_requirements(job)

        candidates = []
        rejected = []

        for worker in workers:
            ok, score, reasons = score_worker_for_job(worker, requirements)

            candidate_info = {
                "worker_id": worker.get("worker_id"),
                "name": worker.get("name"),
                "target_name": worker.get("target_name"),
                "computed_health": worker.get("computed_health"),
                "score": score,
                "reasons": reasons,
            }

            if ok:
                candidates.append(candidate_info)
            else:
                rejected.append(candidate_info)

        candidates.sort(key=lambda item: item["score"])

        plans.append(
            {
                "job_id": job["id"],
                "job_type": job["job_type"],
                "requested_model": job.get("requested_model"),
                "requirements": requirements,
                "selected_worker": candidates[0] if candidates else None,
                "candidates": candidates,
                "rejected": rejected,
            }
        )

    return {
        "ok": True,
        "queued_jobs": len(plans),
        "worker_count": len(workers),
        "plans": plans,
    }





# ============================================================
# Inventory/remediation compatibility helpers
# ============================================================

def load_inventory() -> dict[str, Any]:
    """
    Load edge_inventory.json when present. If it is not present, fall back to
    the existing single-worker SSH settings from .env.
    """
    inventory_path = Path(os.getenv("EDGE_INVENTORY_FILE", "edge_inventory.json"))

    if inventory_path.exists():
        with inventory_path.open("r", encoding="utf-8") as f:
            return json.load(f)

    return {
        "targets": {
            "llms_ollama": {
                "label": "LLMs / AI Platform / Ollama",
                "worker_start_ssh_host": WORKER_START_SSH_HOST,
                "worker_start_ssh_user": WORKER_START_SSH_USER,
                "worker_start_ssh_key": WORKER_START_SSH_KEY,
                "worker_start_command": WORKER_START_COMMAND,
            }
        }
    }


def start_target_worker(target: dict[str, Any], dry_run: bool = False) -> dict[str, Any]:
    """
    Start a target worker over SSH. This is used by remediation.
    """
    ssh_host = target.get("worker_start_ssh_host") or WORKER_START_SSH_HOST
    ssh_user = target.get("worker_start_ssh_user") or WORKER_START_SSH_USER
    ssh_key = target.get("worker_start_ssh_key") or WORKER_START_SSH_KEY
    command = target.get("worker_start_command") or WORKER_START_COMMAND

    if not ssh_host:
        return {
            "action": "worker_start_failed",
            "reason": "No worker_start_ssh_host configured.",
        }

    if not command:
        return {
            "action": "worker_start_failed",
            "reason": "No worker_start_command configured.",
        }

    ssh_target = f"{ssh_user}@{ssh_host}"

    cmd = [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=10",
    ]

    if ssh_key:
        cmd.extend(["-i", ssh_key])

    cmd.extend([ssh_target, command])

    if dry_run:
        return {
            "action": "would_start_worker_over_ssh",
            "dry_run": True,
            "ssh_target": ssh_target,
            "command": command,
        }

    try:
        completed = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=120,
            check=False,
        )
    except Exception as exc:
        return {
            "action": "worker_start_failed",
            "ssh_target": ssh_target,
            "command": command,
            "error": repr(exc),
        }

    return {
        "action": "worker_start_attempted",
        "ssh_target": ssh_target,
        "command": command,
        "returncode": completed.returncode,
        "stdout": completed.stdout[-2000:],
        "stderr": completed.stderr[-2000:],
    }


# ============================================================
# Worker remediation
# ============================================================

class RemediationTickRequest(BaseModel):
    dry_run: bool = True
    max_restart_attempts: int = 3


@app.post("/workers/remediation/tick")
def workers_remediation_tick(payload: RemediationTickRequest | None = None):
    """
    Controlled remediation pass.

    This does not run automatically yet. It checks worker health and,
    when allowed, calls the target worker start command. This is the
    safe foundation for future automatic repair loops.
    """
    init_worker_registry_db()

    payload = payload or RemediationTickRequest()
    inventory = load_inventory()
    targets = inventory.get("targets", {})

    with db() as conn:
        rows = conn.execute(
            """
            SELECT *
            FROM workers
            ORDER BY worker_id ASC
            """
        ).fetchall()

    workers = [worker_row_to_dict(row) for row in rows]
    actions: list[dict[str, Any]] = []

    for worker in workers:
        worker_id = worker.get("worker_id")
        health = worker.get("computed_health")
        restart_attempts = int(worker.get("restart_attempts") or 0)
        target_name = worker.get("target_name")

        if health not in ("unhealthy", "stale"):
            actions.append(
                {
                    "worker_id": worker_id,
                    "action": "no_remediation_needed",
                    "health": health,
                }
            )
            continue

        if restart_attempts >= payload.max_restart_attempts:
            now = utc_now()
            with db() as conn:
                conn.execute(
                    """
                    INSERT INTO worker_events (worker_id, event_type, message, created_at)
                    VALUES (?, 'manual_check_required', ?, ?)
                    """,
                    (
                        worker_id,
                        f"Worker reached restart_attempts={restart_attempts}; health={health}.",
                        now,
                    ),
                )
                conn.commit()

            actions.append(
                {
                    "worker_id": worker_id,
                    "action": "manual_check_required",
                    "health": health,
                    "restart_attempts": restart_attempts,
                    "max_restart_attempts": payload.max_restart_attempts,
                    "last_error": worker.get("last_error"),
                }
            )
            continue

        target = targets.get(target_name or "")

        if not target:
            actions.append(
                {
                    "worker_id": worker_id,
                    "action": "remediation_failed",
                    "reason": f"No target found for target_name={target_name!r}.",
                }
            )
            continue

        if payload.dry_run:
            actions.append(
                {
                    "worker_id": worker_id,
                    "action": "would_attempt_worker_restart",
                    "dry_run": True,
                    "health": health,
                    "target_name": target_name,
                    "restart_attempts": restart_attempts,
                    "last_error": worker.get("last_error"),
                }
            )
            continue

        result = start_target_worker(target, dry_run=False)
        now = utc_now()

        with db() as conn:
            conn.execute(
                """
                UPDATE workers
                SET
                    restart_attempts = restart_attempts + 1,
                    updated_at = ?
                WHERE worker_id = ?
                """,
                (now, worker_id),
            )

            conn.execute(
                """
                INSERT INTO worker_events (worker_id, event_type, message, created_at)
                VALUES (?, 'restart_attempt', ?, ?)
                """,
                (
                    worker_id,
                    f"Remediation attempted for health={health}; result={result.get('action')}.",
                    now,
                ),
            )

            conn.commit()

        actions.append(
            {
                "worker_id": worker_id,
                "action": "worker_restart_attempted",
                "health": health,
                "target_name": target_name,
                "restart_attempts_before": restart_attempts,
                "result": result,
            }
        )

    return {
        "ok": True,
        "dry_run": payload.dry_run,
        "worker_count": len(workers),
        "actions": actions,
    }


@app.get("/workers/events")
def workers_events(limit: int = 50):
    init_worker_registry_db()

    limit = max(1, min(limit, 200))

    with db() as conn:
        rows = conn.execute(
            """
            SELECT *
            FROM worker_events
            ORDER BY id DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()

    return {
        "ok": True,
        "events": [dict(row) for row in rows],
    }



# ---------------------------------------------------------------------
# Manual remediation reset endpoint
# ---------------------------------------------------------------------
@app.post("/workers/{worker_id}/remediation/reset")
async def reset_worker_remediation(worker_id: str):
    """
    Reset remediation counters for a worker after a successful/manual recovery.

    This clears:
      - consecutive_failures
      - restart_attempts
      - last_error

    It also writes a worker event when the event table is available.
    """
    import sqlite3
    from pathlib import Path
    from datetime import datetime, timezone
    from fastapi import HTTPException

    def find_db_path():
        candidates = []

        for name, value in globals().items():
            upper = name.upper()

            if "DB" in upper and ("PATH" in upper or "FILE" in upper or "DATABASE" in upper):
                if isinstance(value, (str, Path)):
                    text = str(value)

                    if text.startswith("sqlite:///"):
                        text = text.replace("sqlite:///", "", 1)

                    if text and not text.startswith("postgres"):
                        candidates.append(Path(text))

        for p in candidates:
            if p.exists():
                return p

        fallback_names = [
            "edge_controller.db",
            "edge_controller.sqlite",
            "edge_controller.sqlite3",
            "queue_controller.db",
            "queue_controller.sqlite",
            "queue_controller.sqlite3",
        ]

        here = Path(__file__).resolve().parent
        for name in fallback_names:
            p = here / name
            if p.exists():
                return p

        raise HTTPException(
            status_code=500,
            detail="Could not locate SQLite database path from controller globals or known fallback names.",
        )

    db_path = find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        worker_cols = {
            row["name"]
            for row in conn.execute("PRAGMA table_info(workers)").fetchall()
        }

        if not worker_cols:
            raise HTTPException(status_code=500, detail="workers table not found or has no columns")

        if "worker_id" in worker_cols:
            worker_key_col = "worker_id"
        elif "id" in worker_cols:
            worker_key_col = "id"
        else:
            raise HTTPException(
                status_code=500,
                detail="workers table does not contain worker_id or id column",
            )

        updates = []
        params = []

        if "consecutive_failures" in worker_cols:
            updates.append("consecutive_failures = ?")
            params.append(0)

        if "restart_attempts" in worker_cols:
            updates.append("restart_attempts = ?")
            params.append(0)

        if "last_error" in worker_cols:
            updates.append("last_error = ?")
            params.append(None)

        now = datetime.now(timezone.utc).isoformat()

        if "updated_at" in worker_cols:
            updates.append("updated_at = ?")
            params.append(now)

        if not updates:
            raise HTTPException(
                status_code=500,
                detail="No remediation columns found to reset",
            )

        params.append(worker_id)

        cur = conn.execute(
            f"""
            UPDATE workers
            SET {", ".join(updates)}
            WHERE {worker_key_col} = ?
            """,
            params,
        )

        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail=f"Worker not found: {worker_id}")

        event_table = None
        for row in conn.execute(
            """
            SELECT name
            FROM sqlite_master
            WHERE type = 'table'
            ORDER BY name
            """
        ).fetchall():
            table = row["name"]
            cols = {
                c["name"]
                for c in conn.execute(f"PRAGMA table_info({table})").fetchall()
            }

            if {"worker_id", "event_type", "message"}.issubset(cols):
                event_table = table
                event_cols = cols
                break

        if event_table:
            cols = ["worker_id", "event_type", "message"]
            values = [
                worker_id,
                "remediation_reset",
                "Manual remediation counters reset.",
            ]

            if "created_at" in event_cols:
                cols.append("created_at")
                values.append(now)

            placeholders = ", ".join(["?"] * len(cols))

            conn.execute(
                f"""
                INSERT INTO {event_table} ({", ".join(cols)})
                VALUES ({placeholders})
                """,
                values,
            )

        conn.commit()

        return {
            "ok": True,
            "worker_id": worker_id,
            "reset": {
                "consecutive_failures": "consecutive_failures" in worker_cols,
                "restart_attempts": "restart_attempts" in worker_cols,
                "last_error": "last_error" in worker_cols,
            },
            "event_logged": bool(event_table),
        }

    finally:
        conn.close()


# ---------------------------------------------------------------------
# Power idle dry-run endpoint
# ---------------------------------------------------------------------
@app.post("/power/idle/tick")
async def power_idle_tick():
    """
    Dry-run idle power management.

    Policy goal:
      1. If the queue has been empty for EDGE_IDLE_CONTAINER_SECONDS,
         report which worker targets would be stopped.
      2. If all worker targets have been idle/off for EDGE_IDLE_HOST_SECONDS,
         report whether the host would be eligible for shutdown.

    This endpoint is intentionally dry-run by default. It does not stop
    containers or shut down hosts yet.
    """
    import json
    import os
    import sqlite3
    from pathlib import Path
    from datetime import datetime, timezone
    from fastapi import HTTPException

    now = datetime.now(timezone.utc)

    def now_iso():
        return datetime.now(timezone.utc).isoformat()

    def parse_bool(value, default=True):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    def parse_csv(value):
        if not value:
            return set()
        return {
            item.strip()
            for item in str(value).split(",")
            if item.strip()
        }

    dry_run = parse_bool(os.getenv("EDGE_POWER_DRY_RUN"), True)
    container_idle_seconds_required = int(os.getenv("EDGE_IDLE_CONTAINER_SECONDS", "300"))
    host_idle_seconds_required = int(os.getenv("EDGE_IDLE_HOST_SECONDS", "300"))

    # Safety rule:
    # Even in the future, real stopping should only be allowed for explicit targets.
    allowed_stop_targets = parse_csv(os.getenv("EDGE_POWER_ALLOWED_STOP_TARGETS", ""))

    protected_targets = parse_csv(
        os.getenv(
            "EDGE_POWER_PROTECTED_TARGETS",
            "controller,router,dns,cloudflare,cloudflared,tailscale,network",
        )
    )

    def find_db_path():
        candidates = []

        for name, value in globals().items():
            upper = name.upper()

            if "DB" in upper and ("PATH" in upper or "FILE" in upper or "DATABASE" in upper):
                if isinstance(value, (str, Path)):
                    text = str(value)

                    if text.startswith("sqlite:///"):
                        text = text.replace("sqlite:///", "", 1)

                    if text and not text.startswith("postgres"):
                        candidates.append(Path(text))

        for candidate in candidates:
            if candidate.exists():
                return candidate

        fallback_names = [
            "edge_queue.sqlite3",
            "edge_queue.sqlite",
            "edge_queue.db",
            "edge_controller.db",
            "edge_controller.sqlite",
            "edge_controller.sqlite3",
            "queue_controller.db",
            "queue_controller.sqlite",
            "queue_controller.sqlite3",
        ]

        here = Path(__file__).resolve().parent
        for name in fallback_names:
            candidate = here / name
            if candidate.exists():
                return candidate

        raise HTTPException(
            status_code=500,
            detail="Could not locate SQLite database path.",
        )

    db_path = find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS power_idle_state (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TEXT NOT NULL
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS power_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                message TEXT NOT NULL,
                payload_json TEXT,
                created_at TEXT NOT NULL
            )
            """
        )

        def get_state(key):
            row = conn.execute(
                "SELECT value FROM power_idle_state WHERE key = ?",
                (key,),
            ).fetchone()
            return row["value"] if row else None

        def set_state(key, value):
            conn.execute(
                """
                INSERT INTO power_idle_state (key, value, updated_at)
                VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET
                    value = excluded.value,
                    updated_at = excluded.updated_at
                """,
                (key, value, now_iso()),
            )

        def clear_state(key):
            conn.execute(
                "DELETE FROM power_idle_state WHERE key = ?",
                (key,),
            )

        def seconds_since(iso_value):
            if not iso_value:
                return 0
            try:
                dt = datetime.fromisoformat(iso_value)
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                return max(0, int((now - dt).total_seconds()))
            except Exception:
                return 0

        tables = {
            row["name"]
            for row in conn.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table'"
            ).fetchall()
        }

        workers = []
        if "workers" in tables:
            worker_rows = conn.execute("SELECT * FROM workers").fetchall()
            for row in worker_rows:
                item = dict(row)
                workers.append(item)

        jobs_known = "jobs" in tables
        active_jobs_count = None
        job_status_column = None

        terminal_statuses = {
            "done",
            "complete",
            "completed",
            "success",
            "succeeded",
            "failed",
            "error",
            "errored",
            "cancelled",
            "canceled",
            "forwarded",
        }

        if jobs_known:
            job_cols = {
                row["name"]
                for row in conn.execute("PRAGMA table_info(jobs)").fetchall()
            }

            for candidate in ("status", "state", "job_status"):
                if candidate in job_cols:
                    job_status_column = candidate
                    break

            if job_status_column:
                rows = conn.execute(
                    f"SELECT {job_status_column} AS status_value FROM jobs"
                ).fetchall()

                active_jobs_count = 0
                for row in rows:
                    status = str(row["status_value"] or "").strip().lower()

                    # Empty/unknown status is treated as active for safety.
                    if not status or status not in terminal_statuses:
                        active_jobs_count += 1
            else:
                # If we cannot identify job status safely, block shutdown decisions.
                active_jobs_count = None

        worker_busy_count = 0
        worker_queue_depth_total = 0

        for worker in workers:
            try:
                worker_busy_count += int(worker.get("current_jobs") or 0)
            except Exception:
                worker_busy_count += 0

            try:
                worker_queue_depth_total += int(worker.get("queue_depth") or 0)
            except Exception:
                worker_queue_depth_total += 0

        jobs_safe_to_evaluate = active_jobs_count is not None

        queue_now_empty = (
            jobs_safe_to_evaluate
            and active_jobs_count == 0
            and worker_busy_count == 0
            and worker_queue_depth_total == 0
        )

        previous_queue_empty_since = get_state("queue_empty_since")

        if queue_now_empty:
            if not previous_queue_empty_since:
                previous_queue_empty_since = now.isoformat()
                set_state("queue_empty_since", previous_queue_empty_since)
        else:
            clear_state("queue_empty_since")
            previous_queue_empty_since = None

        queue_empty_for_seconds = seconds_since(previous_queue_empty_since)

        container_actions = []

        for worker in workers:
            worker_id = worker.get("worker_id") or worker.get("name") or "unknown-worker"
            target_name = worker.get("target_name") or worker_id
            host_id = worker.get("host_id") or "unknown-host"

            try:
                current_jobs = int(worker.get("current_jobs") or 0)
            except Exception:
                current_jobs = 0

            try:
                queue_depth = int(worker.get("queue_depth") or 0)
            except Exception:
                queue_depth = 0

            target_is_protected = target_name in protected_targets or worker_id in protected_targets
            target_is_allowlisted = target_name in allowed_stop_targets or worker_id in allowed_stop_targets

            if not queue_now_empty:
                action = "no_action_queue_not_empty_or_unknown"
                reason = "Queue is not empty, jobs table could not be evaluated, or worker still has work."
            elif queue_empty_for_seconds < container_idle_seconds_required:
                action = "no_action_idle_grace_period"
                reason = f"Queue empty for {queue_empty_for_seconds}s; waiting for {container_idle_seconds_required}s."
            elif current_jobs != 0 or queue_depth != 0:
                action = "no_action_worker_busy"
                reason = "Worker still reports current jobs or queue depth."
            elif target_is_protected:
                action = "blocked_protected_target"
                reason = "Target is protected from auto-stop."
            elif not target_is_allowlisted:
                action = "blocked_not_allowlisted"
                reason = "Target is not in EDGE_POWER_ALLOWED_STOP_TARGETS."
            elif dry_run:
                action = "would_stop_worker_target"
                reason = "Queue has been empty long enough and target is allowlisted, but dry-run is enabled."
            else:
                # Real stop is intentionally not implemented yet.
                action = "real_stop_not_implemented"
                reason = "Dry-run is disabled, but real stop code has not been implemented yet."

            container_actions.append(
                {
                    "worker_id": worker_id,
                    "host_id": host_id,
                    "target_name": target_name,
                    "current_jobs": current_jobs,
                    "queue_depth": queue_depth,
                    "protected": target_is_protected,
                    "allowlisted": target_is_allowlisted,
                    "action": action,
                    "reason": reason,
                }
            )

        all_container_actions_idle_or_blocked = all(
            action["action"] in {
                "would_stop_worker_target",
                "blocked_protected_target",
                "blocked_not_allowlisted",
                "real_stop_not_implemented",
            }
            for action in container_actions
        ) if container_actions else False

        previous_host_empty_since = get_state("host_empty_since")

        # Host shutdown is not truly safe until we can query Proxmox CT/VM inventory.
        # For now, host logic only tracks the dry-run grace window and reports blocked.
        host_candidate_now = (
            queue_now_empty
            and queue_empty_for_seconds >= container_idle_seconds_required
            and all_container_actions_idle_or_blocked
        )

        if host_candidate_now:
            if not previous_host_empty_since:
                previous_host_empty_since = now.isoformat()
                set_state("host_empty_since", previous_host_empty_since)
        else:
            clear_state("host_empty_since")
            previous_host_empty_since = None

        host_empty_for_seconds = seconds_since(previous_host_empty_since)

        host_actions = []
        proxmox_inventory_result = None
        proxmox_inventory_error = None

        hosts = sorted({
            worker.get("host_id") or "unknown-host"
            for worker in workers
        })

        # Only query Proxmox inventory after the queue/container idle grace period
        # has already passed. This keeps normal ticks cheap and only performs SSH
        # when host shutdown would otherwise be considered.
        if host_candidate_now and host_empty_for_seconds >= host_idle_seconds_required:
            try:
                proxmox_inventory_result = await proxmox_inventory()
            except Exception as e:
                proxmox_inventory_error = str(e)

        for host in hosts:
            inventory_summary = None

            if isinstance(proxmox_inventory_result, dict):
                inventory_summary = proxmox_inventory_result.get("summary")

            if not host_candidate_now:
                host_action = "no_action_host_not_idle_candidate"
                host_reason = "Queue/container idle requirements are not satisfied yet."

            elif host_empty_for_seconds < host_idle_seconds_required:
                host_action = "no_action_host_idle_grace_period"
                host_reason = f"Host idle candidate for {host_empty_for_seconds}s; waiting for {host_idle_seconds_required}s."

            elif proxmox_inventory_error:
                host_action = "blocked_proxmox_inventory_error"
                host_reason = f"Could not query Proxmox inventory safely: {proxmox_inventory_error}"

            elif not inventory_summary:
                host_action = "blocked_missing_proxmox_inventory"
                host_reason = "Proxmox inventory result was unavailable or malformed."

            elif inventory_summary.get("host_shutdown_safe_now"):
                if dry_run:
                    host_action = "would_shutdown_host"
                    host_reason = "Proxmox inventory says no CTs/VMs are running, but dry-run is enabled."
                else:
                    # Real host shutdown is intentionally not implemented yet.
                    host_action = "real_host_shutdown_not_implemented"
                    host_reason = "Dry-run is disabled, but real host shutdown code has not been implemented yet."

            elif inventory_summary.get("host_shutdown_safe_if_auto_managed_stopped"):
                host_action = "would_shutdown_host_after_auto_managed_targets_stop"
                host_reason = (
                    "Only auto-managed CTs/VMs are running. Host shutdown would become safe "
                    "after those targets are stopped and the host idle grace period passes."
                )

            else:
                host_action = "blocked_running_protected_or_unknown_workloads"
                host_reason = (
                    "Proxmox inventory shows protected or manual/unknown CTs/VMs running. "
                    "Host shutdown is blocked."
                )

            host_actions.append(
                {
                    "host_id": host,
                    "idle_candidate_for_seconds": host_empty_for_seconds,
                    "action": host_action,
                    "reason": host_reason,
                    "proxmox_inventory_error": proxmox_inventory_error,
                    "proxmox_inventory_summary": inventory_summary,
                }
            )

        payload = {
            "ok": True,
            "dry_run": dry_run,
            "db_path": str(db_path),
            "policy": {
                "container_idle_seconds_required": container_idle_seconds_required,
                "host_idle_seconds_required": host_idle_seconds_required,
                "allowed_stop_targets": sorted(allowed_stop_targets),
                "protected_targets": sorted(protected_targets),
            },
            "queue": {
                "jobs_known": jobs_known,
                "jobs_safe_to_evaluate": jobs_safe_to_evaluate,
                "job_status_column": job_status_column,
                "active_jobs_count": active_jobs_count,
                "worker_busy_count": worker_busy_count,
                "worker_queue_depth_total": worker_queue_depth_total,
                "queue_now_empty": queue_now_empty,
                "queue_empty_since": previous_queue_empty_since,
                "queue_empty_for_seconds": queue_empty_for_seconds,
            },
            "container_actions": container_actions,
            "host_actions": host_actions,
        }

        conn.execute(
            """
            INSERT INTO power_events (event_type, message, payload_json, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (
                "power_idle_tick",
                "Power idle dry-run tick evaluated.",
                json.dumps(payload, sort_keys=True),
                now_iso(),
            ),
        )

        conn.commit()

        return payload

    finally:
        conn.close()


# ---------------------------------------------------------------------
# Proxmox inventory dry-run endpoint
# ---------------------------------------------------------------------
@app.post("/power/proxmox/inventory")
async def proxmox_inventory():
    """
    Dry-run Proxmox CT/VM inventory check.

    This endpoint only reads:
      - pct list
      - qm list

    It does not stop containers.
    It does not shut down the host.
    """
    import os
    import subprocess
    from datetime import datetime, timezone
    from fastapi import HTTPException

    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()
    host_id = os.getenv("EDGE_PROXMOX_HOST_ID", "pveso").strip() or "pveso"

    if not ssh_target:
        raise HTTPException(
            status_code=500,
            detail="EDGE_PROXMOX_SSH_TARGET is not configured.",
        )

    def parse_csv(value):
        if not value:
            return set()
        return {
            item.strip()
            for item in str(value).split(",")
            if item.strip()
        }

    auto_managed = parse_csv(os.getenv("EDGE_PROXMOX_AUTO_MANAGED", ""))
    protected = parse_csv(os.getenv("EDGE_PROXMOX_PROTECTED", ""))

    remote_cmd = (
        "hostname; "
        "echo __PCT_BEGIN__; pct list; echo __PCT_END__; "
        "echo __QM_BEGIN__; qm list; echo __QM_END__"
    )

    cmd = [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=5",
        "-o", "StrictHostKeyChecking=accept-new",
        ssh_target,
        remote_cmd,
    ]

    try:
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=12,
            check=False,
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=504,
            detail="Timed out while querying Proxmox inventory over SSH.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to run SSH inventory command: {e}",
        )

    if result.returncode != 0:
        raise HTTPException(
            status_code=502,
            detail={
                "message": "SSH inventory command failed.",
                "returncode": result.returncode,
                "stdout": result.stdout[-2000:],
                "stderr": result.stderr[-2000:],
            },
        )

    stdout = result.stdout

    def section(text, start_marker, end_marker):
        if start_marker not in text or end_marker not in text:
            return ""
        return text.split(start_marker, 1)[1].split(end_marker, 1)[0].strip()

    hostname = stdout.splitlines()[0].strip() if stdout.splitlines() else host_id
    pct_text = section(stdout, "__PCT_BEGIN__", "__PCT_END__")
    qm_text = section(stdout, "__QM_BEGIN__", "__QM_END__")

    def classify(vmid, name):
        keys = {str(vmid), str(name)}
        return {
            "protected": bool(keys & protected),
            "auto_managed": bool(keys & auto_managed),
        }

    containers = []
    for line in pct_text.splitlines():
        line = line.strip()
        if not line:
            continue

        # Skip header line:
        # VMID       Status     Lock         Name
        if line.lower().startswith("vmid"):
            continue

        parts = line.split()
        if len(parts) < 3:
            continue

        vmid = parts[0]
        status = parts[1]
        name = parts[-1]

        flags = classify(vmid, name)

        containers.append(
            {
                "kind": "ct",
                "vmid": vmid,
                "name": name,
                "status": status,
                "running": status.lower() == "running",
                **flags,
            }
        )

    vms = []
    for line in qm_text.splitlines():
        line = line.strip()
        if not line:
            continue

        # Skip header line:
        # VMID NAME STATUS MEM(MB) BOOTDISK(GB) PID
        if line.lower().startswith("vmid"):
            continue

        parts = line.split()
        if len(parts) < 3:
            continue

        vmid = parts[0]
        name = parts[1]
        status = parts[2]

        flags = classify(vmid, name)

        vms.append(
            {
                "kind": "vm",
                "vmid": vmid,
                "name": name,
                "status": status,
                "running": status.lower() == "running",
                **flags,
            }
        )

    all_items = containers + vms

    running_items = [item for item in all_items if item["running"]]
    running_auto_managed = [
        item for item in running_items
        if item["auto_managed"] and not item["protected"]
    ]
    running_protected = [
        item for item in running_items
        if item["protected"]
    ]
    running_manual_or_unknown = [
        item for item in running_items
        if not item["auto_managed"] and not item["protected"]
    ]

    host_shutdown_safe_now = len(running_items) == 0

    # Useful for the future:
    # This means host shutdown would become safe after auto-managed workers stop.
    host_shutdown_safe_if_auto_managed_stopped = (
        len(running_protected) == 0
        and len(running_manual_or_unknown) == 0
    )

    return {
        "ok": True,
        "dry_run": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "host_id": host_id,
        "ssh_target": ssh_target,
        "hostname": hostname,
        "policy": {
            "auto_managed": sorted(auto_managed),
            "protected": sorted(protected),
        },
        "containers": containers,
        "vms": vms,
        "summary": {
            "running_total": len(running_items),
            "running_auto_managed": len(running_auto_managed),
            "running_protected": len(running_protected),
            "running_manual_or_unknown": len(running_manual_or_unknown),
            "host_shutdown_safe_now": host_shutdown_safe_now,
            "host_shutdown_safe_if_auto_managed_stopped": host_shutdown_safe_if_auto_managed_stopped,
        },
        "decision": {
            "host_shutdown_safe_now": host_shutdown_safe_now,
            "reason": (
                "No CTs/VMs are running."
                if host_shutdown_safe_now
                else "One or more CTs/VMs are still running."
            ),
        },
    }


# ---------------------------------------------------------------------
# Power stop command plan dry-run endpoint
# ---------------------------------------------------------------------
@app.post("/power/stop-plan")
async def power_stop_plan():
    """
    Build an explicit dry-run command plan for idle power management.

    This endpoint does not execute stop/shutdown commands.
    It only reports what commands would be eligible to run later.
    """
    import os
    from datetime import datetime, timezone
    from fastapi import HTTPException

    def parse_bool(value, default=True):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    def parse_target_map(value):
        result = {}

        if not value:
            return result

        for item in str(value).split(","):
            item = item.strip()
            if not item:
                continue

            if "=" not in item:
                continue

            key, target = item.split("=", 1)
            key = key.strip()
            target = target.strip()

            if not key or not target:
                continue

            if ":" not in target:
                continue

            kind, vmid = target.split(":", 1)
            kind = kind.strip().lower()
            vmid = vmid.strip()

            if kind not in {"ct", "vm"}:
                continue

            if not vmid:
                continue

            result[key] = {
                "kind": kind,
                "vmid": vmid,
            }

        return result

    dry_run = parse_bool(os.getenv("EDGE_POWER_DRY_RUN"), True)
    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()
    shutdown_timeout = int(os.getenv("EDGE_POWER_CONTAINER_SHUTDOWN_TIMEOUT", "60"))
    target_map = parse_target_map(os.getenv("EDGE_POWER_TARGET_MAP", ""))

    if not ssh_target:
        raise HTTPException(
            status_code=500,
            detail="EDGE_PROXMOX_SSH_TARGET is not configured.",
        )

    idle_result = await power_idle_tick()
    inventory_result = await proxmox_inventory()

    containers = inventory_result.get("containers", [])
    vms = inventory_result.get("vms", [])

    inventory_lookup = {}

    for item in containers:
        inventory_lookup[("ct", str(item.get("vmid")))] = item
        inventory_lookup[("name", str(item.get("name")))] = item

    for item in vms:
        inventory_lookup[("vm", str(item.get("vmid")))] = item
        inventory_lookup[("name", str(item.get("name")))] = item

    container_stop_plans = []

    for action in idle_result.get("container_actions", []):
        worker_id = action.get("worker_id")
        target_name = action.get("target_name")
        idle_action = action.get("action")

        lookup_keys = [
            target_name,
            worker_id,
        ]

        mapped = None
        mapped_from = None

        for key in lookup_keys:
            if key in target_map:
                mapped = target_map[key]
                mapped_from = key
                break

        base_plan = {
            "worker_id": worker_id,
            "target_name": target_name,
            "idle_action": idle_action,
            "mapped_from": mapped_from,
            "mapped_target": mapped,
            "eligible": False,
            "blocked_reason": None,
            "would_run": None,
            "item": None,
        }

        if idle_action != "would_stop_worker_target":
            base_plan["blocked_reason"] = f"Idle action is {idle_action}, not would_stop_worker_target."
            container_stop_plans.append(base_plan)
            continue

        if not mapped:
            base_plan["blocked_reason"] = "No EDGE_POWER_TARGET_MAP entry matched this worker/target."
            container_stop_plans.append(base_plan)
            continue

        kind = mapped["kind"]
        vmid = mapped["vmid"]

        item = inventory_lookup.get((kind, vmid))
        base_plan["item"] = item

        if not item:
            base_plan["blocked_reason"] = f"Mapped target {kind}:{vmid} was not found in Proxmox inventory."
            container_stop_plans.append(base_plan)
            continue

        if item.get("protected"):
            base_plan["blocked_reason"] = f"Mapped target {kind}:{vmid} is protected."
            container_stop_plans.append(base_plan)
            continue

        if not item.get("auto_managed"):
            base_plan["blocked_reason"] = f"Mapped target {kind}:{vmid} is not auto-managed."
            container_stop_plans.append(base_plan)
            continue

        if not item.get("running"):
            base_plan["blocked_reason"] = f"Mapped target {kind}:{vmid} is already stopped."
            container_stop_plans.append(base_plan)
            continue

        if kind == "ct":
            remote_command = f"pct shutdown {vmid} --timeout {shutdown_timeout}"
        else:
            remote_command = f"qm shutdown {vmid} --timeout {shutdown_timeout}"

        base_plan["eligible"] = True
        base_plan["blocked_reason"] = None
        base_plan["would_run"] = f"ssh {ssh_target!r} {remote_command!r}"

        container_stop_plans.append(base_plan)

    inventory_summary = inventory_result.get("summary", {})
    idle_host_actions = idle_result.get("host_actions", [])

    host_shutdown_plan = {
        "eligible": False,
        "blocked_reason": None,
        "would_run": None,
        "inventory_summary": inventory_summary,
        "idle_host_actions": idle_host_actions,
    }

    if inventory_summary.get("host_shutdown_safe_now"):
        host_shutdown_plan["eligible"] = True
        host_shutdown_plan["would_run"] = f"ssh {ssh_target!r} 'shutdown -h now'"
    elif inventory_summary.get("host_shutdown_safe_if_auto_managed_stopped"):
        host_shutdown_plan["blocked_reason"] = (
            "Host shutdown is blocked until auto-managed running CTs/VMs are stopped "
            "and inventory confirms zero running workloads."
        )
    else:
        host_shutdown_plan["blocked_reason"] = (
            "Host shutdown is blocked because protected or manual/unknown workloads may be running."
        )

    return {
        "ok": True,
        "dry_run": dry_run,
        "time": datetime.now(timezone.utc).isoformat(),
        "ssh_target": ssh_target,
        "target_map": target_map,
        "idle_summary": {
            "queue": idle_result.get("queue"),
            "container_actions": idle_result.get("container_actions"),
            "host_actions": idle_result.get("host_actions"),
        },
        "inventory_summary": inventory_summary,
        "container_stop_plans": container_stop_plans,
        "host_shutdown_plan": host_shutdown_plan,
        "note": "This endpoint is dry-run only and does not execute commands.",
    }


# ---------------------------------------------------------------------
# Manual power stop execution endpoint
# ---------------------------------------------------------------------
@app.post("/power/execute-stop-plan")
async def power_execute_stop_plan(confirm: str = ""):
    """
    Manually execute eligible auto-managed stop commands.

    Safety gates:
      1. EDGE_POWER_EXECUTE_STOPS must be enabled.
      2. confirm must equal STOP_AUTO_MANAGED_TARGETS.
      3. /power/stop-plan must say the target is eligible.
      4. Only auto-managed, non-protected, running targets can be stopped.
      5. Host shutdown is not executed here.
    """
    import os
    import subprocess
    from datetime import datetime, timezone
    from fastapi import HTTPException

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    execute_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_STOPS"), False)
    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()
    shutdown_timeout = int(os.getenv("EDGE_POWER_CONTAINER_SHUTDOWN_TIMEOUT", "60"))

    required_confirmation = "STOP_AUTO_MANAGED_TARGETS"

    plan = await power_stop_plan()

    if confirm != required_confirmation:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required_confirmation,
            "example": "/power/execute-stop-plan?confirm=STOP_AUTO_MANAGED_TARGETS",
            "plan": plan,
        }

    if not execute_enabled:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "EDGE_POWER_EXECUTE_STOPS is not enabled.",
            "how_to_enable": "Set Environment=EDGE_POWER_EXECUTE_STOPS=1 in the controller systemd drop-in, then restart the controller.",
            "plan": plan,
        }

    if not ssh_target:
        raise HTTPException(
            status_code=500,
            detail="EDGE_PROXMOX_SSH_TARGET is not configured.",
        )

    executions = []

    for stop_plan in plan.get("container_stop_plans", []):
        if not stop_plan.get("eligible"):
            executions.append(
                {
                    "worker_id": stop_plan.get("worker_id"),
                    "target_name": stop_plan.get("target_name"),
                    "executed": False,
                    "blocked_reason": stop_plan.get("blocked_reason") or "Stop plan was not eligible.",
                }
            )
            continue

        mapped = stop_plan.get("mapped_target") or {}
        kind = str(mapped.get("kind") or "").strip().lower()
        vmid = str(mapped.get("vmid") or "").strip()

        if kind not in {"ct", "vm"} or not vmid:
            executions.append(
                {
                    "worker_id": stop_plan.get("worker_id"),
                    "target_name": stop_plan.get("target_name"),
                    "executed": False,
                    "blocked_reason": "Mapped target was missing or invalid.",
                    "mapped_target": mapped,
                }
            )
            continue

        if kind == "ct":
            remote_command = f"pct shutdown {vmid} --timeout {shutdown_timeout}"
        else:
            remote_command = f"qm shutdown {vmid} --timeout {shutdown_timeout}"

        cmd = [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=accept-new",
            ssh_target,
            remote_command,
        ]

        try:
            result = subprocess.run(
                cmd,
                text=True,
                capture_output=True,
                timeout=shutdown_timeout + 15,
                check=False,
            )
        except subprocess.TimeoutExpired:
            executions.append(
                {
                    "worker_id": stop_plan.get("worker_id"),
                    "target_name": stop_plan.get("target_name"),
                    "kind": kind,
                    "vmid": vmid,
                    "executed": False,
                    "blocked_reason": "Timed out while executing shutdown command.",
                    "remote_command": remote_command,
                }
            )
            continue
        except Exception as e:
            executions.append(
                {
                    "worker_id": stop_plan.get("worker_id"),
                    "target_name": stop_plan.get("target_name"),
                    "kind": kind,
                    "vmid": vmid,
                    "executed": False,
                    "blocked_reason": f"Failed to execute shutdown command: {e}",
                    "remote_command": remote_command,
                }
            )
            continue

        postprocess_offline_marker_after_successful_stop = None

        if result.returncode == 0:
            postprocess_offline_marker_after_successful_stop = _power_mark_worker_offline_after_stop(
                stop_plan.get("target_name") or stop_plan.get("worker_id") or "",
                reason=f"Intentional auto-managed stop executed for {kind}:{vmid}.",
            )

        executions.append(
            {
                "worker_id": stop_plan.get("worker_id"),
                "target_name": stop_plan.get("target_name"),
                "kind": kind,
                "vmid": vmid,
                "executed": result.returncode == 0,
                "offline_marker_result": postprocess_offline_marker_after_successful_stop,
                "returncode": result.returncode,
                "remote_command": remote_command,
                "stdout": result.stdout[-2000:],
                "stderr": result.stderr[-2000:],
            }
        )

    return {
        "ok": True,
        "executed": any(item.get("executed") for item in executions),
        "time": datetime.now(timezone.utc).isoformat(),
        "execute_enabled": execute_enabled,
        "confirm": confirm,
        "executions": executions,
        "note": "This endpoint only stops eligible auto-managed CT/VM targets. It does not shut down the Proxmox host.",
    }


# ---------------------------------------------------------------------
# Host wake plan and guarded execution endpoints
# ---------------------------------------------------------------------
@app.post("/power/wake-plan")
async def power_wake_plan():
    """
    Build a dry-run Wake-on-LAN plan for the Proxmox host.

    This endpoint does not send a magic packet.
    """
    import os
    import re
    from datetime import datetime, timezone

    host_id = os.getenv("EDGE_PROXMOX_HOST_ID", "pveso").strip() or "pveso"
    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()
    mac = os.getenv("EDGE_PROXMOX_WAKE_MAC", "").strip()
    broadcast = os.getenv("EDGE_PROXMOX_WAKE_BROADCAST", "192.168.0.255").strip()
    port = int(os.getenv("EDGE_PROXMOX_WAKE_PORT", "9"))

    clean_mac = re.sub(r"[^0-9A-Fa-f]", "", mac)
    mac_valid = len(clean_mac) == 12 and all(c in "0123456789abcdefABCDEF" for c in clean_mac)

    eligible = bool(mac_valid and broadcast and port > 0)

    blocked_reason = None
    if not mac:
        blocked_reason = "EDGE_PROXMOX_WAKE_MAC is not configured."
    elif not mac_valid:
        blocked_reason = "EDGE_PROXMOX_WAKE_MAC is not a valid MAC address."
    elif not broadcast:
        blocked_reason = "EDGE_PROXMOX_WAKE_BROADCAST is not configured."
    elif port <= 0:
        blocked_reason = "EDGE_PROXMOX_WAKE_PORT must be greater than zero."

    return {
        "ok": True,
        "dry_run": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "host_id": host_id,
        "ssh_target": ssh_target,
        "wake": {
            "mac": mac,
            "broadcast": broadcast,
            "port": port,
            "eligible": eligible,
            "blocked_reason": blocked_reason,
            "would_send": (
                f"Wake-on-LAN magic packet to {mac} via UDP {broadcast}:{port}"
                if eligible
                else None
            ),
        },
        "note": (
            "Wake-on-LAN works only if the controller is on a network path that can deliver "
            "the broadcast packet to the Proxmox host NIC."
        ),
    }


@app.post("/power/execute-wake")
async def power_execute_wake(confirm: str = ""):
    """
    Manually send a Wake-on-LAN magic packet.

    Safety gates:
      1. EDGE_POWER_EXECUTE_WAKE must be enabled.
      2. confirm must equal WAKE_PROXMOX_HOST.
      3. /power/wake-plan must be eligible.
    """
    import os
    import re
    import socket
    from datetime import datetime, timezone

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    required_confirmation = "WAKE_PROXMOX_HOST"
    execute_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_WAKE"), False)

    plan = await power_wake_plan()
    wake = plan.get("wake", {})

    if confirm != required_confirmation:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required_confirmation,
            "example": "/power/execute-wake?confirm=WAKE_PROXMOX_HOST",
            "plan": plan,
        }

    if not execute_enabled:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "EDGE_POWER_EXECUTE_WAKE is not enabled.",
            "how_to_enable": "Set Environment=EDGE_POWER_EXECUTE_WAKE=1, then restart the controller.",
            "plan": plan,
        }

    if not wake.get("eligible"):
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": wake.get("blocked_reason") or "Wake plan is not eligible.",
            "plan": plan,
        }

    mac = wake["mac"]
    broadcast = wake["broadcast"]
    port = int(wake["port"])

    clean_mac = re.sub(r"[^0-9A-Fa-f]", "", mac)
    mac_bytes = bytes.fromhex(clean_mac)

    magic_packet = b"\xff" * 6 + mac_bytes * 16

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.settimeout(3)
        sent = sock.sendto(magic_packet, (broadcast, port))
        sock.close()
    except Exception as e:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": f"Failed to send Wake-on-LAN packet: {e}",
            "plan": plan,
        }

    return {
        "ok": True,
        "executed": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "host_id": plan.get("host_id"),
        "mac": mac,
        "broadcast": broadcast,
        "port": port,
        "bytes_sent": sent,
        "note": "Magic packet sent. If the host is already on, this usually has no visible effect.",
    }


# ---------------------------------------------------------------------
# Host shutdown plan and guarded execution endpoints
# ---------------------------------------------------------------------
@app.post("/power/host-shutdown-plan")
async def power_host_shutdown_plan():
    """
    Build a dry-run Proxmox host shutdown plan.

    This endpoint does not shut down the host.
    """
    import os
    from datetime import datetime, timezone

    host_id = os.getenv("EDGE_PROXMOX_HOST_ID", "pveso").strip() or "pveso"
    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()

    idle_result = await power_idle_tick()
    inventory_result = await proxmox_inventory()
    wake_result = await power_wake_plan()

    queue = idle_result.get("queue", {})
    inventory_summary = inventory_result.get("summary", {})
    wake = wake_result.get("wake", {})

    queue_now_empty = bool(queue.get("queue_now_empty"))
    active_jobs_count = queue.get("active_jobs_count")
    worker_busy_count = queue.get("worker_busy_count")
    worker_queue_depth_total = queue.get("worker_queue_depth_total")

    host_shutdown_safe_now = bool(inventory_summary.get("host_shutdown_safe_now"))
    running_total = int(inventory_summary.get("running_total") or 0)
    running_protected = int(inventory_summary.get("running_protected") or 0)
    running_manual_or_unknown = int(inventory_summary.get("running_manual_or_unknown") or 0)
    wake_eligible = bool(wake.get("eligible"))

    eligible = (
        bool(ssh_target)
        and queue_now_empty
        and host_shutdown_safe_now
        and running_total == 0
        and running_protected == 0
        and running_manual_or_unknown == 0
        and wake_eligible
    )

    blocked_reasons = []

    if not ssh_target:
        blocked_reasons.append("EDGE_PROXMOX_SSH_TARGET is not configured.")

    if not queue_now_empty:
        blocked_reasons.append("Queue is not empty or could not be safely evaluated.")

    if active_jobs_count not in (0, None):
        blocked_reasons.append(f"active_jobs_count is {active_jobs_count}, not 0.")

    if worker_busy_count not in (0, None):
        blocked_reasons.append(f"worker_busy_count is {worker_busy_count}, not 0.")

    if worker_queue_depth_total not in (0, None):
        blocked_reasons.append(f"worker_queue_depth_total is {worker_queue_depth_total}, not 0.")

    if not host_shutdown_safe_now:
        blocked_reasons.append("Proxmox inventory does not say host_shutdown_safe_now=true.")

    if running_total != 0:
        blocked_reasons.append(f"running_total is {running_total}, not 0.")

    if running_protected != 0:
        blocked_reasons.append(f"running_protected is {running_protected}, not 0.")

    if running_manual_or_unknown != 0:
        blocked_reasons.append(f"running_manual_or_unknown is {running_manual_or_unknown}, not 0.")

    if not wake_eligible:
        blocked_reasons.append("Wake plan is not eligible; refusing to plan host shutdown without a recovery path.")

    return {
        "ok": True,
        "dry_run": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "host_id": host_id,
        "ssh_target": ssh_target,
        "eligible": eligible,
        "blocked_reasons": blocked_reasons,
        "would_run": f"ssh {ssh_target!r} 'shutdown -h now'" if eligible else None,
        "queue": queue,
        "inventory_summary": inventory_summary,
        "wake": wake,
        "note": "This endpoint is dry-run only. It does not shut down the Proxmox host.",
    }


@app.post("/power/execute-host-shutdown")
async def power_execute_host_shutdown(confirm: str = ""):
    """
    Manually execute guarded Proxmox host shutdown.

    Safety gates:
      1. EDGE_POWER_EXECUTE_HOST_SHUTDOWN must be enabled.
      2. confirm must equal SHUTDOWN_PROXMOX_HOST.
      3. /power/host-shutdown-plan must be eligible.
      4. Wake plan must be eligible before shutdown is allowed.
    """
    import os
    import subprocess
    from datetime import datetime, timezone

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    required_confirmation = "SHUTDOWN_PROXMOX_HOST"
    execute_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_HOST_SHUTDOWN"), False)

    plan = await power_host_shutdown_plan()

    if confirm != required_confirmation:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required_confirmation,
            "example": "/power/execute-host-shutdown?confirm=SHUTDOWN_PROXMOX_HOST",
            "plan": plan,
        }

    if not execute_enabled:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "EDGE_POWER_EXECUTE_HOST_SHUTDOWN is not enabled.",
            "how_to_enable": "Set Environment=EDGE_POWER_EXECUTE_HOST_SHUTDOWN=1, then restart the controller.",
            "plan": plan,
        }

    if not plan.get("eligible"):
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Host shutdown plan is not eligible.",
            "blocked_reasons": plan.get("blocked_reasons", []),
            "plan": plan,
        }

    ssh_target = plan.get("ssh_target")
    remote_command = "shutdown -h now"

    cmd = [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=5",
        "-o", "StrictHostKeyChecking=accept-new",
        ssh_target,
        remote_command,
    ]

    try:
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Timed out while sending host shutdown command.",
            "remote_command": remote_command,
            "plan": plan,
        }
    except Exception as e:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": f"Failed to send host shutdown command: {e}",
            "remote_command": remote_command,
            "plan": plan,
        }

    return {
        "ok": True,
        "executed": result.returncode == 0,
        "time": datetime.now(timezone.utc).isoformat(),
        "host_id": plan.get("host_id"),
        "ssh_target": ssh_target,
        "remote_command": remote_command,
        "returncode": result.returncode,
        "stdout": result.stdout[-2000:],
        "stderr": result.stderr[-2000:],
        "note": "If successful, the Proxmox host should power off shortly.",
    }


# ---------------------------------------------------------------------
# Power automation tick endpoint
# ---------------------------------------------------------------------
@app.post("/power/auto/tick")
async def power_auto_tick():
    """
    Combined idle power automation tick.

    Safety model:
      - This endpoint can be called every minute by a timer.
      - It only executes CT/VM stops if EDGE_POWER_AUTO_STOP_WORKERS=1
        and the existing guarded execution endpoint allows it.
      - It only executes host shutdown if EDGE_POWER_AUTO_SHUTDOWN_HOST=1
        and the existing guarded host shutdown endpoint allows it.
      - By default, both automation flags are disabled.
    """
    import os
    from datetime import datetime, timezone

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    auto_stop_workers = parse_bool(os.getenv("EDGE_POWER_AUTO_STOP_WORKERS"), False)
    auto_shutdown_host = parse_bool(os.getenv("EDGE_POWER_AUTO_SHUTDOWN_HOST"), False)
    auto_start_workers = parse_bool(os.getenv("EDGE_POWER_AUTO_START_WORKERS"), False)

    auto_status = await power_auto_status()
    if auto_status.get("paused"):
        return {
            "ok": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "automation": {
                "auto_stop_workers": auto_stop_workers,
                "auto_shutdown_host": auto_shutdown_host,
                "auto_start_workers": auto_start_workers,
                "paused": True,
                "pause_reason": auto_status.get("pause_reason"),
                "pause_until": auto_status.get("pause_until"),
                "pause_remaining_seconds": auto_status.get("pause_remaining_seconds"),
            },
            "actions": [
                {
                    "area": "automation",
                    "action": "automation_paused",
                    "executed": False,
                    "reason": auto_status.get("pause_reason"),
                    "pause_until": auto_status.get("pause_until"),
                    "pause_remaining_seconds": auto_status.get("pause_remaining_seconds"),
                }
            ],
            "note": "Power automation is paused. No worker stop or host shutdown action was evaluated.",
        }

    execute_stops_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_STOPS"), False)
    execute_host_shutdown_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_HOST_SHUTDOWN"), False)
    execute_wake_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_WAKE"), False)
    execute_wake_and_start_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_WAKE_AND_START"), False)

    queue_demand = _power_auto_queue_demand_state()
    worker_registry_state = _power_lookup_worker_registry_state("llms_ollama")
    worker_start_plan = await power_start_worker_plan(target_name="llms_ollama")

    stop_plan = await power_stop_plan()
    host_plan = await power_host_shutdown_plan()
    wake_plan = await power_wake_plan()

    container_plans = stop_plan.get("container_stop_plans", [])
    eligible_container_plans = [
        plan for plan in container_plans
        if plan.get("eligible")
    ]

    actions = []

    # ------------------------------------------------------------
    # Worker/CT start automation decision
    # ------------------------------------------------------------
    if queue_demand.get("has_start_demand"):
        start_plan_blocked_reason = worker_start_plan.get("blocked_reason") or ""

        if worker_start_plan.get("eligible"):
            if not auto_start_workers:
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "would_auto_start_worker",
                        "executed": False,
                        "reason": "Queued jobs exist and worker target is stopped/eligible, but EDGE_POWER_AUTO_START_WORKERS=0.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                    }
                )
            elif not execute_wake_and_start_enabled:
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "blocked_auto_start_execution_disabled",
                        "executed": False,
                        "reason": "Queued jobs exist and worker target is stopped/eligible, but EDGE_POWER_EXECUTE_WAKE_AND_START=0.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                    }
                )
            else:
                start_result = await power_execute_wake_and_start_worker(
                    target_name="llms_ollama",
                    confirm="WAKE_AND_START_WORKER",
                    pause_after_start_minutes=10,
                    wait_worker_seconds=180,
                    wait_registry_seconds=180,
                )
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "auto_wake_and_start_worker_executed",
                        "executed": bool(start_result.get("executed")),
                        "reason": "Queued jobs exist, worker target is stopped/eligible, and guarded wake-and-start execution was called.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                        "result": start_result,
                    }
                )

        elif "already running" in start_plan_blocked_reason and worker_registry_state.get("computed_health") == "available":
            actions.append(
                {
                    "area": "worker_start",
                    "action": "no_worker_start_needed",
                    "executed": False,
                    "reason": "Queued jobs exist, worker target is already running, and worker registry shows available.",
                    "queue_demand": queue_demand,
                    "worker_registry_state": worker_registry_state,
                    "worker_start_plan": worker_start_plan,
                }
            )

        elif "already running" in start_plan_blocked_reason:
            if not auto_start_workers:
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "would_recover_running_worker",
                        "executed": False,
                        "reason": "Worker target is running but registry is not available; EDGE_POWER_AUTO_START_WORKERS=0.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                    }
                )
            elif not execute_wake_and_start_enabled:
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "blocked_recover_running_worker_execution_disabled",
                        "executed": False,
                        "reason": "Worker target is running but registry is not available; EDGE_POWER_EXECUTE_WAKE_AND_START=0.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                    }
                )
            else:
                start_result = await power_execute_wake_and_start_worker(
                    target_name="llms_ollama",
                    confirm="WAKE_AND_START_WORKER",
                    pause_after_start_minutes=10,
                    wait_worker_seconds=180,
                    wait_registry_seconds=180,
                )
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "auto_recover_running_worker_executed",
                        "executed": bool(start_result.get("executed")),
                        "reason": "Worker target is running but registry was not available, so guarded wake-and-start recovery was called.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                        "result": start_result,
                    }
                )

        else:
            actions.append(
                {
                    "area": "worker_start",
                    "action": "worker_start_blocked_by_plan",
                    "executed": False,
                    "reason": worker_start_plan.get("blocked_reason") or "Worker start plan is not eligible.",
                    "queue_demand": queue_demand,
                    "worker_registry_state": worker_registry_state,
                    "worker_start_plan": worker_start_plan,
                }
            )
    else:
        actions.append(
            {
                "area": "worker_start",
                "action": "no_start_demand",
                "executed": False,
                "reason": "No queued jobs require a worker start.",
                "queue_demand": queue_demand,
                "worker_registry_state": worker_registry_state,
            }
        )

    # ------------------------------------------------------------
    # Worker/CT stop automation decision
    # ------------------------------------------------------------
    if queue_demand.get("has_start_demand"):
        actions.append(
            {
                "area": "worker_stop",
                "action": "skip_worker_stop_due_to_queue_demand",
                "executed": False,
                "reason": "Queued jobs exist, so auto-stop is skipped.",
                "queue_demand": queue_demand,
            }
        )
    elif eligible_container_plans:
        if not auto_stop_workers:
            actions.append(
                {
                    "area": "worker_stop",
                    "action": "would_auto_stop_worker_targets",
                    "executed": False,
                    "reason": "Eligible worker targets exist, but EDGE_POWER_AUTO_STOP_WORKERS=0.",
                    "eligible_count": len(eligible_container_plans),
                    "plans": eligible_container_plans,
                }
            )
        elif not execute_stops_enabled:
            actions.append(
                {
                    "area": "worker_stop",
                    "action": "blocked_auto_stop_execution_disabled",
                    "executed": False,
                    "reason": "EDGE_POWER_AUTO_STOP_WORKERS=1, but EDGE_POWER_EXECUTE_STOPS=0.",
                    "eligible_count": len(eligible_container_plans),
                    "plans": eligible_container_plans,
                }
            )
        else:
            execution_result = await power_execute_stop_plan(
                confirm="STOP_AUTO_MANAGED_TARGETS"
            )
            actions.append(
                {
                    "area": "worker_stop",
                    "action": "auto_stop_worker_targets_executed",
                    "executed": bool(execution_result.get("executed")),
                    "reason": "Auto stop was enabled and guarded stop execution was called.",
                    "result": execution_result,
                }
            )
    else:
        actions.append(
            {
                "area": "worker_stop",
                "action": "no_worker_stop_needed",
                "executed": False,
                "reason": "No eligible worker stop plans.",
                "plans": container_plans,
            }
        )

    # ------------------------------------------------------------
    # Host shutdown automation decision
    # ------------------------------------------------------------
    if host_plan.get("eligible"):
        if not auto_shutdown_host:
            actions.append(
                {
                    "area": "host_shutdown",
                    "action": "would_auto_shutdown_host",
                    "executed": False,
                    "reason": "Host shutdown plan is eligible, but EDGE_POWER_AUTO_SHUTDOWN_HOST=0.",
                    "would_run": host_plan.get("would_run"),
                }
            )
        elif not execute_host_shutdown_enabled:
            actions.append(
                {
                    "area": "host_shutdown",
                    "action": "blocked_auto_host_shutdown_execution_disabled",
                    "executed": False,
                    "reason": "EDGE_POWER_AUTO_SHUTDOWN_HOST=1, but EDGE_POWER_EXECUTE_HOST_SHUTDOWN=0.",
                    "would_run": host_plan.get("would_run"),
                }
            )
        else:
            shutdown_result = await power_execute_host_shutdown(
                confirm="SHUTDOWN_PROXMOX_HOST"
            )
            actions.append(
                {
                    "area": "host_shutdown",
                    "action": "auto_host_shutdown_executed",
                    "executed": bool(shutdown_result.get("executed")),
                    "reason": "Auto host shutdown was enabled and guarded host shutdown execution was called.",
                    "result": shutdown_result,
                }
            )
    else:
        actions.append(
            {
                "area": "host_shutdown",
                "action": "no_host_shutdown",
                "executed": False,
                "reason": "Host shutdown plan is not eligible.",
                "blocked_reasons": host_plan.get("blocked_reasons", []),
            }
        )

    return {
        "ok": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "automation": {
            "auto_stop_workers": auto_stop_workers,
            "auto_shutdown_host": auto_shutdown_host,
            "auto_start_workers": auto_start_workers,
            "execute_stops_enabled": execute_stops_enabled,
            "execute_host_shutdown_enabled": execute_host_shutdown_enabled,
            "execute_wake_enabled": execute_wake_enabled,
            "execute_wake_and_start_enabled": execute_wake_and_start_enabled,
        },
        "stop_plan_summary": {
            "eligible_container_stop_count": len(eligible_container_plans),
            "container_stop_plans": container_plans,
        },
        "host_plan_summary": {
            "eligible": host_plan.get("eligible"),
            "blocked_reasons": host_plan.get("blocked_reasons", []),
            "would_run": host_plan.get("would_run"),
            "inventory_summary": host_plan.get("inventory_summary"),
        },
        "wake_plan_summary": {
            "eligible": (wake_plan.get("wake") or {}).get("eligible"),
            "would_send": (wake_plan.get("wake") or {}).get("would_send"),
        },
        "actions": actions,
        "note": "Automation flags are separate from execution flags. Keep both disabled until intentionally testing automation.",
    }


# ---------------------------------------------------------------------
# Power automation pause/resume endpoints
# ---------------------------------------------------------------------
def _power_auto_find_db_path():
    from pathlib import Path
    from fastapi import HTTPException

    candidates = []

    for name, value in globals().items():
        upper = name.upper()

        if "DB" in upper and ("PATH" in upper or "FILE" in upper or "DATABASE" in upper):
            if isinstance(value, (str, Path)):
                text = str(value)

                if text.startswith("sqlite:///"):
                    text = text.replace("sqlite:///", "", 1)

                if text and not text.startswith("postgres"):
                    candidates.append(Path(text))

    for candidate in candidates:
        if candidate.exists():
            return candidate

    fallback_names = [
        "edge_queue.sqlite3",
        "edge_queue.sqlite",
        "edge_queue.db",
        "edge_controller.db",
        "edge_controller.sqlite",
        "edge_controller.sqlite3",
        "queue_controller.db",
        "queue_controller.sqlite",
        "queue_controller.sqlite3",
    ]

    here = Path(__file__).resolve().parent
    for name in fallback_names:
        candidate = here / name
        if candidate.exists():
            return candidate

    raise HTTPException(
        status_code=500,
        detail="Could not locate SQLite database path for power automation state.",
    )


def _power_auto_init_state(conn):
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS power_auto_state (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TEXT NOT NULL
        )
        """
    )


@app.post("/power/auto/status")
async def power_auto_status():
    """
    Show whether power automation is paused.

    Pause sources:
      1. EDGE_POWER_AUTO_PAUSED=1 environment variable
      2. /power/auto/pause database pause_until timestamp
    """
    import os
    import sqlite3
    from datetime import datetime, timezone

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    now = datetime.now(timezone.utc)
    env_paused = parse_bool(os.getenv("EDGE_POWER_AUTO_PAUSED"), False)

    db_path = _power_auto_find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        _power_auto_init_state(conn)

        row = conn.execute(
            "SELECT value FROM power_auto_state WHERE key = ?",
            ("pause_until",),
        ).fetchone()

        pause_until = row["value"] if row else None
        pause_remaining_seconds = 0
        db_paused = False

        if pause_until:
            try:
                pause_dt = datetime.fromisoformat(pause_until)
                if pause_dt.tzinfo is None:
                    pause_dt = pause_dt.replace(tzinfo=timezone.utc)

                pause_remaining_seconds = int((pause_dt - now).total_seconds())

                if pause_remaining_seconds > 0:
                    db_paused = True
                else:
                    conn.execute(
                        "DELETE FROM power_auto_state WHERE key = ?",
                        ("pause_until",),
                    )
                    conn.commit()
                    pause_until = None
                    pause_remaining_seconds = 0

            except Exception:
                # Bad stored value should not permanently break automation status.
                conn.execute(
                    "DELETE FROM power_auto_state WHERE key = ?",
                    ("pause_until",),
                )
                conn.commit()
                pause_until = None
                pause_remaining_seconds = 0

        paused = env_paused or db_paused

        if env_paused:
            pause_reason = "EDGE_POWER_AUTO_PAUSED=1"
        elif db_paused:
            pause_reason = "manual temporary pause"
        else:
            pause_reason = None

        return {
            "ok": True,
            "time": now.isoformat(),
            "paused": paused,
            "pause_reason": pause_reason,
            "env_paused": env_paused,
            "db_paused": db_paused,
            "pause_until": pause_until,
            "pause_remaining_seconds": max(0, pause_remaining_seconds),
            "db_path": str(db_path),
        }

    finally:
        conn.close()


@app.post("/power/auto/pause")
async def power_auto_pause(minutes: int = 30, reason: str = "manual"):
    """
    Temporarily pause automatic power actions.

    This is intentionally easy to call because it only makes the system safer.
    """
    import sqlite3
    from datetime import datetime, timezone, timedelta

    if minutes < 1:
        minutes = 1

    if minutes > 1440:
        minutes = 1440

    now = datetime.now(timezone.utc)
    pause_until = now + timedelta(minutes=minutes)

    db_path = _power_auto_find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        _power_auto_init_state(conn)

        conn.execute(
            """
            INSERT INTO power_auto_state (key, value, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET
                value = excluded.value,
                updated_at = excluded.updated_at
            """,
            ("pause_until", pause_until.isoformat(), now.isoformat()),
        )

        conn.execute(
            """
            INSERT INTO power_auto_state (key, value, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET
                value = excluded.value,
                updated_at = excluded.updated_at
            """,
            ("pause_reason", reason, now.isoformat()),
        )

        conn.commit()

    finally:
        conn.close()

    return {
        "ok": True,
        "paused": True,
        "minutes": minutes,
        "reason": reason,
        "pause_until": pause_until.isoformat(),
        "note": "Automatic worker stop and host shutdown actions will be skipped while paused.",
    }


@app.post("/power/auto/resume")
async def power_auto_resume(confirm: str = ""):
    """
    Resume automatic power actions by clearing temporary pause.

    This requires confirmation because resuming could allow auto-stop if automation
    flags are enabled.
    """
    import sqlite3
    from datetime import datetime, timezone

    required_confirmation = "RESUME_POWER_AUTOMATION"

    if confirm != required_confirmation:
        return {
            "ok": False,
            "resumed": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required_confirmation,
            "example": "/power/auto/resume?confirm=RESUME_POWER_AUTOMATION",
        }

    now = datetime.now(timezone.utc)
    db_path = _power_auto_find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        _power_auto_init_state(conn)

        conn.execute(
            "DELETE FROM power_auto_state WHERE key IN (?, ?)",
            ("pause_until", "pause_reason"),
        )

        conn.commit()

    finally:
        conn.close()

    return {
        "ok": True,
        "resumed": True,
        "time": now.isoformat(),
        "note": "Temporary DB pause cleared. Environment pause EDGE_POWER_AUTO_PAUSED=1, if set, still takes priority.",
    }


# ---------------------------------------------------------------------
# Worker start plan and guarded execution endpoints
# ---------------------------------------------------------------------
@app.post("/power/start-worker-plan")
async def power_start_worker_plan(target_name: str = "llms_ollama"):
    """
    Build a dry-run plan to start an auto-managed worker CT/VM.

    This endpoint does not start anything.
    """
    import os
    from datetime import datetime, timezone
    from fastapi import HTTPException

    def parse_target_map(value):
        result = {}

        if not value:
            return result

        for item in str(value).split(","):
            item = item.strip()
            if not item or "=" not in item:
                continue

            key, target = item.split("=", 1)
            key = key.strip()
            target = target.strip()

            if not key or ":" not in target:
                continue

            kind, vmid = target.split(":", 1)
            kind = kind.strip().lower()
            vmid = vmid.strip()

            if kind not in {"ct", "vm"}:
                continue

            if not vmid:
                continue

            result[key] = {"kind": kind, "vmid": vmid}

        return result

    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()
    target_map = parse_target_map(os.getenv("EDGE_POWER_TARGET_MAP", ""))

    if not ssh_target:
        raise HTTPException(
            status_code=500,
            detail="EDGE_PROXMOX_SSH_TARGET is not configured.",
        )

    mapped = target_map.get(target_name)

    if not mapped:
        return {
            "ok": True,
            "dry_run": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "target_name": target_name,
            "eligible": False,
            "blocked_reason": "target_name is not present in EDGE_POWER_TARGET_MAP.",
            "target_map": target_map,
            "would_run": None,
        }

    inventory_result = await proxmox_inventory()

    inventory_lookup = {}

    for item in inventory_result.get("containers", []):
        inventory_lookup[("ct", str(item.get("vmid")))] = item
        inventory_lookup[("name", str(item.get("name")))] = item

    for item in inventory_result.get("vms", []):
        inventory_lookup[("vm", str(item.get("vmid")))] = item
        inventory_lookup[("name", str(item.get("name")))] = item

    kind = mapped["kind"]
    vmid = mapped["vmid"]

    item = inventory_lookup.get((kind, vmid))

    if not item:
        return {
            "ok": True,
            "dry_run": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "target_name": target_name,
            "mapped_target": mapped,
            "eligible": False,
            "blocked_reason": f"Mapped target {kind}:{vmid} was not found in Proxmox inventory.",
            "would_run": None,
            "inventory_summary": inventory_result.get("summary"),
        }

    if item.get("protected"):
        return {
            "ok": True,
            "dry_run": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "target_name": target_name,
            "mapped_target": mapped,
            "item": item,
            "eligible": False,
            "blocked_reason": f"Mapped target {kind}:{vmid} is protected.",
            "would_run": None,
            "inventory_summary": inventory_result.get("summary"),
        }

    if not item.get("auto_managed"):
        return {
            "ok": True,
            "dry_run": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "target_name": target_name,
            "mapped_target": mapped,
            "item": item,
            "eligible": False,
            "blocked_reason": f"Mapped target {kind}:{vmid} is not auto-managed.",
            "would_run": None,
            "inventory_summary": inventory_result.get("summary"),
        }

    if item.get("running"):
        return {
            "ok": True,
            "dry_run": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "target_name": target_name,
            "mapped_target": mapped,
            "item": item,
            "eligible": False,
            "blocked_reason": f"Mapped target {kind}:{vmid} is already running.",
            "would_run": None,
            "inventory_summary": inventory_result.get("summary"),
        }

    if kind == "ct":
        remote_command = f"pct start {vmid}"
    else:
        remote_command = f"qm start {vmid}"

    return {
        "ok": True,
        "dry_run": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "target_name": target_name,
        "mapped_target": mapped,
        "item": item,
        "eligible": True,
        "blocked_reason": None,
        "would_run": f"ssh {ssh_target!r} {remote_command!r}",
        "remote_command": remote_command,
        "inventory_summary": inventory_result.get("summary"),
        "note": "This endpoint is dry-run only. It does not start the worker.",
    }


@app.post("/power/execute-start-worker")
async def power_execute_start_worker(
    target_name: str = "llms_ollama",
    confirm: str = "",
    pause_after_start_minutes: int = 10,
):
    """
    Manually start an eligible auto-managed worker CT/VM.

    Safety gates:
      1. EDGE_POWER_EXECUTE_START_WORKERS must be enabled.
      2. confirm must equal START_AUTO_MANAGED_TARGETS.
      3. /power/start-worker-plan must be eligible.
    """
    import os
    import subprocess
    from datetime import datetime, timezone

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    required_confirmation = "START_AUTO_MANAGED_TARGETS"
    execute_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_START_WORKERS"), False)
    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()

    plan = await power_start_worker_plan(target_name=target_name)

    if confirm != required_confirmation:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required_confirmation,
            "example": "/power/execute-start-worker?target_name=llms_ollama&confirm=START_AUTO_MANAGED_TARGETS",
            "plan": plan,
        }

    if not execute_enabled:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "EDGE_POWER_EXECUTE_START_WORKERS is not enabled.",
            "how_to_enable": "Set Environment=EDGE_POWER_EXECUTE_START_WORKERS=1, then restart the controller.",
            "plan": plan,
        }

    if not plan.get("eligible"):
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Worker start plan is not eligible.",
            "plan": plan,
        }

    remote_command = plan.get("remote_command")

    cmd = [
        "ssh",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=5",
        "-o", "StrictHostKeyChecking=accept-new",
        ssh_target,
        remote_command,
    ]

    try:
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=30,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Timed out while starting worker target.",
            "remote_command": remote_command,
            "plan": plan,
        }
    except Exception as e:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": f"Failed to start worker target: {e}",
            "remote_command": remote_command,
            "plan": plan,
        }

    pause_result = None

    if result.returncode == 0 and pause_after_start_minutes > 0:
        pause_result = await power_auto_pause(
            minutes=pause_after_start_minutes,
            reason=f"worker-start-{target_name}",
        )

    return {
        "ok": True,
        "executed": result.returncode == 0,
        "time": datetime.now(timezone.utc).isoformat(),
        "target_name": target_name,
        "remote_command": remote_command,
        "returncode": result.returncode,
        "stdout": result.stdout[-2000:],
        "stderr": result.stderr[-2000:],
        "pause_after_start_minutes": pause_after_start_minutes,
        "pause_result": pause_result,
        "plan": plan,
        "note": "If successful, power automation is temporarily paused so the worker can finish booting.",
    }


# ---------------------------------------------------------------------
# Wake and start worker guarded endpoint
# ---------------------------------------------------------------------
@app.post("/power/wake-and-start-worker-plan")
async def power_wake_and_start_worker_plan(target_name: str = "llms_ollama"):
    """
    Dry-run plan for waking the Proxmox host if needed and starting a worker CT/VM.

    This endpoint does not send Wake-on-LAN packets.
    This endpoint does not start CTs/VMs.
    """
    import os
    import subprocess
    from datetime import datetime, timezone

    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()
    host_id = os.getenv("EDGE_PROXMOX_HOST_ID", "pveso").strip() or "pveso"

    wake_plan = await power_wake_plan()

    host_online = False
    host_probe = {
        "attempted": False,
        "returncode": None,
        "stdout": "",
        "stderr": "",
    }

    if ssh_target:
        cmd = [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=accept-new",
            ssh_target,
            "hostname",
        ]

        host_probe["attempted"] = True

        try:
            result = subprocess.run(
                cmd,
                text=True,
                capture_output=True,
                timeout=8,
                check=False,
            )
            host_probe["returncode"] = result.returncode
            host_probe["stdout"] = result.stdout[-1000:]
            host_probe["stderr"] = result.stderr[-1000:]
            host_online = result.returncode == 0
        except Exception as e:
            host_probe["stderr"] = str(e)

    start_plan = None
    start_plan_error = None

    if host_online:
        try:
            start_plan = await power_start_worker_plan(target_name=target_name)
        except Exception as e:
            start_plan_error = str(e)

    wake_eligible = bool((wake_plan.get("wake") or {}).get("eligible"))

    steps = []

    if not ssh_target:
        steps.append(
            {
                "step": "ssh_probe",
                "action": "blocked",
                "reason": "EDGE_PROXMOX_SSH_TARGET is not configured.",
            }
        )
    elif not host_online:
        steps.append(
            {
                "step": "wake_host",
                "action": "would_send_wake_packet" if wake_eligible else "blocked",
                "reason": (
                    "Host is offline or SSH is unreachable; Wake-on-LAN is eligible."
                    if wake_eligible
                    else "Host is offline or SSH is unreachable, but wake plan is not eligible."
                ),
                "wake": wake_plan.get("wake"),
            }
        )
        steps.append(
            {
                "step": "wait_for_host_ssh",
                "action": "would_wait",
                "reason": "Would wait for Proxmox host SSH to return.",
            }
        )
        steps.append(
            {
                "step": "start_worker",
                "action": "would_recheck_after_host_online",
                "reason": "Worker start plan requires Proxmox inventory, so it will be checked after the host is online.",
            }
        )
    elif start_plan_error:
        steps.append(
            {
                "step": "start_worker",
                "action": "blocked",
                "reason": f"Could not build worker start plan: {start_plan_error}",
            }
        )
    elif start_plan and start_plan.get("eligible"):
        steps.append(
            {
                "step": "start_worker",
                "action": "would_start_worker",
                "reason": "Worker target is stopped and eligible to start.",
                "start_plan": start_plan,
            }
        )
    elif start_plan:
        blocked_reason = start_plan.get("blocked_reason")
        if blocked_reason and "already running" in blocked_reason:
            steps.append(
                {
                    "step": "start_worker",
                    "action": "already_running",
                    "reason": blocked_reason,
                    "start_plan": start_plan,
                }
            )
        else:
            steps.append(
                {
                    "step": "start_worker",
                    "action": "blocked",
                    "reason": blocked_reason or "Worker start plan is not eligible.",
                    "start_plan": start_plan,
                }
            )

    eligible = bool(
        ssh_target
        and (
            host_online
            or wake_eligible
        )
    )

    return {
        "ok": True,
        "dry_run": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "host_id": host_id,
        "ssh_target": ssh_target,
        "target_name": target_name,
        "host_online": host_online,
        "host_probe": host_probe,
        "eligible": eligible,
        "wake_plan": wake_plan,
        "start_plan": start_plan,
        "start_plan_error": start_plan_error,
        "steps": steps,
        "note": "This endpoint is dry-run only. It does not wake or start anything.",
    }


@app.post("/power/execute-wake-and-start-worker")
async def power_execute_wake_and_start_worker(
    target_name: str = "llms_ollama",
    confirm: str = "",
    wait_host_seconds: int = 180,
    wait_worker_seconds: int = 180,
    wait_registry_seconds: int = 180,
    pause_after_start_minutes: int = 10,
    health_url: str = "http://100.88.245.33:11434/api/tags",
    registry_url: str = "http://127.0.0.1:7070/workers/registry",
):
    """
    Guarded wake-and-start workflow.

    Safety gates:
      1. EDGE_POWER_EXECUTE_WAKE_AND_START must be enabled.
      2. confirm must equal WAKE_AND_START_WORKER.
      3. Wake plan must be eligible if host is offline.
      4. Start plan must be eligible if worker is stopped.
      5. Power automation is paused after successful start.
    """
    import os
    import re
    import socket
    import subprocess
    import time
    import json
    import urllib.request
    from datetime import datetime, timezone

    def parse_bool(value, default=False):
        if value is None:
            return default
        return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}

    required_confirmation = "WAKE_AND_START_WORKER"
    execute_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_WAKE_AND_START"), False)
    ssh_target = os.getenv("EDGE_PROXMOX_SSH_TARGET", "").strip()

    plan = await power_wake_and_start_worker_plan(target_name=target_name)

    if confirm != required_confirmation:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required_confirmation,
            "example": "/power/execute-wake-and-start-worker?target_name=llms_ollama&confirm=WAKE_AND_START_WORKER",
            "plan": plan,
        }

    if not execute_enabled:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "EDGE_POWER_EXECUTE_WAKE_AND_START is not enabled.",
            "how_to_enable": "Set Environment=EDGE_POWER_EXECUTE_WAKE_AND_START=1, then restart the controller.",
            "plan": plan,
        }

    if not ssh_target:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "EDGE_PROXMOX_SSH_TARGET is not configured.",
            "plan": plan,
        }

    events = []

    def ssh_hostname():
        cmd = [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=accept-new",
            ssh_target,
            "hostname",
        ]

        try:
            result = subprocess.run(
                cmd,
                text=True,
                capture_output=True,
                timeout=8,
                check=False,
            )
            return result.returncode == 0, result
        except Exception as e:
            return False, e

    host_online, host_probe = ssh_hostname()

    if not host_online:
        wake_plan = await power_wake_plan()
        wake = wake_plan.get("wake") or {}

        if not wake.get("eligible"):
            return {
                "ok": False,
                "executed": False,
                "blocked_reason": wake.get("blocked_reason") or "Wake plan is not eligible.",
                "wake_plan": wake_plan,
                "plan": plan,
            }

        mac = wake["mac"]
        broadcast = wake["broadcast"]
        port = int(wake["port"])

        clean_mac = re.sub(r"[^0-9A-Fa-f]", "", mac)
        mac_bytes = bytes.fromhex(clean_mac)
        magic_packet = b"\xff" * 6 + mac_bytes * 16

        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            sock.settimeout(3)
            sent = sock.sendto(magic_packet, (broadcast, port))
            sock.close()

            events.append(
                {
                    "step": "wake_host",
                    "executed": True,
                    "bytes_sent": sent,
                    "mac": mac,
                    "broadcast": broadcast,
                    "port": port,
                }
            )
        except Exception as e:
            return {
                "ok": False,
                "executed": False,
                "blocked_reason": f"Failed to send Wake-on-LAN packet: {e}",
                "wake_plan": wake_plan,
                "plan": plan,
            }

    else:
        events.append(
            {
                "step": "wake_host",
                "executed": False,
                "reason": "Host SSH is already online.",
            }
        )

    host_ready = False
    host_wait_started = time.time()

    while time.time() - host_wait_started <= max(1, wait_host_seconds):
        host_online, probe = ssh_hostname()
        if host_online:
            host_ready = True
            events.append(
                {
                    "step": "wait_for_host_ssh",
                    "ready": True,
                    "waited_seconds": int(time.time() - host_wait_started),
                }
            )
            break

        time.sleep(5)

    if not host_ready:
        return {
            "ok": False,
            "executed": False,
            "blocked_reason": "Timed out waiting for Proxmox SSH.",
            "events": events,
            "plan": plan,
        }

    start_plan = await power_start_worker_plan(target_name=target_name)

    start_executed = False
    start_already_running = False
    start_result_payload = None

    if start_plan.get("eligible"):
        remote_command = start_plan.get("remote_command")

        cmd = [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=accept-new",
            ssh_target,
            remote_command,
        ]

        try:
            result = subprocess.run(
                cmd,
                text=True,
                capture_output=True,
                timeout=30,
                check=False,
            )

            start_executed = result.returncode == 0
            start_result_payload = {
                "step": "start_worker",
                "executed": start_executed,
                "remote_command": remote_command,
                "returncode": result.returncode,
                "stdout": result.stdout[-2000:],
                "stderr": result.stderr[-2000:],
                "start_plan": start_plan,
            }
            events.append(start_result_payload)

            if result.returncode != 0:
                return {
                    "ok": False,
                    "executed": False,
                    "blocked_reason": "Worker start command failed.",
                    "events": events,
                    "start_plan": start_plan,
                    "plan": plan,
                }

        except subprocess.TimeoutExpired:
            return {
                "ok": False,
                "executed": False,
                "blocked_reason": "Timed out while starting worker target.",
                "events": events,
                "start_plan": start_plan,
                "plan": plan,
            }
        except Exception as e:
            return {
                "ok": False,
                "executed": False,
                "blocked_reason": f"Failed to start worker target: {e}",
                "events": events,
                "start_plan": start_plan,
                "plan": plan,
            }

    else:
        blocked_reason = start_plan.get("blocked_reason") or "Worker start plan is not eligible."

        if "already running" in blocked_reason:
            start_already_running = True
            events.append(
                {
                    "step": "start_worker",
                    "executed": False,
                    "already_running": True,
                    "reason": blocked_reason,
                    "start_plan": start_plan,
                }
            )
        else:
            return {
                "ok": False,
                "executed": False,
                "blocked_reason": blocked_reason,
                "events": events,
                "start_plan": start_plan,
                "plan": plan,
            }

    pause_result = None

    if pause_after_start_minutes > 0:
        pause_result = await power_auto_pause(
            minutes=pause_after_start_minutes,
            reason=f"wake-and-start-{target_name}",
        )
        events.append(
            {
                "step": "pause_automation",
                "executed": True,
                "pause_result": pause_result,
            }
        )

    worker_ready = False
    health_error = None
    health_wait_started = time.time()

    while time.time() - health_wait_started <= max(1, wait_worker_seconds):
        try:
            with urllib.request.urlopen(health_url, timeout=5) as response:
                if 200 <= response.status < 300:
                    worker_ready = True
                    events.append(
                        {
                            "step": "wait_for_worker_health",
                            "ready": True,
                            "health_url": health_url,
                            "status": response.status,
                            "waited_seconds": int(time.time() - health_wait_started),
                        }
                    )
                    break
        except Exception as e:
            health_error = str(e)

        time.sleep(5)

    if not worker_ready:
        return {
            "ok": False,
            "executed": start_executed or start_already_running,
            "blocked_reason": "Timed out waiting for worker health URL.",
            "health_url": health_url,
            "last_health_error": health_error,
            "events": events,
            "pause_result": pause_result,
            "plan": plan,
        }

    registry_refresh_result = _power_mark_worker_available_from_controller_check(target_name)
    events.append(
        {
            "step": "refresh_worker_registry_from_health_check",
            "executed": bool(registry_refresh_result.get("updated")),
            "result": registry_refresh_result,
        }
    )

    registry_ready = False
    registry_error = None
    registry_worker = None
    registry_wait_started = time.time()

    while time.time() - registry_wait_started <= max(1, wait_registry_seconds):
        try:
            registry_state = _power_lookup_worker_registry_state(target_name)
            registry_worker = registry_state.get("worker")

            if registry_state.get("computed_health") == "available":
                registry_ready = True
                events.append(
                    {
                        "step": "wait_for_worker_registry",
                        "ready": True,
                        "source": "sqlite",
                        "waited_seconds": int(time.time() - registry_wait_started),
                        "worker": registry_worker,
                    }
                )
                break

            registry_error = registry_state.get("reason") or (
                f"Worker found but not available: {registry_state.get('computed_health')}"
            )

        except Exception as e:
            registry_error = str(e)

        time.sleep(5)

    if not registry_ready:
        return {
            "ok": False,
            "executed": start_executed or start_already_running,
            "blocked_reason": "Timed out waiting for worker registry availability.",
            "registry_source": "sqlite",
            "registry_url": registry_url,
            "last_registry_error": registry_error,
            "registry_worker": registry_worker,
            "events": events,
            "pause_result": pause_result,
            "plan": plan,
        }

    return {
        "ok": True,
        "executed": True,
        "time": datetime.now(timezone.utc).isoformat(),
        "target_name": target_name,
        "host_ready": host_ready,
        "worker_ready": worker_ready,
        "registry_ready": registry_ready,
        "registry_worker": registry_worker,
        "start_executed": start_executed,
        "start_already_running": start_already_running,
        "pause_result": pause_result,
        "events": events,
        "note": "Host is online, worker target is started/running, health URL is reachable, and registry shows worker available.",
    }


# ---------------------------------------------------------------------
# Direct worker registry lookup helper
# ---------------------------------------------------------------------
def _power_lookup_worker_registry_state(target_name: str):
    """
    Read worker state directly from SQLite.

    This avoids calling http://127.0.0.1:7070/workers/registry from inside
    a controller request, which can deadlock/time out with a single Uvicorn worker.
    """
    import sqlite3
    from datetime import datetime, timezone

    db_path = _power_auto_find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        row = conn.execute(
            """
            SELECT *
            FROM workers
            WHERE worker_id = ?
               OR name = ?
               OR target_name = ?
            LIMIT 1
            """,
            (target_name, target_name, target_name),
        ).fetchone()

        if not row:
            return {
                "ok": True,
                "found": False,
                "target_name": target_name,
                "computed_health": "missing",
                "worker": None,
                "reason": f"No worker matched {target_name}.",
            }

        worker = dict(row)

        now = datetime.now(timezone.utc)
        last_heartbeat_at = worker.get("last_heartbeat_at")
        heartbeat_age_seconds = None

        if last_heartbeat_at:
            try:
                heartbeat_dt = datetime.fromisoformat(str(last_heartbeat_at))
                if heartbeat_dt.tzinfo is None:
                    heartbeat_dt = heartbeat_dt.replace(tzinfo=timezone.utc)
                heartbeat_age_seconds = int((now - heartbeat_dt).total_seconds())
            except Exception:
                heartbeat_age_seconds = None

        status = str(worker.get("status") or "").lower()
        last_error = worker.get("last_error")
        current_jobs = int(worker.get("current_jobs") or 0)
        max_concurrent_jobs = int(worker.get("max_concurrent_jobs") or 1)
        queue_depth = int(worker.get("queue_depth") or 0)

        stale_after_seconds = 75

        if status in {"disabled", "offline"}:
            computed_health = status
        elif status == "unhealthy":
            computed_health = "unhealthy"
        elif heartbeat_age_seconds is None or heartbeat_age_seconds > stale_after_seconds:
            computed_health = "stale"
        elif last_error:
            computed_health = "unhealthy"
        elif current_jobs >= max_concurrent_jobs or queue_depth > 0:
            computed_health = "busy"
        else:
            computed_health = "available"

        worker["heartbeat_age_seconds"] = heartbeat_age_seconds
        worker["computed_health"] = computed_health

        return {
            "ok": True,
            "found": True,
            "target_name": target_name,
            "computed_health": computed_health,
            "worker": worker,
            "reason": None,
            "db_path": str(db_path),
        }

    finally:
        conn.close()


# ---------------------------------------------------------------------
# Power auto-start queue demand helper
# ---------------------------------------------------------------------
def _power_auto_queue_demand_state():
    """
    Read queued job demand directly from SQLite.

    This intentionally avoids self-HTTP calls from inside the controller.
    """
    import sqlite3

    db_path = _power_auto_find_db_path()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        tables = [
            row["name"]
            for row in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            ).fetchall()
        ]

        if "jobs" not in tables:
            return {
                "ok": True,
                "db_path": str(db_path),
                "has_jobs_table": False,
                "queued_job_count": 0,
                "active_job_count": 0,
                "status_counts": {},
                "has_start_demand": False,
                "reason": "No jobs table exists.",
            }

        status_counts = {
            row["status"]: int(row["count"])
            for row in conn.execute(
                """
                SELECT status, COUNT(*) AS count
                FROM jobs
                GROUP BY status
                """
            ).fetchall()
        }

        start_statuses = {
            "queued",
            "pending",
            "ready",
            "retry",
            "retrying",
        }

        active_statuses = start_statuses | {
            "running",
            "processing",
            "forwarding",
            "in_progress",
        }

        queued_job_count = sum(
            count
            for status, count in status_counts.items()
            if str(status).lower() in start_statuses
        )

        active_job_count = sum(
            count
            for status, count in status_counts.items()
            if str(status).lower() in active_statuses
        )

        return {
            "ok": True,
            "db_path": str(db_path),
            "has_jobs_table": True,
            "queued_job_count": queued_job_count,
            "active_job_count": active_job_count,
            "status_counts": status_counts,
            "has_start_demand": queued_job_count > 0,
            "reason": None,
        }

    finally:
        conn.close()


# ---------------------------------------------------------------------
# Direct worker registry refresh helper
# ---------------------------------------------------------------------
def _power_mark_worker_available_from_controller_check(target_name: str):
    """
    Mark a worker fresh/available after the controller has independently verified
    the backing service health URL.

    This avoids waiting for a heartbeat POST while the controller is already inside
    a long-running wake/start request.
    """
    import sqlite3
    from datetime import datetime, timezone

    db_path = _power_auto_find_db_path()
    now = datetime.now(timezone.utc).isoformat()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        row = conn.execute(
            """
            SELECT worker_id, name, target_name
            FROM workers
            WHERE worker_id = ?
               OR name = ?
               OR target_name = ?
            LIMIT 1
            """,
            (target_name, target_name, target_name),
        ).fetchone()

        if not row:
            return {
                "ok": False,
                "updated": False,
                "target_name": target_name,
                "reason": f"No worker matched {target_name}.",
                "db_path": str(db_path),
            }

        worker_id = row["worker_id"]

        conn.execute(
            """
            UPDATE workers
            SET
                status = 'online',
                current_jobs = 0,
                queue_depth = 0,
                last_error = NULL,
                last_heartbeat_at = ?,
                updated_at = ?
            WHERE worker_id = ?
            """,
            (now, now, worker_id),
        )

        conn.commit()

        refreshed = _power_lookup_worker_registry_state(target_name)

        return {
            "ok": True,
            "updated": True,
            "target_name": target_name,
            "worker_id": worker_id,
            "updated_at": now,
            "refreshed_state": refreshed,
            "db_path": str(db_path),
        }

    finally:
        conn.close()



# ---------------------------------------------------------------------
# Direct Ollama tick path
# ---------------------------------------------------------------------
def _parse_bool_env(name: str, default: bool = False) -> bool:
    value = os.getenv(name)

    if value is None:
        return default

    return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}


def _mark_edge_job_forwarded(job_id: int):
    now = datetime.now(timezone.utc).isoformat()

    with db() as conn:
        conn.execute(
            """
            UPDATE jobs
            SET
                status = 'forwarded',
                attempts = attempts + 1,
                last_error = NULL,
                updated_at = ?,
                forwarded_at = ?
            WHERE id = ?
            """,
            (now, now, job_id),
        )

    return {
        "job_id": job_id,
        "status": "forwarded",
        "updated_at": now,
        "forwarded_at": now,
    }


def _mark_edge_job_forward_error(job_id: int, error: str):
    now = datetime.now(timezone.utc).isoformat()

    with db() as conn:
        conn.execute(
            """
            UPDATE jobs
            SET
                attempts = attempts + 1,
                last_error = ?,
                updated_at = ?
            WHERE id = ?
            """,
            (error[:2000], now, job_id),
        )

    return {
        "job_id": job_id,
        "status": "queued",
        "updated_at": now,
        "last_error": error[:2000],
    }


async def _forward_ollama_chat_job_direct(job: dict[str, Any], ollama_base_url: str):
    model = job.get("requested_model") or os.getenv("EDGE_OLLAMA_DEFAULT_MODEL", "qwen2.5:0.5b")
    prompt = job.get("prompt") or ""

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": prompt,
            }
        ],
        "stream": False,
    }

    url = ollama_base_url.rstrip("/") + "/api/chat"

    try:
        async with httpx.AsyncClient(timeout=180.0) as client:
            response = await client.post(url, json=payload)

        raw_text = response.text

        if response.status_code < 200 or response.status_code >= 300:
            update = _mark_edge_job_forward_error(
                int(job["id"]),
                f"Ollama HTTP {response.status_code}: {raw_text[:1000]}",
            )

            return {
                "job_id": job["id"],
                "action": "ollama_direct_forward_failed",
                "ok": False,
                "url": url,
                "status_code": response.status_code,
                "error": raw_text[:1000],
                "job_update": update,
            }

        try:
            data = response.json()
        except Exception:
            data = {"raw": raw_text[:2000]}

        update = _mark_edge_job_forwarded(int(job["id"]))

        message = data.get("message") if isinstance(data, dict) else None
        content = message.get("content") if isinstance(message, dict) else None

        public_result_store = _public_store_job_result(
            job_id=int(job["id"]),
            model=model,
            response_text=content or raw_text,
            response_json=data,
            error=None,
        )

        return {
            "job_id": job["id"],
            "action": "ollama_direct_forwarded",
            "public_result_store": public_result_store,
            "ok": True,
            "url": url,
            "status_code": response.status_code,
            "model": model,
            "response_preview": (content or raw_text)[:1000],
            "job_update": update,
        }

    except Exception as e:
        update = _mark_edge_job_forward_error(int(job["id"]), str(e))

        return {
            "job_id": job["id"],
            "action": "ollama_direct_forward_exception",
            "ok": False,
            "url": url,
            "error": str(e),
            "job_update": update,
        }


@app.post("/tick/ollama-direct")
async def tick_ollama_direct(
    confirm: str = "",
    limit: int = 5,
    target_name: str = "llms_ollama",
    ollama_base_url: str = "",
):
    """
    Directly forward queued ollama_chat jobs to Ollama.

    This bypasses the legacy HOST_CHECK_URL / 3010 path and uses:
      - worker registry readiness
      - direct Ollama /api/chat

    Safety gates:
      1. EDGE_DIRECT_OLLAMA_FORWARD=1
      2. confirm=DIRECT_OLLAMA_FORWARD
      3. worker registry computed_health must be available
    """
    execute_enabled = _parse_bool_env("EDGE_DIRECT_OLLAMA_FORWARD", False)
    required_confirm = "DIRECT_OLLAMA_FORWARD"

    if limit < 1:
        limit = 1
    if limit > 25:
        limit = 25

    if not ollama_base_url:
        ollama_base_url = os.getenv("EDGE_OLLAMA_BASE_URL", "http://100.88.245.33:11434")

    with db() as conn:
        rows = conn.execute(
            """
            SELECT *
            FROM jobs
            WHERE status = 'queued'
            ORDER BY id ASC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()

    queued_jobs = [row_to_dict(row) for row in rows]
    ollama_jobs = [job for job in queued_jobs if job.get("job_type") == "ollama_chat"]

    worker_state = _power_lookup_worker_registry_state(target_name)

    actions: list[dict[str, Any]] = []

    if not queued_jobs:
        return {
            "ok": True,
            "executed": False,
            "action": "nothing_to_do",
            "reason": "No queued jobs.",
            "worker_state": worker_state,
            "ollama_base_url": ollama_base_url,
            "actions": actions,
        }

    if not ollama_jobs:
        return {
            "ok": True,
            "executed": False,
            "action": "nothing_forwarded",
            "reason": "Queued jobs exist, but none are ollama_chat jobs.",
            "queued_job_count": len(queued_jobs),
            "worker_state": worker_state,
            "ollama_base_url": ollama_base_url,
            "actions": actions,
        }

    if worker_state.get("computed_health") != "available":
        return {
            "ok": False,
            "executed": False,
            "action": "worker_not_available",
            "reason": "Worker registry does not show the target worker as available.",
            "worker_state": worker_state,
            "queued_job_count": len(queued_jobs),
            "ollama_job_count": len(ollama_jobs),
            "ollama_base_url": ollama_base_url,
            "actions": actions,
        }

    if confirm != required_confirm:
        return {
            "ok": False,
            "executed": False,
            "action": "blocked_missing_confirmation",
            "required_confirm": required_confirm,
            "example": "/tick/ollama-direct?confirm=DIRECT_OLLAMA_FORWARD",
            "worker_state": worker_state,
            "queued_job_count": len(queued_jobs),
            "ollama_job_count": len(ollama_jobs),
            "would_forward_job_ids": [job["id"] for job in ollama_jobs],
            "ollama_base_url": ollama_base_url,
            "actions": actions,
        }

    if not execute_enabled:
        return {
            "ok": False,
            "executed": False,
            "action": "blocked_execution_disabled",
            "reason": "EDGE_DIRECT_OLLAMA_FORWARD is not enabled.",
            "how_to_enable": "Set Environment=EDGE_DIRECT_OLLAMA_FORWARD=1, then restart the controller.",
            "worker_state": worker_state,
            "queued_job_count": len(queued_jobs),
            "ollama_job_count": len(ollama_jobs),
            "would_forward_job_ids": [job["id"] for job in ollama_jobs],
            "ollama_base_url": ollama_base_url,
            "actions": actions,
        }

    forwarded_count = 0

    for job in ollama_jobs:
        result = await _forward_ollama_chat_job_direct(job, ollama_base_url)
        actions.append(result)

        if result.get("ok"):
            forwarded_count += 1

    return {
        "ok": True,
        "executed": forwarded_count > 0,
        "action": "ollama_direct_tick_complete",
        "queued_job_count": len(queued_jobs),
        "ollama_job_count": len(ollama_jobs),
        "forwarded_count": forwarded_count,
        "worker_state": worker_state,
        "ollama_base_url": ollama_base_url,
        "actions": actions,
    }


# ---------------------------------------------------------------------
# Direct worker offline marker helper
# ---------------------------------------------------------------------
def _power_mark_worker_offline_after_stop(target_name: str, reason: str = "worker target stopped"):
    """
    Mark a worker offline after its mapped CT/VM has been stopped intentionally.

    This keeps the registry from showing an intentionally stopped worker as
    online/stale and prevents confusing remediation decisions.
    """
    import sqlite3
    from datetime import datetime, timezone

    db_path = _power_auto_find_db_path()
    now = datetime.now(timezone.utc).isoformat()

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    try:
        row = conn.execute(
            """
            SELECT worker_id, name, target_name
            FROM workers
            WHERE worker_id = ?
               OR name = ?
               OR target_name = ?
            LIMIT 1
            """,
            (target_name, target_name, target_name),
        ).fetchone()

        if not row:
            return {
                "ok": False,
                "updated": False,
                "target_name": target_name,
                "reason": f"No worker matched {target_name}.",
                "db_path": str(db_path),
            }

        worker_id = row["worker_id"]

        conn.execute(
            """
            UPDATE workers
            SET
                status = 'offline',
                current_jobs = 0,
                queue_depth = 0,
                last_error = ?,
                updated_at = ?
            WHERE worker_id = ?
            """,
            (reason, now, worker_id),
        )

        conn.commit()

        refreshed = _power_lookup_worker_registry_state(target_name)

        return {
            "ok": True,
            "updated": True,
            "target_name": target_name,
            "worker_id": worker_id,
            "updated_at": now,
            "refreshed_state": refreshed,
            "db_path": str(db_path),
        }

    finally:
        conn.close()



# ---------------------------------------------------------------------
# Public API layer for website/Cloudflare
# ---------------------------------------------------------------------
from fastapi import Request, HTTPException
import hmac


def _public_max_prompt_chars() -> int:
    try:
        return int(os.getenv("EDGE_PUBLIC_MAX_PROMPT_CHARS", "4000"))
    except Exception:
        return 4000


def _public_default_model() -> str:
    return os.getenv("EDGE_PUBLIC_DEFAULT_MODEL", os.getenv("EDGE_OLLAMA_DEFAULT_MODEL", "qwen2.5:0.5b"))


async def _require_public_api_key(request: Request):
    expected = os.getenv("EDGE_PUBLIC_API_KEY", "").strip()

    if not expected:
        raise HTTPException(
            status_code=503,
            detail="Public API is not configured. EDGE_PUBLIC_API_KEY is missing.",
        )

    supplied = request.headers.get("x-edge-api-key", "").strip()

    if not supplied or not hmac.compare_digest(supplied, expected):
        raise HTTPException(status_code=401, detail="Invalid or missing public API key.")

    return True


def _public_init_job_results_table():
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS job_results (
                job_id INTEGER PRIMARY KEY,
                model TEXT,
                response_text TEXT,
                response_json TEXT,
                error TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(job_id) REFERENCES jobs(id)
            )
            """
        )


def _public_store_job_result(job_id: int, model: str | None, response_text: str | None, response_json: object | None = None, error: str | None = None):
    _public_init_job_results_table()

    now = datetime.now(timezone.utc).isoformat()

    try:
        response_json_text = json.dumps(response_json, ensure_ascii=False) if response_json is not None else None
    except Exception:
        response_json_text = None

    with db() as conn:
        conn.execute(
            """
            INSERT INTO job_results (
                job_id,
                model,
                response_text,
                response_json,
                error,
                created_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(job_id) DO UPDATE SET
                model = excluded.model,
                response_text = excluded.response_text,
                response_json = excluded.response_json,
                error = excluded.error,
                updated_at = excluded.updated_at
            """,
            (
                int(job_id),
                model,
                response_text,
                response_json_text,
                error,
                now,
                now,
            ),
        )

    return {
        "job_id": int(job_id),
        "stored": True,
        "updated_at": now,
        "has_response_text": bool(response_text),
        "has_error": bool(error),
    }



def _public_get_job_with_result(job_id: int, user_id: int | None = None):
    _public_init_job_results_table()
    _auth_init_tables()

    with db() as conn:
        if user_id is None:
            job = conn.execute(
                """
                SELECT *
                FROM jobs
                WHERE id = ?
                LIMIT 1
                """,
                (int(job_id),),
            ).fetchone()
        else:
            job = conn.execute(
                """
                SELECT *
                FROM jobs
                WHERE id = ?
                  AND user_id = ?
                LIMIT 1
                """,
                (int(job_id), int(user_id)),
            ).fetchone()

        if not job:
            return None

        result = conn.execute(
            """
            SELECT *
            FROM job_results
            WHERE job_id = ?
            LIMIT 1
            """,
            (int(job_id),),
        ).fetchone()

    job_data = row_to_dict(job)

    result_data = None
    if result:
        result_data = row_to_dict(result)

        raw_json = result_data.get("response_json")
        if raw_json:
            try:
                result_data["response_json"] = json.loads(raw_json)
            except Exception:
                result_data["response_json"] = None

    return {
        "job": job_data,
        "result": result_data,
    }

def _public_create_ollama_job(prompt: str, requested_model: str | None = None, user_id: int | None = None):
    _auth_init_tables()

    now = datetime.now(timezone.utc).isoformat()
    model = requested_model or _public_default_model()

    with db() as conn:
        cur = conn.execute(
            """
            INSERT INTO jobs (
                user_id,
                job_type,
                prompt,
                requested_model,
                status,
                attempts,
                last_error,
                created_at,
                updated_at,
                forwarded_at
            )
            VALUES (?, ?, ?, ?, 'queued', 0, NULL, ?, ?, NULL)
            """,
            (
                user_id,
                "ollama_chat",
                prompt,
                model,
                now,
                now,
            ),
        )

        job_id = cur.lastrowid

        row = conn.execute(
            """
            SELECT *
            FROM jobs
            WHERE id = ?
            """,
            (job_id,),
        ).fetchone()

    return row_to_dict(row)

@app.post("/public/jobs")
async 
@app.post("/public/jobs")
async def public_create_job(request: Request):
    await _require_public_api_key(request)
    user_row = _auth_current_user_from_request(request)
    user_id = int(user_row["id"])

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    prompt = payload.get("prompt") if isinstance(payload, dict) else None
    requested_model = payload.get("requested_model") if isinstance(payload, dict) else None

    if not isinstance(prompt, str) or not prompt.strip():
        raise HTTPException(status_code=400, detail="prompt is required.")

    prompt = prompt.strip()
    max_chars = _public_max_prompt_chars()

    if len(prompt) > max_chars:
        raise HTTPException(
            status_code=400,
            detail=f"prompt is too long. Max characters: {max_chars}.",
        )

    if requested_model is not None and not isinstance(requested_model, str):
        raise HTTPException(status_code=400, detail="requested_model must be a string when provided.")

    requested_model = (requested_model or _public_default_model()).strip()

    job = _public_create_ollama_job(
        prompt=prompt,
        requested_model=requested_model,
        user_id=user_id,
    )

    return {
        "ok": True,
        "job_id": job["id"],
        "user_id": user_id,
        "status": job["status"],
        "requested_model": job["requested_model"],
        "poll_url": f"/public/jobs/{job['id']}",
        "message": "Job queued. Poll the job URL for status and result.",
    }

@app.get("/public/jobs/{job_id}")
async 
@app.get("/public/jobs/{job_id}")
async def public_get_job(job_id: int, request: Request):
    await _require_public_api_key(request)
    user_row = _auth_current_user_from_request(request)
    user_id = int(user_row["id"])

    data = _public_get_job_with_result(job_id, user_id=user_id)

    if not data:
        raise HTTPException(status_code=404, detail="Job not found.")

    job = data["job"]
    result = data["result"]

    return {
        "ok": True,
        "job_id": job["id"],
        "user_id": job.get("user_id"),
        "status": job["status"],
        "attempts": job.get("attempts"),
        "last_error": job.get("last_error"),
        "created_at": job.get("created_at"),
        "updated_at": job.get("updated_at"),
        "forwarded_at": job.get("forwarded_at"),
        "requested_model": job.get("requested_model"),
        "result": result,
    }



def _public_list_jobs_for_user(user_id: int, limit: int = 50):
    _auth_init_tables()
    _public_init_job_results_table()

    if limit < 1:
        limit = 1
    if limit > 100:
        limit = 100

    with db() as conn:
        rows = conn.execute(
            """
            SELECT
                j.id,
                j.user_id,
                j.job_type,
                j.prompt,
                j.requested_model,
                j.status,
                j.attempts,
                j.last_error,
                j.created_at,
                j.updated_at,
                j.forwarded_at,
                CASE WHEN r.job_id IS NULL THEN 0 ELSE 1 END AS has_result
            FROM jobs j
            LEFT JOIN job_results r ON r.job_id = j.id
            WHERE j.user_id = ?
            ORDER BY j.id DESC
            LIMIT ?
            """,
            (
                int(user_id),
                int(limit),
            ),
        ).fetchall()

    return [row_to_dict(row) for row in rows]


@app.get("/public/jobs")
async def public_list_jobs(request: Request, limit: int = 50):
    await _require_public_api_key(request)
    user_row = _auth_current_user_from_request(request)
    user_id = int(user_row["id"])

    jobs = _public_list_jobs_for_user(user_id=user_id, limit=limit)

    return {
        "ok": True,
        "user_id": user_id,
        "count": len(jobs),
        "jobs": jobs,
    }


@app.get("/public/status")
async def public_status(request: Request):
    await _require_public_api_key(request)

    with db() as conn:
        job_counts = {
            row["status"]: row["count"]
            for row in conn.execute(
                """
                SELECT status, COUNT(*) AS count
                FROM jobs
                GROUP BY status
                """
            ).fetchall()
        }

        latest_job = conn.execute(
            """
            SELECT id, job_type, status, created_at, updated_at, forwarded_at, last_error
            FROM jobs
            ORDER BY id DESC
            LIMIT 1
            """
        ).fetchone()

        workers = [
            worker_row_to_dict(row)
            for row in conn.execute(
                """
                SELECT *
                FROM workers
                ORDER BY worker_id
                """
            ).fetchall()
        ]

    worker_summary = {
        "total": len(workers),
        "available": sum(1 for w in workers if w.get("computed_health") == "available"),
        "busy": sum(1 for w in workers if w.get("computed_health") == "busy"),
        "offline": sum(1 for w in workers if w.get("computed_health") == "offline"),
        "stale": sum(1 for w in workers if w.get("computed_health") == "stale"),
        "unhealthy": sum(1 for w in workers if w.get("computed_health") == "unhealthy"),
        "disabled": sum(1 for w in workers if w.get("computed_health") == "disabled"),
    }

    return {
        "ok": True,
        "queue": {
            "status_counts": job_counts,
            "queued": job_counts.get("queued", 0),
            "forwarded": job_counts.get("forwarded", 0),
        },
        "workers": worker_summary,
        "latest_job": row_to_dict(latest_job) if latest_job else None,
    }


# ---------------------------------------------------------------------
# Public user auth foundation
# ---------------------------------------------------------------------
import base64 as _auth_base64
import hashlib as _auth_hashlib
import secrets as _auth_secrets
from datetime import timedelta as _auth_timedelta


def _auth_now_iso():
    return datetime.now(timezone.utc).isoformat()


def _auth_init_tables():
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS app_users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL UNIQUE,
                display_name TEXT,
                password_hash TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                last_login_at TEXT
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                revoked_at TEXT,
                last_seen_at TEXT,
                user_agent TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        # Future-proof jobs so later every AI job can belong to a user.
        cols = {
            row["name"]
            for row in conn.execute("PRAGMA table_info(jobs)").fetchall()
        }
        if "user_id" not in cols:
            conn.execute("ALTER TABLE jobs ADD COLUMN user_id INTEGER")


def _auth_normalize_email(email: str) -> str:
    return str(email or "").strip().lower()


def _auth_hash_password(password: str) -> str:
    iterations = 310000
    salt = _auth_secrets.token_bytes(16)
    digest = _auth_hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        iterations,
    )

    salt_b64 = _auth_base64.urlsafe_b64encode(salt).decode("ascii")
    digest_b64 = _auth_base64.urlsafe_b64encode(digest).decode("ascii")

    return f"pbkdf2_sha256${iterations}${salt_b64}${digest_b64}"


def _auth_verify_password(password: str, stored: str) -> bool:
    try:
        algo, iterations_text, salt_b64, digest_b64 = stored.split("$", 3)
        if algo != "pbkdf2_sha256":
            return False

        iterations = int(iterations_text)
        salt = _auth_base64.urlsafe_b64decode(salt_b64.encode("ascii"))
        expected = _auth_base64.urlsafe_b64decode(digest_b64.encode("ascii"))

        actual = _auth_hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt,
            iterations,
        )

        return hmac.compare_digest(actual, expected)
    except Exception:
        return False


def _auth_hash_token(token: str) -> str:
    return _auth_hashlib.sha256(token.encode("utf-8")).hexdigest()


def _auth_public_user(row):
    data = row_to_dict(row)
    return {
        "id": data.get("id"),
        "email": data.get("email"),
        "display_name": data.get("display_name"),
        "status": data.get("status"),
        "created_at": data.get("created_at"),
        "updated_at": data.get("updated_at"),
        "last_login_at": data.get("last_login_at"),
    }


def _auth_create_session(user_id: int, request: Request):
    _auth_init_tables()

    token = _auth_secrets.token_urlsafe(48)
    token_hash = _auth_hash_token(token)

    now = datetime.now(timezone.utc)
    expires = now + _auth_timedelta(days=int(os.getenv("EDGE_PUBLIC_SESSION_DAYS", "30")))

    user_agent = request.headers.get("user-agent")

    with db() as conn:
        conn.execute(
            """
            INSERT INTO user_sessions (
                user_id,
                token_hash,
                created_at,
                expires_at,
                revoked_at,
                last_seen_at,
                user_agent
            )
            VALUES (?, ?, ?, ?, NULL, ?, ?)
            """,
            (
                int(user_id),
                token_hash,
                now.isoformat(),
                expires.isoformat(),
                now.isoformat(),
                user_agent,
            ),
        )

    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_at": expires.isoformat(),
    }


def _auth_get_bearer_token(request: Request) -> str | None:
    header = request.headers.get("authorization", "")
    if not header.lower().startswith("bearer "):
        return None
    return header.split(" ", 1)[1].strip()


def _auth_current_user_from_request(request: Request):
    _auth_init_tables()

    token = _auth_get_bearer_token(request)
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token.")

    token_hash = _auth_hash_token(token)
    now = datetime.now(timezone.utc)

    with db() as conn:
        row = conn.execute(
            """
            SELECT
                u.*
            FROM user_sessions s
            JOIN app_users u ON u.id = s.user_id
            WHERE s.token_hash = ?
              AND s.revoked_at IS NULL
              AND s.expires_at > ?
              AND u.status = 'active'
            LIMIT 1
            """,
            (
                token_hash,
                now.isoformat(),
            ),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=401, detail="Invalid or expired session.")

        conn.execute(
            """
            UPDATE user_sessions
            SET last_seen_at = ?
            WHERE token_hash = ?
            """,
            (
                now.isoformat(),
                token_hash,
            ),
        )

    return row


@app.post("/public/auth/register")
async def public_auth_register(request: Request):
    await _require_public_api_key(request)
    _auth_init_tables()

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    email = _auth_normalize_email(payload.get("email") if isinstance(payload, dict) else "")
    password = payload.get("password") if isinstance(payload, dict) else None
    display_name = payload.get("display_name") if isinstance(payload, dict) else None

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required.")

    if not isinstance(password, str) or len(password) < 10:
        raise HTTPException(status_code=400, detail="Password must be at least 10 characters.")

    if display_name is not None:
        display_name = str(display_name).strip()[:120] or None

    now = _auth_now_iso()
    password_hash = _auth_hash_password(password)

    try:
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO app_users (
                    email,
                    display_name,
                    password_hash,
                    status,
                    created_at,
                    updated_at,
                    last_login_at
                )
                VALUES (?, ?, ?, 'active', ?, ?, ?)
                """,
                (
                    email,
                    display_name,
                    password_hash,
                    now,
                    now,
                    now,
                ),
            )

            user_id = cur.lastrowid

            row = conn.execute(
                """
                SELECT *
                FROM app_users
                WHERE id = ?
                """,
                (user_id,),
            ).fetchone()
    except Exception as e:
        if "UNIQUE" in str(e).upper():
            raise HTTPException(status_code=409, detail="An account with that email already exists.")
        raise

    session = _auth_create_session(user_id=int(user_id), request=request)

    return {
        "ok": True,
        "user": _auth_public_user(row),
        "session": session,
    }


@app.post("/public/auth/login")
async def public_auth_login(request: Request):
    await _require_public_api_key(request)
    _auth_init_tables()

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    email = _auth_normalize_email(payload.get("email") if isinstance(payload, dict) else "")
    password = payload.get("password") if isinstance(payload, dict) else None

    if not email or not isinstance(password, str):
        raise HTTPException(status_code=400, detail="Email and password are required.")

    with db() as conn:
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE email = ?
              AND status = 'active'
            LIMIT 1
            """,
            (email,),
        ).fetchone()

    if not row or not _auth_verify_password(password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    now = _auth_now_iso()

    with db() as conn:
        conn.execute(
            """
            UPDATE app_users
            SET last_login_at = ?, updated_at = ?
            WHERE id = ?
            """,
            (
                now,
                now,
                row["id"],
            ),
        )

        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (row["id"],),
        ).fetchone()

    session = _auth_create_session(user_id=int(row["id"]), request=request)

    return {
        "ok": True,
        "user": _auth_public_user(row),
        "session": session,
    }


@app.get("/public/me")
async def public_me(request: Request):
    await _require_public_api_key(request)

    row = _auth_current_user_from_request(request)

    return {
        "ok": True,
        "user": _auth_public_user(row),
    }


@app.post("/public/auth/logout")
async def public_auth_logout(request: Request):
    await _require_public_api_key(request)

    token = _auth_get_bearer_token(request)
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token.")

    token_hash = _auth_hash_token(token)
    now = _auth_now_iso()

    with db() as conn:
        conn.execute(
            """
            UPDATE user_sessions
            SET revoked_at = ?
            WHERE token_hash = ?
              AND revoked_at IS NULL
            """,
            (
                now,
                token_hash,
            ),
        )

    return {
        "ok": True,
        "message": "Logged out.",
    }
