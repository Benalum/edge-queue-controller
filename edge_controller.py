import os
import json
import sqlite3
from edge_router_schema import init_router_foundation_schema, router_foundation_table_names
import subprocess
import asyncio
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
        # Stage 6AB: Universal Intent Router persistent schema foundation.
        init_router_foundation_schema(conn)

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
    requested_model: str | None = Field(default="gemma4:e4b")


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

        # Stage 7W-1: legacy /tick can auto-ready the worker before
        # direct Ollama forwarding. Keep the post-start pause bounded and
        # locally defined so the scheduler timer cannot crash with NameError.
        try:
            web_presence_start_pause_minutes = int(os.getenv("WEB_POWER_START_PAUSE_MINUTES", "10"))
        except (TypeError, ValueError):
            web_presence_start_pause_minutes = 10
        web_presence_start_pause_minutes = max(1, min(120, web_presence_start_pause_minutes))

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
                    pause_after_start_minutes=web_presence_start_pause_minutes,
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
                action = "would_stop_worker_target"
                reason = "Queue has been empty long enough and target is allowlisted; guarded stop execution is enabled."

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
        result = await asyncio.to_thread(
            subprocess.run,
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

    # STAGE_5O2_POWER_AUTO_TICK_NONBLOCKING_DEFAULT_V1
    # /power/auto/tick previously evaluated several Proxmox/SSH-backed plans
    # before deciding whether any action was enabled. When pveso/Proxmox was
    # unreachable, this could block the single controller worker and freeze
    # /health plus browser auth/API routes. Keep the route non-blocking unless
    # an operator explicitly opts into the full legacy evaluator.
    full_power_auto_tick = parse_bool(os.getenv("EDGE_POWER_AUTO_TICK_FULL"), False)

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

    if not full_power_auto_tick:
        return {
            "ok": True,
            "time": datetime.now(timezone.utc).isoformat(),
            "quarantined": True,
            "source": "stage_5o2_power_auto_tick_nonblocking_default",
            "automation": {
                "auto_stop_workers": auto_stop_workers,
                "auto_shutdown_host": auto_shutdown_host,
                "auto_start_workers": auto_start_workers,
                "full_power_auto_tick": False,
                "paused": False,
            },
            "actions": [
                {
                    "area": "automation",
                    "action": "power_auto_tick_quarantined_nonblocking",
                    "executed": False,
                    "reason": "EDGE_POWER_AUTO_TICK_FULL is not enabled, so Proxmox/SSH-backed planning is skipped.",
                }
            ],
            "note": "Set EDGE_POWER_AUTO_TICK_FULL=1 only after the Proxmox/SSH planning path is made safe and non-blocking.",
        }

    execute_stops_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_STOPS"), False)
    execute_host_shutdown_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_HOST_SHUTDOWN"), False)
    execute_wake_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_WAKE"), False)
    execute_wake_and_start_enabled = parse_bool(os.getenv("EDGE_POWER_EXECUTE_WAKE_AND_START"), False)

    queue_demand = _power_auto_queue_demand_state()
    worker_registry_state = _power_lookup_worker_registry_state("llms_ollama")

    try:
        worker_start_plan = await power_start_worker_plan(target_name="llms_ollama")
    except HTTPException as e:
        worker_start_plan = {
            "ok": False,
            "eligible": False,
            "inventory_error": True,
            "blocked_reason": "Inventory unavailable; worker start plan could not be safely evaluated.",
            "error": e.detail,
        }

    try:
        stop_plan = await power_stop_plan()
    except HTTPException as e:
        stop_plan = {
            "ok": False,
            "inventory_error": True,
            "error": e.detail,
            "container_stop_plans": [],
            "note": "power_auto_tick continued after power_stop_plan failed.",
        }

    try:
        host_plan = await power_host_shutdown_plan()
    except HTTPException as e:
        host_plan = {
            "ok": False,
            "inventory_error": True,
            "error": e.detail,
            "eligible": False,
            "blocked_reasons": [
                "Inventory unavailable; host shutdown plan could not be safely evaluated."
            ],
            "note": "power_auto_tick continued after power_host_shutdown_plan failed.",
        }

    try:
        wake_plan = await power_wake_plan()
    except HTTPException as e:
        wake_plan = {
            "ok": False,
            "inventory_error": True,
            "error": e.detail,
            "wake": {
                "eligible": False,
            },
            "note": "power_auto_tick continued after power_wake_plan failed.",
        }

    # Guard old auto-stop / auto-shutdown path with the newer web presence policy.
    # If someone is actively using the site, do not stop workers or shut down pveso.
    try:
        web_power_policy = _web_presence_power_decision()
    except Exception as e:
        web_power_policy = {
            "ok": False,
            "error": str(e),
            "desired_state": {},
        }

    if not isinstance(web_power_policy, dict):
        web_power_policy = {
            "ok": False,
            "error": "Web power policy returned non-dict result.",
            "desired_state": {},
        }

    web_desired_state = web_power_policy.get("desired_state") or {}
    web_host_required = bool(web_desired_state.get("host_required"))
    web_container_required = bool(web_desired_state.get("container_required"))

    # WEB_PRESENCE_CONTAINER_START_DEMAND_V1
    # Logged-in/admin web presence means CT101 is required, not just PVESO.
    # Reuse the existing worker start path by treating container_required
    # as start demand even when there are no queued jobs.
    if web_container_required and not queue_demand.get("has_start_demand"):
        queue_demand["has_start_demand"] = True
        queue_demand["reason"] = "web_presence_container_required"
        queue_demand["source"] = "web_presence_power_policy"
        queue_demand["web_presence_container_required"] = True

        # Queue auto-start can remain off for normal jobs, but authenticated
        # web presence must be allowed to start the core CT101 app container.
        auto_start_workers = True

    # WEB_PRESENCE_NO_START_PAUSE_V1
    # Web presence needs CT101 available immediately. Do not create a temporary
    # automation pause after web-presence start/recovery, because that pause can
    # block a follow-up start if CT101 is manually stopped or crashes.
    web_presence_start_pause_minutes = (
        0 if queue_demand.get("web_presence_container_required") else 10
    )

    # Extra safety: after a wake request, keep the host alive during the boot grace window.
    # This prevents the old /power/auto/tick path from shutting pveso down before services
    # have had time to start or before the user can actually use the site.
    try:
        booting_marker = _system_read_booting_marker()
    except Exception as e:
        booting_marker = {
            "active": False,
            "error": str(e),
        }

    boot_grace_active = bool(
        isinstance(booting_marker, dict)
        and booting_marker.get("active")
    )

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

        # STAGE_5P15_HOST_FIRST_WAKE_ON_INVENTORY_UNAVAILABLE_V1
        # If logged-in web presence requires the host/container and Proxmox is offline,
        # CT inventory cannot be evaluated yet. In that case, send host WOL first,
        # mark the host as booting, and let a later tick start CT101 after inventory returns.
        if (
            worker_start_plan.get("inventory_error")
            and (web_host_required or web_container_required)
            and bool((wake_plan.get("wake") or {}).get("eligible"))
        ):
            if boot_grace_active:
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "defer_worker_start_during_host_boot_grace",
                        "executed": False,
                        "reason": "Host boot grace is active; worker start inventory will be rechecked after the host returns.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                        "wake_plan": wake_plan,
                        "booting_marker": booting_marker,
                    }
                )
            elif not execute_wake_enabled:
                actions.append(
                    {
                        "area": "worker_start",
                        "action": "blocked_host_first_wake_execution_disabled",
                        "executed": False,
                        "reason": "Host/container is required and inventory is unavailable, but EDGE_POWER_EXECUTE_WAKE=0.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                        "wake_plan": wake_plan,
                    }
                )
            else:
                wake_result = system_boot_pveso(
                    {
                        "confirm": "BOOT_PVESO",
                        "source": "power_auto_tick_host_first_wake",
                        "decision": {
                            "reason": "web_presence_requires_host_but_inventory_unavailable",
                            "web_host_required": web_host_required,
                            "web_container_required": web_container_required,
                            "queue_demand": queue_demand,
                            "worker_start_plan": worker_start_plan,
                            "wake_plan": wake_plan,
                        },
                    }
                )

                try:
                    booting_marker = _system_read_booting_marker()
                except Exception as e:
                    booting_marker = {
                        "active": False,
                        "error": str(e),
                    }

                boot_grace_active = bool(
                    isinstance(booting_marker, dict)
                    and booting_marker.get("active")
                )

                actions.append(
                    {
                        "area": "worker_start",
                        "action": "auto_wake_host_first_due_to_inventory_unavailable",
                        "executed": bool(wake_result.get("boot_sent")),
                        "reason": "Host/container is required but Proxmox inventory is unavailable, so host Wake-on-LAN was attempted before CT start planning.",
                        "queue_demand": queue_demand,
                        "worker_registry_state": worker_registry_state,
                        "worker_start_plan": worker_start_plan,
                        "wake_plan": wake_plan,
                        "booting_marker": booting_marker,
                        "result": wake_result,
                    }
                )

        elif worker_start_plan.get("eligible"):
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
                    pause_after_start_minutes=web_presence_start_pause_minutes,
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
                    pause_after_start_minutes=web_presence_start_pause_minutes,
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
    elif web_host_required or web_container_required or boot_grace_active:
        actions.append(
            {
                "area": "worker_stop",
                "action": "skip_worker_stop_due_to_web_presence_or_boot_grace",
                "executed": False,
                "reason": "Active web presence or boot grace requires the host, so worker stop is skipped.",
                "web_presence_policy": web_power_policy,
                "booting_marker": booting_marker,
                "plans": container_plans,
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
    if web_host_required or boot_grace_active:
        actions.append(
            {
                "area": "host_shutdown",
                "action": "skip_host_shutdown_due_to_web_presence_or_boot_grace",
                "executed": False,
                "reason": "Active web presence or boot grace requires the host, so host shutdown is skipped.",
                "web_presence_policy": web_power_policy,
                "booting_marker": booting_marker,
                "would_run": host_plan.get("would_run"),
            }
        )
    elif host_plan.get("eligible"):
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
    model = job.get("requested_model") or os.getenv("EDGE_OLLAMA_DEFAULT_MODEL", "gemma4:e4b")
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
    return os.getenv("EDGE_PUBLIC_DEFAULT_MODEL", os.getenv("EDGE_OLLAMA_DEFAULT_MODEL", "gemma4:e4b"))


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
                int(user_id) if user_id is not None else None,
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
from edge_modules.email_verification import (
    email_verification_expires_at as _email_verification_expires_at,
    email_verification_hash as _email_verification_hash,
    email_verification_token as _email_verification_token,
    email_verification_url as _email_verification_url,
    password_reset_expires_at as _password_reset_expires_at,
    password_reset_url as _password_reset_url,
    send_email_verification as _send_email_verification,
    send_password_reset_email as _send_password_reset_email,
)


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

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS pending_email_signups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL UNIQUE,
                display_name TEXT,
                password_hash TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                consumed_at TEXT,
                sent_count INTEGER NOT NULL DEFAULT 0,
                last_sent_at TEXT
            )
            """
        )


        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS password_reset_tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                email TEXT NOT NULL,
                token_hash TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                consumed_at TEXT,
                sent_count INTEGER NOT NULL DEFAULT 1,
                last_sent_at TEXT,
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




def _auth_pending_signup_response(email: str, delivery):
    response = {
        "ok": True,
        "verification_required": True,
        "email": email,
        "message": "Check your email to finish creating your account.",
        "email_delivery": delivery.get("delivery") if isinstance(delivery, dict) else None,
    }

    if isinstance(delivery, dict) and delivery.get("debug_verify_url"):
        response["debug_verify_url"] = delivery["debug_verify_url"]

    return response


def _auth_create_or_update_pending_signup(email: str, password_hash: str, display_name=None):
    _auth_init_tables()

    now = _auth_now_iso()
    token = _email_verification_token()
    token_hash = _email_verification_hash(token)
    expires_at = _email_verification_expires_at(now)

    with db() as conn:
        existing_user = conn.execute(
            """
            SELECT id
            FROM app_users
            WHERE email = ?
            LIMIT 1
            """,
            (email,),
        ).fetchone()

        if existing_user:
            # Do not reveal whether the account exists. Return a no-op verification response.
            return None, None, {
                "sent": False,
                "delivery": "existing_account_noop",
                "debug_verify_url": None,
            }

        conn.execute(
            """
            INSERT INTO pending_email_signups (
                email,
                display_name,
                password_hash,
                token_hash,
                created_at,
                updated_at,
                expires_at,
                consumed_at,
                sent_count,
                last_sent_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, NULL, 1, ?)
            ON CONFLICT(email) DO UPDATE SET
                display_name = excluded.display_name,
                password_hash = excluded.password_hash,
                token_hash = excluded.token_hash,
                updated_at = excluded.updated_at,
                expires_at = excluded.expires_at,
                consumed_at = NULL,
                sent_count = pending_email_signups.sent_count + 1,
                last_sent_at = excluded.last_sent_at
            """,
            (
                email,
                display_name,
                password_hash,
                token_hash,
                now,
                now,
                expires_at,
                now,
            ),
        )

    verify_url = _email_verification_url(token)
    delivery = _send_email_verification(email, verify_url)
    return token, verify_url, delivery


def _auth_complete_email_verification(token: str):
    _auth_init_tables()

    token = str(token or "").strip()
    if not token:
        raise HTTPException(status_code=400, detail="Verification token is required.")

    token_hash = _email_verification_hash(token)
    now = _auth_now_iso()

    with db() as conn:
        conn.execute("BEGIN IMMEDIATE")

        pending = conn.execute(
            """
            SELECT *
            FROM pending_email_signups
            WHERE token_hash = ?
              AND consumed_at IS NULL
            LIMIT 1
            """,
            (token_hash,),
        ).fetchone()

        if not pending:
            raise HTTPException(status_code=400, detail="Invalid or already used verification link.")

        if str(pending["expires_at"]) <= now:
            raise HTTPException(status_code=400, detail="Verification link expired. Please register again.")

        existing_user = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE email = ?
            LIMIT 1
            """,
            (pending["email"],),
        ).fetchone()

        if existing_user:
            conn.execute(
                """
                UPDATE pending_email_signups
                SET consumed_at = ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (now, now, pending["id"]),
            )
            conn.commit()
            return existing_user, False

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
            VALUES (?, ?, ?, 'active', ?, ?, NULL)
            """,
            (
                pending["email"],
                pending["display_name"],
                pending["password_hash"],
                now,
                now,
            ),
        )

        user_id = cur.lastrowid

        conn.execute(
            """
            UPDATE pending_email_signups
            SET consumed_at = ?,
                updated_at = ?
            WHERE id = ?
            """,
            (now, now, pending["id"]),
        )

        user = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()

        conn.commit()

    return user, True


def _auth_pending_signup_exists(email: str) -> bool:
    _auth_init_tables()
    now = _auth_now_iso()

    with db() as conn:
        row = conn.execute(
            """
            SELECT id
            FROM pending_email_signups
            WHERE email = ?
              AND consumed_at IS NULL
              AND expires_at > ?
            LIMIT 1
            """,
            (email, now),
        ).fetchone()

    return bool(row)






def _auth_password_reset_response(email: str, delivery=None):
    response = {
        "ok": True,
        "message": "If that email exists, a password reset link has been sent.",
        "email": email,
    }

    if isinstance(delivery, dict) and delivery.get("debug_reset_url"):
        response["debug_reset_url"] = delivery["debug_reset_url"]

    if isinstance(delivery, dict):
        response["email_delivery"] = delivery.get("delivery")

    return response


def _auth_create_password_reset(email: str):
    _auth_init_tables()

    email = _auth_normalize_email(email)
    now = _auth_now_iso()

    with db() as conn:
        user = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE email = ?
              AND status = 'active'
            LIMIT 1
            """,
            (email,),
        ).fetchone()

        if not user:
            return None, None, {
                "sent": False,
                "delivery": "no_account_noop",
                "debug_reset_url": None,
            }

        token = _email_verification_token()
        token_hash = _email_verification_hash(token)
        expires_at = _password_reset_expires_at(now)

        conn.execute(
            """
            UPDATE password_reset_tokens
            SET consumed_at = ?
            WHERE user_id = ?
              AND consumed_at IS NULL
            """,
            (now, int(user["id"])),
        )

        conn.execute(
            """
            INSERT INTO password_reset_tokens (
                user_id,
                email,
                token_hash,
                created_at,
                expires_at,
                consumed_at,
                sent_count,
                last_sent_at
            )
            VALUES (?, ?, ?, ?, ?, NULL, 1, ?)
            """,
            (
                int(user["id"]),
                email,
                token_hash,
                now,
                expires_at,
                now,
            ),
        )

    reset_url = _password_reset_url(token)
    delivery = _send_password_reset_email(email, reset_url)
    return token, reset_url, delivery


def _auth_reset_password_with_token(token: str, new_password: str):
    _auth_init_tables()

    token = str(token or "").strip()
    new_password = str(new_password or "")

    if not token:
        raise HTTPException(status_code=400, detail="Reset token is required.")

    if len(new_password) < 8:
        raise HTTPException(status_code=400, detail="New password must be at least 8 characters.")

    token_hash = _email_verification_hash(token)
    password_hash = _auth_hash_password(new_password)
    now = _auth_now_iso()

    with db() as conn:
        conn.execute("BEGIN IMMEDIATE")

        row = conn.execute(
            """
            SELECT *
            FROM password_reset_tokens
            WHERE token_hash = ?
              AND consumed_at IS NULL
            LIMIT 1
            """,
            (token_hash,),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=400, detail="Invalid or already used reset link.")

        if str(row["expires_at"]) <= now:
            raise HTTPException(status_code=400, detail="Reset link expired. Please request a new password reset.")

        user = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
              AND status = 'active'
            LIMIT 1
            """,
            (int(row["user_id"]),),
        ).fetchone()

        if not user:
            raise HTTPException(status_code=400, detail="Invalid reset link.")

        conn.execute(
            """
            UPDATE app_users
            SET password_hash = ?,
                updated_at = ?
            WHERE id = ?
            """,
            (
                password_hash,
                now,
                int(row["user_id"]),
            ),
        )

        conn.execute(
            """
            UPDATE password_reset_tokens
            SET consumed_at = ?
            WHERE id = ?
            """,
            (
                now,
                int(row["id"]),
            ),
        )

        conn.execute(
            """
            UPDATE user_sessions
            SET revoked_at = ?
            WHERE user_id = ?
              AND revoked_at IS NULL
            """,
            (
                now,
                int(row["user_id"]),
            ),
        )

        updated = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (int(row["user_id"]),),
        ).fetchone()

        conn.commit()

    return updated

def _auth_change_password_for_user(user_id: int, current_password: str, new_password: str, keep_token: str | None = None):
    _auth_init_tables()

    current_password = str(current_password or "")
    new_password = str(new_password or "")

    if not current_password:
        raise HTTPException(status_code=400, detail="Current password is required.")

    if len(new_password) < 8:
        raise HTTPException(status_code=400, detail="New password must be at least 8 characters.")

    if current_password == new_password:
        raise HTTPException(status_code=400, detail="New password must be different from the current password.")

    keep_token_hash = _auth_hash_token(keep_token) if keep_token else None
    new_password_hash = _auth_hash_password(new_password)
    now = _auth_now_iso()

    with db() as conn:
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
              AND status = 'active'
            LIMIT 1
            """,
            (int(user_id),),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=401, detail="Invalid or expired session.")

        if not _auth_verify_password(current_password, row["password_hash"]):
            raise HTTPException(status_code=401, detail="Current password is incorrect.")

        conn.execute(
            """
            UPDATE app_users
            SET password_hash = ?,
                updated_at = ?
            WHERE id = ?
            """,
            (
                new_password_hash,
                now,
                int(user_id),
            ),
        )

        if keep_token_hash:
            conn.execute(
                """
                UPDATE user_sessions
                SET revoked_at = ?
                WHERE user_id = ?
                  AND revoked_at IS NULL
                  AND token_hash != ?
                """,
                (
                    now,
                    int(user_id),
                    keep_token_hash,
                ),
            )
        else:
            conn.execute(
                """
                UPDATE user_sessions
                SET revoked_at = ?
                WHERE user_id = ?
                  AND revoked_at IS NULL
                """,
                (
                    now,
                    int(user_id),
                ),
            )

        updated = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (int(user_id),),
        ).fetchone()

    return updated

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
    _auth_init_tables()

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    email = _auth_normalize_email(payload.get("email") or "")
    password = str(payload.get("password") or "")
    display_name = str(payload.get("display_name") or "").strip() or None

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required.")

    if len(password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters.")

    password_hash = _auth_hash_password(password)
    _, _, delivery = _auth_create_or_update_pending_signup(email, password_hash, display_name)

    return _auth_pending_signup_response(email, delivery)







@app.get("/public/auth/verify-email")
async def public_auth_verify_email(token: str, request: Request):
    user, created = _auth_complete_email_verification(token)
    session = _auth_create_session(int(user["id"]), request)

    return {
        "ok": True,
        "verified": True,
        "created": bool(created),
        "user": _auth_public_user(user),
        "session": session,
        **session,
    }


@app.post("/public/auth/resend-verification")
async def public_auth_resend_verification(request: Request):
    _auth_init_tables()

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    email = _auth_normalize_email(payload.get("email") or "")

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required.")

    with db() as conn:
        pending = conn.execute(
            """
            SELECT *
            FROM pending_email_signups
            WHERE email = ?
              AND consumed_at IS NULL
            LIMIT 1
            """,
            (email,),
        ).fetchone()

    if not pending:
        return _auth_pending_signup_response(
            email,
            {
                "sent": False,
                "delivery": "no_pending_signup_noop",
                "debug_verify_url": None,
            },
        )

    _, _, delivery = _auth_create_or_update_pending_signup(
        email,
        pending["password_hash"],
        pending["display_name"],
    )

    return _auth_pending_signup_response(email, delivery)





@app.get("/api/auth/verify-email")
async def api_auth_verify_email(token: str, request: Request):
    return await public_auth_verify_email(token, request)


@app.post("/api/auth/resend-verification")
async def api_auth_resend_verification(request: Request):
    return await public_auth_resend_verification(request)


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

    if not row:
        if _auth_pending_signup_exists(email):
            raise HTTPException(status_code=403, detail="Email verification required. Check your email to finish creating your account.")
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    if not _auth_verify_password(password, row["password_hash"]):
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








@app.post("/public/auth/forgot-password")
async def public_auth_forgot_password(request: Request):
    await _require_public_api_key(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    email = _auth_normalize_email(payload.get("email") or "")

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required.")

    _, _, delivery = _auth_create_password_reset(email)

    return _auth_password_reset_response(email, delivery)


@app.post("/public/auth/reset-password")
async def public_auth_reset_password(request: Request):
    await _require_public_api_key(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    token = payload.get("token") or ""
    new_password = payload.get("new_password") or ""

    user = _auth_reset_password_with_token(token, new_password)

    return {
        "ok": True,
        "message": "Password reset. You can now log in.",
        "user": _auth_public_user(user),
    }


@app.post("/system/session/forgot-password")
async def system_session_forgot_password(request: Request):
    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    email = _auth_normalize_email(payload.get("email") or "")

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required.")

    _, _, delivery = _auth_create_password_reset(email)

    return _auth_password_reset_response(email, delivery)


@app.post("/system/session/reset-password")
async def system_session_reset_password(request: Request):
    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    token = payload.get("token") or ""
    new_password = payload.get("new_password") or ""

    user = _auth_reset_password_with_token(token, new_password)

    return {
        "ok": True,
        "message": "Password reset. You can now log in.",
        "user": _auth_public_user(user),
    }


@app.post("/public/auth/change-password")
async def public_auth_change_password(request: Request):
    await _require_public_api_key(request)

    user = _auth_current_user_from_request(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    current_password = payload.get("current_password") or ""
    new_password = payload.get("new_password") or ""
    keep_token = _auth_get_bearer_token(request)

    updated = _auth_change_password_for_user(
        int(user["id"]),
        current_password,
        new_password,
        keep_token=keep_token,
    )

    return {
        "ok": True,
        "message": "Password changed.",
        "user": _auth_public_user(updated),
    }


@app.post("/system/session/change-password")
async def system_session_change_password(request: Request):
    user = _auth_current_user_from_request(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    current_password = payload.get("current_password") or ""
    new_password = payload.get("new_password") or ""
    keep_token = _auth_get_bearer_token(request)

    updated = _auth_change_password_for_user(
        int(user["id"]),
        current_password,
        new_password,
        keep_token=keep_token,
    )

    return {
        "ok": True,
        "message": "Password changed.",
        "user": _auth_public_user(updated),
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



# ---------------------------------------------------------------------
# Public study decks/cards/progress foundation
# ---------------------------------------------------------------------
def _study_init_tables():
    _auth_init_tables()

    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS study_decks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS study_cards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                deck_id INTEGER NOT NULL,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                explanation TEXT,
                difficulty TEXT,
                tags_json TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id),
                FOREIGN KEY(deck_id) REFERENCES study_decks(id)
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS study_reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                deck_id INTEGER NOT NULL,
                card_id INTEGER NOT NULL,
                was_correct INTEGER NOT NULL,
                confidence INTEGER,
                response_time_ms INTEGER,
                reviewed_at TEXT NOT NULL,
                notes TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id),
                FOREIGN KEY(deck_id) REFERENCES study_decks(id),
                FOREIGN KEY(card_id) REFERENCES study_cards(id)
            )
            """
        )


def _study_current_user_id(request: Request) -> int:
    user_row = _auth_current_user_from_request(request)
    return int(user_row["id"])


def _study_parse_tags(value):
    if value is None:
        return []

    if isinstance(value, list):
        tags = value
    elif isinstance(value, str):
        tags = [part.strip() for part in value.split(",")]
    else:
        tags = []

    cleaned = []
    for tag in tags:
        tag = str(tag).strip()
        if tag and tag not in cleaned:
            cleaned.append(tag[:60])

    return cleaned[:20]


def _study_deck_for_user(deck_id: int, user_id: int):
    _study_init_tables()

    with db() as conn:
        row = conn.execute(
            """
            SELECT *
            FROM study_decks
            WHERE id = ?
              AND user_id = ?
              AND archived_at IS NULL
            LIMIT 1
            """,
            (int(deck_id), int(user_id)),
        ).fetchone()

    return row


def _study_card_for_user(card_id: int, user_id: int):
    _study_init_tables()

    with db() as conn:
        row = conn.execute(
            """
            SELECT *
            FROM study_cards
            WHERE id = ?
              AND user_id = ?
              AND archived_at IS NULL
            LIMIT 1
            """,
            (int(card_id), int(user_id)),
        ).fetchone()

    return row


def _study_card_to_public(row):
    data = row_to_dict(row)

    raw_tags = data.get("tags_json")
    if raw_tags:
        try:
            data["tags"] = json.loads(raw_tags)
        except Exception:
            data["tags"] = []
    else:
        data["tags"] = []

    data.pop("tags_json", None)

    return data



# STAGE_5P2_STUDY_SESSION_STATUS_BEGIN
_STUDY_SESSION_ACTIVE_STATUSES = (
    "active",
    "paused",
    "reviewing_answer",
    "waiting_for_mark",
)


def _study_init_session_tables():
    _study_init_tables()
    with db() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS study_sessions ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "user_id INTEGER NOT NULL, "
            "deck_id INTEGER, "
            "status TEXT NOT NULL, "
            "current_card_id INTEGER, "
            "queue_json TEXT, "
            "queue_position INTEGER NOT NULL DEFAULT 0, "
            "started_at TEXT, "
            "paused_at TEXT, "
            "ended_at TEXT, "
            "last_action TEXT, "
            "last_intent TEXT, "
            "created_at TEXT NOT NULL, "
            "updated_at TEXT NOT NULL, "
            "FOREIGN KEY(user_id) REFERENCES app_users(id), "
            "FOREIGN KEY(deck_id) REFERENCES study_decks(id), "
            "FOREIGN KEY(current_card_id) REFERENCES study_cards(id)"
            ")"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_study_sessions_user_status "
            "ON study_sessions(user_id, status, updated_at)"
        )
        # STAGE_5P11L_STUDY_SESSION_EVENTS_BEGIN
        conn.execute(
            "CREATE TABLE IF NOT EXISTS study_session_events ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "session_id INTEGER NOT NULL, "
            "user_id INTEGER NOT NULL, "
            "deck_id INTEGER, "
            "card_id INTEGER, "
            "event_type TEXT NOT NULL, "
            "was_correct INTEGER, "
            "created_at TEXT NOT NULL, "
            "metadata_json TEXT, "
            "FOREIGN KEY(session_id) REFERENCES study_sessions(id), "
            "FOREIGN KEY(user_id) REFERENCES app_users(id), "
            "FOREIGN KEY(deck_id) REFERENCES study_decks(id), "
            "FOREIGN KEY(card_id) REFERENCES study_cards(id)"
            ")"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_study_session_events_session "
            "ON study_session_events(session_id, created_at)"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_study_session_events_user "
            "ON study_session_events(user_id, created_at)"
        )
        # STAGE_5P11L_STUDY_SESSION_EVENTS_END

        # STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_BEGIN
        conn.execute(
            "CREATE TABLE IF NOT EXISTS study_user_totals ("
            "user_id INTEGER PRIMARY KEY, "
            "total_cards_reviewed INTEGER NOT NULL DEFAULT 0, "
            "total_answered INTEGER NOT NULL DEFAULT 0, "
            "total_correct INTEGER NOT NULL DEFAULT 0, "
            "total_wrong INTEGER NOT NULL DEFAULT 0, "
            "total_skipped INTEGER NOT NULL DEFAULT 0, "
            "total_study_seconds INTEGER NOT NULL DEFAULT 0, "
            "updated_at TEXT NOT NULL, "
            "FOREIGN KEY(user_id) REFERENCES app_users(id)"
            ")"
        )
        conn.execute(
            "CREATE TABLE IF NOT EXISTS study_deck_totals ("
            "user_id INTEGER NOT NULL, "
            "deck_id INTEGER NOT NULL, "
            "total_cards_reviewed INTEGER NOT NULL DEFAULT 0, "
            "total_answered INTEGER NOT NULL DEFAULT 0, "
            "total_correct INTEGER NOT NULL DEFAULT 0, "
            "total_wrong INTEGER NOT NULL DEFAULT 0, "
            "total_skipped INTEGER NOT NULL DEFAULT 0, "
            "total_study_seconds INTEGER NOT NULL DEFAULT 0, "
            "updated_at TEXT NOT NULL, "
            "PRIMARY KEY(user_id, deck_id), "
            "FOREIGN KEY(user_id) REFERENCES app_users(id), "
            "FOREIGN KEY(deck_id) REFERENCES study_decks(id)"
            ")"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_study_deck_totals_user "
            "ON study_deck_totals(user_id, updated_at)"
        )
        # STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_END
        conn.commit()




# STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_HELPERS_BEGIN
def _study_parse_elapsed_seconds(started_at, ended_at):
    if not started_at or not ended_at:
        return 0

    try:
        start_dt = datetime.fromisoformat(str(started_at))
        end_dt = datetime.fromisoformat(str(ended_at))

        if start_dt.tzinfo is None:
            start_dt = start_dt.replace(tzinfo=timezone.utc)
        if end_dt.tzinfo is None:
            end_dt = end_dt.replace(tzinfo=timezone.utc)

        return max(0, int((end_dt - start_dt).total_seconds()))
    except Exception:
        return 0


def _study_blank_total():
    return {
        "total_cards_reviewed": 0,
        "total_answered": 0,
        "total_correct": 0,
        "total_wrong": 0,
        "total_skipped": 0,
        "total_study_seconds": 0,
    }


def _study_rebuild_cumulative_totals(user_id=None):
    """
    Rebuild cumulative Study totals from durable detailed rows.

    Correct/wrong come from study_reviews.
    Skipped comes from study_session_events.
    Study time comes from completed/stopped study_sessions.

    This allows old detailed rows to be deleted later while keeping cumulative totals.
    """
    _study_init_session_tables()

    now = datetime.now(timezone.utc).isoformat()
    user_filter = ""
    params = []

    if user_id is not None:
        user_filter = "WHERE user_id = ?"
        params = [int(user_id)]

    deck_totals = {}
    user_totals = {}

    def ensure_user(uid):
        uid = int(uid)
        if uid not in user_totals:
            user_totals[uid] = _study_blank_total()
        return user_totals[uid]

    def ensure_deck(uid, did):
        uid = int(uid)
        did = int(did)
        key = (uid, did)
        if key not in deck_totals:
            deck_totals[key] = _study_blank_total()
        ensure_user(uid)
        return deck_totals[key]

    with db() as conn:
        conn.row_factory = sqlite3.Row

        review_rows = conn.execute(
            f"""
            SELECT
                user_id,
                deck_id,
                COUNT(*) AS total_answered,
                COALESCE(SUM(CASE WHEN was_correct = 1 THEN 1 ELSE 0 END), 0) AS total_correct,
                COALESCE(SUM(CASE WHEN was_correct = 0 THEN 1 ELSE 0 END), 0) AS total_wrong
            FROM study_reviews
            {user_filter}
            GROUP BY user_id, deck_id
            """,
            tuple(params),
        ).fetchall()

        for row in review_rows:
            uid = int(row["user_id"])
            did = row["deck_id"]
            answered = int(row["total_answered"] or 0)
            correct = int(row["total_correct"] or 0)
            wrong = int(row["total_wrong"] or 0)

            ut = ensure_user(uid)
            ut["total_answered"] += answered
            ut["total_cards_reviewed"] += answered
            ut["total_correct"] += correct
            ut["total_wrong"] += wrong

            if did is not None:
                dt = ensure_deck(uid, did)
                dt["total_answered"] += answered
                dt["total_cards_reviewed"] += answered
                dt["total_correct"] += correct
                dt["total_wrong"] += wrong

        skip_rows = conn.execute(
            f"""
            SELECT
                user_id,
                deck_id,
                COUNT(*) AS total_skipped
            FROM study_session_events
            WHERE event_type = 'skip'
            {"AND user_id = ?" if user_id is not None else ""}
            GROUP BY user_id, deck_id
            """,
            tuple(params),
        ).fetchall()

        for row in skip_rows:
            uid = int(row["user_id"])
            did = row["deck_id"]
            skipped = int(row["total_skipped"] or 0)

            ut = ensure_user(uid)
            ut["total_skipped"] += skipped
            ut["total_cards_reviewed"] += skipped

            if did is not None:
                dt = ensure_deck(uid, did)
                dt["total_skipped"] += skipped
                dt["total_cards_reviewed"] += skipped

        session_rows = conn.execute(
            f"""
            SELECT user_id, deck_id, started_at, ended_at
            FROM study_sessions
            WHERE started_at IS NOT NULL
              AND ended_at IS NOT NULL
              {"AND user_id = ?" if user_id is not None else ""}
            """,
            tuple(params),
        ).fetchall()

        for row in session_rows:
            uid = int(row["user_id"])
            did = row["deck_id"]
            seconds = _study_parse_elapsed_seconds(row["started_at"], row["ended_at"])

            ut = ensure_user(uid)
            ut["total_study_seconds"] += seconds

            if did is not None:
                dt = ensure_deck(uid, did)
                dt["total_study_seconds"] += seconds

        if user_id is not None:
            conn.execute("DELETE FROM study_user_totals WHERE user_id = ?", (int(user_id),))
            conn.execute("DELETE FROM study_deck_totals WHERE user_id = ?", (int(user_id),))
        else:
            conn.execute("DELETE FROM study_user_totals")
            conn.execute("DELETE FROM study_deck_totals")

        for uid, total in sorted(user_totals.items()):
            conn.execute(
                """
                INSERT INTO study_user_totals (
                    user_id,
                    total_cards_reviewed,
                    total_answered,
                    total_correct,
                    total_wrong,
                    total_skipped,
                    total_study_seconds,
                    updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    int(uid),
                    int(total["total_cards_reviewed"]),
                    int(total["total_answered"]),
                    int(total["total_correct"]),
                    int(total["total_wrong"]),
                    int(total["total_skipped"]),
                    int(total["total_study_seconds"]),
                    now,
                ),
            )

        for (uid, did), total in sorted(deck_totals.items()):
            conn.execute(
                """
                INSERT INTO study_deck_totals (
                    user_id,
                    deck_id,
                    total_cards_reviewed,
                    total_answered,
                    total_correct,
                    total_wrong,
                    total_skipped,
                    total_study_seconds,
                    updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    int(uid),
                    int(did),
                    int(total["total_cards_reviewed"]),
                    int(total["total_answered"]),
                    int(total["total_correct"]),
                    int(total["total_wrong"]),
                    int(total["total_skipped"]),
                    int(total["total_study_seconds"]),
                    now,
                ),
            )

        conn.commit()

    return {
        "ok": True,
        "user_id": int(user_id) if user_id is not None else None,
        "user_total_rows": len(user_totals),
        "deck_total_rows": len(deck_totals),
        "updated_at": now,
    }


def _study_get_cumulative_totals_for_user(user_id):
    _study_init_session_tables()

    _study_rebuild_cumulative_totals(user_id=int(user_id))

    with db() as conn:
        conn.row_factory = sqlite3.Row

        user_total = conn.execute(
            """
            SELECT *
            FROM study_user_totals
            WHERE user_id = ?
            """,
            (int(user_id),),
        ).fetchone()

        deck_totals = conn.execute(
            """
            SELECT
                t.*,
                d.title AS deck_title
            FROM study_deck_totals t
            LEFT JOIN study_decks d
                ON d.id = t.deck_id
               AND d.user_id = t.user_id
            WHERE t.user_id = ?
            ORDER BY t.updated_at DESC, t.deck_id DESC
            """,
            (int(user_id),),
        ).fetchall()

    return {
        "user_total": row_to_dict(user_total) if user_total else {
            "user_id": int(user_id),
            "total_cards_reviewed": 0,
            "total_answered": 0,
            "total_correct": 0,
            "total_wrong": 0,
            "total_skipped": 0,
            "total_study_seconds": 0,
            "updated_at": None,
        },
        "deck_totals": [row_to_dict(row) for row in deck_totals],
    }
# STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_HELPERS_END


# STAGE_5P11L_STUDY_SESSION_SUMMARY_HELPERS_BEGIN
def _study_insert_session_event_conn(
    conn,
    *,
    session_id: int,
    user_id: int,
    deck_id=None,
    card_id=None,
    event_type: str,
    was_correct=None,
    created_at: str | None = None,
    metadata: dict | None = None,
):
    event = str(event_type or "").strip()
    if not event:
        return

    ts = created_at or datetime.now(timezone.utc).isoformat()

    try:
        metadata_json = json.dumps(metadata or {}, sort_keys=True)
    except Exception:
        metadata_json = "{}"

    conn.execute(
        """
        INSERT INTO study_session_events (
            session_id,
            user_id,
            deck_id,
            card_id,
            event_type,
            was_correct,
            created_at,
            metadata_json
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            int(session_id),
            int(user_id),
            int(deck_id) if deck_id is not None else None,
            int(card_id) if card_id is not None else None,
            event,
            None if was_correct is None else (1 if was_correct else 0),
            ts,
            metadata_json,
        ),
    )


def _study_session_summary_for_row(item: dict, queue_count: int):
    session_id = item.get("id")
    user_id = item.get("user_id")

    summary = {
        "cards_total": int(queue_count or 0),
        "cards_reviewed": 0,
        "correct_count": 0,
        "wrong_count": 0,
        "skipped_count": 0,
        "answered_count": 0,
        "accuracy": None,
        "elapsed_seconds": None,
        "started_at": item.get("started_at"),
        "ended_at": item.get("ended_at"),
    }

    if not session_id or not user_id:
        return summary

    try:
        with sqlite3.connect(DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            event_stats = conn.execute(
                """
                SELECT
                    COUNT(CASE WHEN event_type IN ('mark_correct', 'mark_incorrect', 'skip') THEN 1 END) AS cards_reviewed,
                    COUNT(CASE WHEN event_type = 'mark_correct' THEN 1 END) AS correct_count,
                    COUNT(CASE WHEN event_type = 'mark_incorrect' THEN 1 END) AS wrong_count,
                    COUNT(CASE WHEN event_type = 'skip' THEN 1 END) AS skipped_count
                FROM study_session_events
                WHERE session_id = ?
                  AND user_id = ?
                """,
                (int(session_id), int(user_id)),
            ).fetchone()

        if event_stats:
            summary["cards_reviewed"] = int(event_stats["cards_reviewed"] or 0)
            summary["correct_count"] = int(event_stats["correct_count"] or 0)
            summary["wrong_count"] = int(event_stats["wrong_count"] or 0)
            summary["skipped_count"] = int(event_stats["skipped_count"] or 0)
    except Exception:
        pass

    summary["answered_count"] = int(summary["correct_count"]) + int(summary["wrong_count"])
    if summary["answered_count"]:
        summary["accuracy"] = round(summary["correct_count"] / summary["answered_count"], 4)

    try:
        start_raw = item.get("started_at")
        end_raw = item.get("ended_at") or item.get("updated_at")
        if start_raw and end_raw:
            start_dt = datetime.fromisoformat(str(start_raw))
            end_dt = datetime.fromisoformat(str(end_raw))
            summary["elapsed_seconds"] = max(0, int((end_dt - start_dt).total_seconds()))
    except Exception:
        summary["elapsed_seconds"] = None

    return summary
# STAGE_5P11L_STUDY_SESSION_SUMMARY_HELPERS_END


def _study_session_row_to_public(row):
    if not row:
        return {
            "id": None,
            "status": "none",
            "deck_id": None,
            "current_card_id": None,
            "queue_position": 0,
            "queue_count": 0,
            "last_action": None,
            "last_intent": None,
            "started_at": None,
            "paused_at": None,
            "ended_at": None,
            "created_at": None,
            "updated_at": None,
            "summary": {
                "cards_total": 0,
                "cards_reviewed": 0,
                "correct_count": 0,
                "wrong_count": 0,
                "skipped_count": 0,
                "answered_count": 0,
                "accuracy": None,
                "elapsed_seconds": None,
                "started_at": None,
                "ended_at": None,
            },
        }

    item = row_to_dict(row)
    queue_count = 0
    try:
        queue_items = json.loads(item.get("queue_json") or "[]")
        if isinstance(queue_items, list):
            queue_count = len(queue_items)
    except Exception:
        queue_count = 0

    # STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_BEGIN
    current_card = None
    current_card_id = item.get("current_card_id")

    if current_card_id:
        try:
            with sqlite3.connect(DB_PATH) as card_conn:
                card_conn.row_factory = sqlite3.Row
                card_row = card_conn.execute(
                    """
                    SELECT id, deck_id, question, answer, explanation, difficulty, tags_json
                    FROM study_cards
                    WHERE id = ?
                      AND user_id = ?
                      AND archived_at IS NULL
                    LIMIT 1
                    """,
                    (current_card_id, item.get("user_id")),
                ).fetchone()

            if card_row:
                current_card = {
                    "id": card_row["id"],
                    "deck_id": card_row["deck_id"],
                    "question": card_row["question"],
                    "answer": card_row["answer"],
                    "explanation": card_row["explanation"],
                    "difficulty": card_row["difficulty"],
                    "tags_json": card_row["tags_json"],
                }
        except Exception:
            current_card = None
    # STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_END

    return {
        "id": item.get("id"),
        "status": item.get("status") or "none",
        "deck_id": item.get("deck_id"),
        "current_card_id": current_card_id,
        "current_card": current_card,
        "queue_position": int(item.get("queue_position") or 0),
        "queue_count": queue_count,
        "last_action": item.get("last_action"),
        "last_intent": item.get("last_intent"),
        "started_at": item.get("started_at"),
        "paused_at": item.get("paused_at"),
        "ended_at": item.get("ended_at"),
        "created_at": item.get("created_at"),
        "updated_at": item.get("updated_at"),
        "summary": _study_session_summary_for_row(item, queue_count),
    }


def _study_get_current_session_for_user(user_id: int):
    _study_init_session_tables()
    placeholders = ",".join("?" for _ in _STUDY_SESSION_ACTIVE_STATUSES)
    params = [int(user_id), *_STUDY_SESSION_ACTIVE_STATUSES]

    with db() as conn:
        return conn.execute(
            f"SELECT * FROM study_sessions "
            f"WHERE user_id = ? AND status IN ({placeholders}) "
            f"ORDER BY updated_at DESC, id DESC LIMIT 1",
            params,
        ).fetchone()


@app.get("/public/study/session/status")
@app.get("/api/study/session/status")
async def public_study_session_status(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    row = _study_get_current_session_for_user(user_id)
    return {
        "ok": True,
        "session": _study_session_row_to_public(row),
    }
# STAGE_5P2_STUDY_SESSION_STATUS_END


# STAGE_5P3A_STUDY_SESSION_START_BEGIN
def _study_session_active_placeholders():
    return ",".join("?" for _ in _STUDY_SESSION_ACTIVE_STATUSES)


# STAGE_5P11Q_REVIEW_STYLE_SESSION_START_BEGIN
def _study_normalize_review_mode(value):
    mode = str(value or "balanced").strip().lower()
    aliases = {
        "": "balanced",
        "default": "balanced",
        "mixed": "balanced",
        "mix": "balanced",
        "normal": "balanced",
        "review": "balanced",
        "new cards": "new",
        "new card": "new",
        "hard cards": "hard",
        "medium cards": "medium",
        "easy cards": "easy",
        "balanced cards": "balanced",
    }
    mode = aliases.get(mode, mode)
    if mode not in {"balanced", "new", "hard", "medium", "easy"}:
        raise HTTPException(status_code=400, detail="review_mode must be balanced, new, hard, medium, or easy.")
    return mode


def _study_build_session_queue(user_id: int, deck_id: int, review_mode: str = "balanced"):
    mode = _study_normalize_review_mode(review_mode)

    try:
        data = _study_card_stats_for_deck(user_id=user_id, deck_id=deck_id)
        selected = _study_select_review_queue(data["cards"], mode=mode, limit=10000)
        queue = [
            int(card["id"])
            for card in selected.get("queue", [])
            if card.get("id") is not None
        ]
        if queue:
            return queue
    except HTTPException:
        raise
    except Exception:
        pass

    with db() as conn:
        rows = conn.execute(
            "SELECT id FROM study_cards "
            "WHERE user_id = ? AND deck_id = ? AND archived_at IS NULL "
            "ORDER BY created_at ASC, id ASC",
            (int(user_id), int(deck_id)),
        ).fetchall()

    return [int(row["id"]) for row in rows]
# STAGE_5P11Q_REVIEW_STYLE_SESSION_START_END


@app.post("/public/study/session/start")
@app.post("/api/study/session/start")
async def public_study_session_start(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    deck_id = payload.get("deck_id") if isinstance(payload, dict) else None
    try:
        deck_id = int(deck_id)
    except Exception:
        raise HTTPException(status_code=400, detail="deck_id is required")

    deck = _study_deck_for_user(deck_id, user_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Study deck not found")

    review_mode = _study_normalize_review_mode(
        payload.get("review_mode")
        or payload.get("mode")
        or payload.get("study_style")
        or "balanced"
    )

    queue = _study_build_session_queue(user_id, deck_id, review_mode=review_mode)
    if not queue:
        raise HTTPException(status_code=400, detail="Study deck has no active cards")

    now = datetime.now(timezone.utc).isoformat()
    active_placeholders = _study_session_active_placeholders()
    active_params = [int(user_id), *_STUDY_SESSION_ACTIVE_STATUSES]

    with db() as conn:
        conn.execute(
            f"UPDATE study_sessions "
            f"SET status = 'stopped', ended_at = ?, updated_at = ?, "
            f"last_action = 'auto_stop_for_new_start', last_intent = 'study_session_start' "
            f"WHERE user_id = ? AND status IN ({active_placeholders})",
            [now, now, *active_params],
        )

        cur = conn.execute(
            "INSERT INTO study_sessions ("
            "user_id, deck_id, status, current_card_id, queue_json, queue_position, "
            "started_at, paused_at, ended_at, last_action, last_intent, created_at, updated_at"
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (
                int(user_id),
                int(deck_id),
                "active",
                int(queue[0]),
                json.dumps(queue),
                0,
                now,
                None,
                None,
                "start",
                "study_session_start",
                now,
                now,
            ),
        )
        _study_insert_session_event_conn(
            conn,
            session_id=int(cur.lastrowid),
            user_id=int(user_id),
            deck_id=int(deck_id),
            card_id=int(queue[0]),
            event_type="start",
            created_at=now,
            metadata={"queue_count": len(queue)},
        )
        conn.commit()

        row = conn.execute(
            "SELECT * FROM study_sessions WHERE id = ?",
            (cur.lastrowid,),
        ).fetchone()

    return {
        "ok": True,
        "intent": "study_session_start",
        "command": "start",
        "session": _study_session_row_to_public(row),
    }
# STAGE_5P3A_STUDY_SESSION_START_END


# STAGE_5P3B_STUDY_SESSION_LIFECYCLE_BEGIN
def _study_require_current_session_for_user(user_id: int):
    row = _study_get_current_session_for_user(user_id)
    if not row:
        raise HTTPException(status_code=404, detail="No active study session found")
    return row


def _study_update_session_status(session_id: int, status: str, action: str, intent: str):
    _study_init_session_tables()
    now = datetime.now(timezone.utc).isoformat()

    paused_at = now if status == "paused" else None
    ended_at = now if status in ("stopped", "completed") else None

    with db() as conn:
        conn.execute(
            "UPDATE study_sessions "
            "SET status = ?, paused_at = ?, ended_at = ?, "
            "last_action = ?, last_intent = ?, updated_at = ? "
            "WHERE id = ?",
            (
                status,
                paused_at,
                ended_at,
                action,
                intent,
                now,
                int(session_id),
            ),
        )
        session_row = conn.execute(
            "SELECT * FROM study_sessions WHERE id = ?",
            (int(session_id),),
        ).fetchone()
        if session_row:
            _study_insert_session_event_conn(
                conn,
                session_id=int(session_id),
                user_id=int(session_row["user_id"]),
                deck_id=session_row["deck_id"],
                card_id=session_row["current_card_id"],
                event_type=str(action or intent or status),
                created_at=now,
                metadata={"status": status, "intent": intent},
            )
        conn.commit()
        return conn.execute(
            "SELECT * FROM study_sessions WHERE id = ?",
            (int(session_id),),
        ).fetchone()


@app.post("/public/study/session/pause")
@app.post("/api/study/session/pause")
async def public_study_session_pause(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    row = _study_require_current_session_for_user(user_id)

    status = row["status"]
    if status == "paused":
        return {
            "ok": True,
            "intent": "study_session_pause",
            "command": "pause",
            "session": _study_session_row_to_public(row),
        }

    if status not in ("active", "reviewing_answer", "waiting_for_mark"):
        raise HTTPException(status_code=400, detail=f"Cannot pause session with status {status}")

    updated = _study_update_session_status(
        row["id"],
        "paused",
        "pause",
        "study_session_pause",
    )
    return {
        "ok": True,
        "intent": "study_session_pause",
        "command": "pause",
        "session": _study_session_row_to_public(updated),
    }


@app.post("/public/study/session/resume")
@app.post("/api/study/session/resume")
async def public_study_session_resume(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    row = _study_require_current_session_for_user(user_id)

    status = row["status"]
    if status == "active":
        return {
            "ok": True,
            "intent": "study_session_resume",
            "command": "resume",
            "session": _study_session_row_to_public(row),
        }

    if status != "paused":
        raise HTTPException(status_code=400, detail=f"Cannot resume session with status {status}")

    updated = _study_update_session_status(
        row["id"],
        "active",
        "resume",
        "study_session_resume",
    )
    return {
        "ok": True,
        "intent": "study_session_resume",
        "command": "resume",
        "session": _study_session_row_to_public(updated),
    }


@app.post("/public/study/session/stop")
@app.post("/api/study/session/stop")
async def public_study_session_stop(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    row = _study_require_current_session_for_user(user_id)

    updated = _study_update_session_status(
        row["id"],
        "stopped",
        "stop",
        "study_session_stop",
    )
    return {
        "ok": True,
        "intent": "study_session_stop",
        "command": "stop",
        "session": _study_session_row_to_public(updated),
    }
# STAGE_5P3B_STUDY_SESSION_LIFECYCLE_END


# STAGE_5P4_STUDY_INTENT_PARSER_BEGIN
def _study_normalize_intent_text(message: str) -> str:
    raw = str(message or "").strip().lower()
    cleaned = []
    for ch in raw:
        if ch.isalnum() or ch.isspace():
            cleaned.append(ch)
        else:
            cleaned.append(" ")
    return " ".join("".join(cleaned).split())


def _study_text_has_any(text: str, words: tuple[str, ...]) -> bool:
    tokens = set(text.split())
    return any(word in tokens for word in words)


def _study_parse_deterministic_intent(message: str, session_status: str = "none"):
    text = _study_normalize_intent_text(message)
    tokens = set(text.split())

    has_study = "study" in tokens
    has_session = "session" in tokens
    active_statuses = {"active", "reviewing_answer", "waiting_for_mark", "paused"}
    has_active_session = str(session_status or "none") in active_statuses

    if not text:
        return {
            "intent": "unknown",
            "command": None,
            "session_required": False,
            "model_tier": "small",
            "queue_lane": "companion-small",
            "reason": "Empty message.",
        }

    if has_study and has_session and _study_text_has_any(text, ("start", "begin", "deck", "cards")):
        return {
            "intent": "study_session_start",
            "command": "start",
            "session_required": False,
            "model_tier": "small",
            "queue_lane": "study-small",
            "reason": "Message contains study + session + start/begin/deck/cards.",
        }

    if has_study and has_session and _study_text_has_any(text, ("pause", "hold")):
        return {
            "intent": "study_session_pause",
            "command": "pause",
            "session_required": True,
            "model_tier": "small",
            "queue_lane": "study-small",
            "reason": "Message contains study + session + pause/hold.",
        }

    if has_study and has_session and _study_text_has_any(text, ("resume", "continue")):
        return {
            "intent": "study_session_resume",
            "command": "resume",
            "session_required": True,
            "model_tier": "small",
            "queue_lane": "study-small",
            "reason": "Message contains study + session + resume/continue.",
        }

    if has_study and has_session and _study_text_has_any(text, ("stop", "end", "finish", "quit")):
        return {
            "intent": "study_session_stop",
            "command": "stop",
            "session_required": True,
            "model_tier": "small",
            "queue_lane": "study-small",
            "reason": "Message contains study + session + stop/end/finish/quit.",
        }

    if has_study and has_session and _study_text_has_any(text, ("status", "state", "progress")):
        return {
            "intent": "study_session_status",
            "command": "status",
            "session_required": False,
            "model_tier": "small",
            "queue_lane": "study-small",
            "reason": "Message contains study + session + status/state/progress.",
        }

    if has_active_session:
        if "answer" in tokens and _study_text_has_any(text, ("read", "show", "tell", "what")):
            return {
                "intent": "study_read_answer",
                "command": "read_answer",
                "session_required": True,
                "model_tier": "small",
                "queue_lane": "study-small",
                "reason": "Active study session and user requested the answer.",
            }

        if _study_text_has_any(text, ("correct", "right")) or "got it" in text:
            return {
                "intent": "study_mark_correct",
                "command": "mark_correct",
                "session_required": True,
                "model_tier": "small",
                "queue_lane": "study-small",
                "reason": "Active study session and user marked correct.",
            }

        if _study_text_has_any(text, ("incorrect", "wrong")) or "missed it" in text:
            return {
                "intent": "study_mark_incorrect",
                "command": "mark_incorrect",
                "session_required": True,
                "model_tier": "small",
                "queue_lane": "study-small",
                "reason": "Active study session and user marked incorrect.",
            }

        if _study_text_has_any(text, ("skip", "pass")):
            return {
                "intent": "study_skip",
                "command": "skip",
                "session_required": True,
                "model_tier": "small",
                "queue_lane": "study-small",
                "reason": "Active study session and user requested skip/pass.",
            }

        if _study_text_has_any(text, ("next",)):
            return {
                "intent": "study_next_card",
                "command": "next_card",
                "session_required": True,
                "model_tier": "small",
                "queue_lane": "study-small",
                "reason": "Active study session and user requested next card.",
            }

        return {
            "intent": "study_answer_attempt",
            "command": "submit_answer",
            "session_required": True,
            "model_tier": "small",
            "queue_lane": "study-small",
            "reason": "Active study session and message did not match a control command.",
        }

    if "explain" in tokens or "why" in tokens or "help" in tokens:
        return {
            "intent": "companion_study_help" if has_study else "general_companion_message",
            "command": None,
            "session_required": False,
            "model_tier": "medium",
            "queue_lane": "companion-medium",
            "reason": "Message appears to request help or explanation.",
        }

    return {
        "intent": "general_companion_message",
        "command": None,
        "session_required": False,
        "model_tier": "small",
        "queue_lane": "companion-small",
        "reason": "No study-session command matched.",
    }


@app.post("/public/study/intent/parse")
@app.post("/api/study/intent/parse")
async def public_study_intent_parse(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    message = payload.get("message") if isinstance(payload, dict) else ""
    session_status = payload.get("session_status") if isinstance(payload, dict) else None

    if not session_status:
        row = _study_get_current_session_for_user(user_id)
        session_status = row["status"] if row else "none"

    parsed = _study_parse_deterministic_intent(message, session_status=session_status)

    return {
        "ok": True,
        "message": message,
        "session_status": session_status,
        **parsed,
    }
# STAGE_5P4_STUDY_INTENT_PARSER_END



# STAGE_5P6A_STUDY_READ_ANSWER_BEGIN
def _study_get_card_for_session(row, user_id: int):
    if not row:
        raise HTTPException(status_code=404, detail="No active study session found")

    card_id = row["current_card_id"]
    deck_id = row["deck_id"]

    if not card_id:
        raise HTTPException(status_code=400, detail="Study session has no current card")

    with db() as conn:
        card = conn.execute(
            "SELECT * FROM study_cards "
            "WHERE id = ? AND user_id = ? AND deck_id = ? AND archived_at IS NULL "
            "LIMIT 1",
            (
                int(card_id),
                int(user_id),
                int(deck_id),
            ),
        ).fetchone()

    if not card:
        raise HTTPException(status_code=404, detail="Current study card not found")

    return card


def _study_card_answer_payload(card):
    item = _study_card_to_public(card)
    return {
        "id": item.get("id"),
        "deck_id": item.get("deck_id"),
        "question": item.get("question"),
        "answer": item.get("answer"),
        "hint": item.get("hint"),
        "tags": item.get("tags") or [],
    }


def _study_read_answer_for_current_session(user_id: int):
    row = _study_require_current_session_for_user(user_id)
    status = row["status"]

    if status == "paused":
        raise HTTPException(status_code=400, detail="Cannot read answer while study session is paused")

    if status not in ("active", "reviewing_answer", "waiting_for_mark"):
        raise HTTPException(status_code=400, detail=f"Cannot read answer with session status {status}")

    card = _study_get_card_for_session(row, user_id)

    updated = _study_update_session_status(
        row["id"],
        "reviewing_answer",
        "read_answer",
        "study_read_answer",
    )

    return {
        "ok": True,
        "intent": "study_read_answer",
        "command": "read_answer",
        "session": _study_session_row_to_public(updated),
        "card": _study_card_answer_payload(card),
        "response": _study_card_answer_payload(card).get("answer"),
    }
# STAGE_5P6A_STUDY_READ_ANSWER_END


# STAGE_5P6B_STUDY_MARK_CARD_BEGIN
def _study_session_queue_items(row):
    try:
        items = json.loads(row["queue_json"] or "[]")
        if isinstance(items, list):
            return [int(item) for item in items]
    except Exception:
        pass
    return []


def _study_mark_current_card_for_session(user_id: int, was_correct: bool):
    row = _study_require_current_session_for_user(user_id)
    status = row["status"]

    if status == "paused":
        raise HTTPException(status_code=400, detail="Cannot mark card while study session is paused")

    if status not in ("active", "reviewing_answer", "waiting_for_mark"):
        raise HTTPException(status_code=400, detail=f"Cannot mark card with session status {status}")

    card = _study_get_card_for_session(row, user_id)
    queue_items = _study_session_queue_items(row)
    position = int(row["queue_position"] or 0)
    next_position = position + 1
    next_card_id = queue_items[next_position] if next_position < len(queue_items) else None
    next_status = "active" if next_card_id else "completed"

    now = datetime.now(timezone.utc).isoformat()
    action = "mark_correct" if was_correct else "mark_incorrect"
    intent = "study_mark_correct" if was_correct else "study_mark_incorrect"

    with db() as conn:
        conn.execute(
            "INSERT INTO study_reviews ("
            "user_id, deck_id, card_id, was_correct, confidence, response_time_ms, reviewed_at, notes"
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (
                int(user_id),
                int(row["deck_id"]),
                int(card["id"]),
                1 if was_correct else 0,
                None,
                None,
                now,
                action,
            ),
        )

        conn.execute(
            "UPDATE study_sessions "
            "SET status = ?, current_card_id = ?, queue_position = ?, ended_at = ?, "
            "last_action = ?, last_intent = ?, updated_at = ? "
            "WHERE id = ?",
            (
                next_status,
                int(next_card_id) if next_card_id else None,
                int(next_position),
                now if next_status == "completed" else None,
                action,
                intent,
                now,
                int(row["id"]),
            ),
        )
        _study_insert_session_event_conn(
            conn,
            session_id=int(row["id"]),
            user_id=int(user_id),
            deck_id=int(row["deck_id"]),
            card_id=int(card["id"]),
            event_type=action,
            was_correct=bool(was_correct),
            created_at=now,
            metadata={
                "intent": intent,
                "next_status": next_status,
                "next_card_id": int(next_card_id) if next_card_id else None,
            },
        )
        conn.commit()

        updated = conn.execute(
            "SELECT * FROM study_sessions WHERE id = ?",
            (int(row["id"]),),
        ).fetchone()

    return {
        "ok": True,
        "intent": intent,
        "command": action,
        "was_correct": bool(was_correct),
        "completed": next_status == "completed",
        "reviewed_card": _study_card_answer_payload(card),
        "session": _study_session_row_to_public(updated),
    }
# STAGE_5P6B_STUDY_MARK_CARD_END


# STAGE_5P6D_STUDY_SKIP_NEXT_BEGIN
def _study_advance_current_session_without_review(user_id: int, action: str, intent: str):
    row = _study_require_current_session_for_user(user_id)
    status = row["status"]

    if status == "paused":
        raise HTTPException(status_code=400, detail="Cannot advance card while study session is paused")

    if status not in ("active", "reviewing_answer", "waiting_for_mark"):
        raise HTTPException(status_code=400, detail=f"Cannot advance card with session status {status}")

    card = _study_get_card_for_session(row, user_id)
    queue_items = _study_session_queue_items(row)
    position = int(row["queue_position"] or 0)
    next_position = position + 1
    next_card_id = queue_items[next_position] if next_position < len(queue_items) else None
    next_status = "active" if next_card_id else "completed"
    now = datetime.now(timezone.utc).isoformat()

    with db() as conn:
        conn.execute(
            "UPDATE study_sessions "
            "SET status = ?, current_card_id = ?, queue_position = ?, ended_at = ?, "
            "last_action = ?, last_intent = ?, updated_at = ? "
            "WHERE id = ?",
            (
                next_status,
                int(next_card_id) if next_card_id else None,
                int(next_position),
                now if next_status == "completed" else None,
                action,
                intent,
                now,
                int(row["id"]),
            ),
        )
        _study_insert_session_event_conn(
            conn,
            session_id=int(row["id"]),
            user_id=int(user_id),
            deck_id=int(row["deck_id"]),
            card_id=int(card["id"]),
            event_type=action,
            was_correct=None,
            created_at=now,
            metadata={
                "intent": intent,
                "next_status": next_status,
                "next_card_id": int(next_card_id) if next_card_id else None,
            },
        )
        conn.commit()

        updated = conn.execute(
            "SELECT * FROM study_sessions WHERE id = ?",
            (int(row["id"]),),
        ).fetchone()

    return {
        "ok": True,
        "intent": intent,
        "command": action,
        "skipped": action == "skip",
        "completed": next_status == "completed",
        "previous_card": _study_card_answer_payload(card),
        "session": _study_session_row_to_public(updated),
    }
# STAGE_5P6D_STUDY_SKIP_NEXT_END

# STAGE_5P5A_STUDY_SESSION_COMMAND_LIFECYCLE_BEGIN
async def _study_execute_lifecycle_command(request: Request, parsed: dict, payload: dict):
    intent = parsed.get("intent")
    command = parsed.get("command")

    if intent == "study_session_status" or command == "status":
        user_id = _study_current_user_id(request)
        row = _study_get_current_session_for_user(user_id)
        return {
            "ok": True,
            "intent": intent,
            "command": "status",
            "session": _study_session_row_to_public(row),
            "router": parsed,
        }

    if intent == "study_session_start" or command == "start":
        deck_id = payload.get("deck_id")
        if deck_id is None:
            raise HTTPException(status_code=400, detail="deck_id is required to start a study session")
        return await public_study_session_start(request)

    if intent == "study_session_pause" or command == "pause":
        return await public_study_session_pause(request)

    if intent == "study_session_resume" or command == "resume":
        return await public_study_session_resume(request)

    if intent == "study_session_stop" or command == "stop":
        return await public_study_session_stop(request)

    if intent == "study_read_answer" or command == "read_answer":
        user_id = _study_current_user_id(request)
        return _study_read_answer_for_current_session(user_id)

    if intent == "study_mark_correct" or command == "mark_correct":
        user_id = _study_current_user_id(request)
        return _study_mark_current_card_for_session(user_id, True)

    if intent == "study_mark_incorrect" or command == "mark_incorrect":
        user_id = _study_current_user_id(request)
        return _study_mark_current_card_for_session(user_id, False)

    if intent == "study_skip" or command == "skip":
        user_id = _study_current_user_id(request)
        return _study_advance_current_session_without_review(user_id, "skip", "study_skip")

    if intent == "study_next_card" or command == "next_card":
        user_id = _study_current_user_id(request)
        return _study_advance_current_session_without_review(user_id, "next_card", "study_next_card")

    return None


@app.post("/public/study/session/command")
@app.post("/api/study/session/command")
async def public_study_session_command(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required")

    message = str(payload.get("message") or "")
    session_status = payload.get("session_status")

    if not session_status:
        row = _study_get_current_session_for_user(user_id)
        session_status = row["status"] if row else "none"

    parsed = _study_parse_deterministic_intent(message, session_status=session_status)
    lifecycle_result = await _study_execute_lifecycle_command(request, parsed, payload)

    if lifecycle_result is not None:
        lifecycle_result["parsed"] = parsed
        return lifecycle_result

    return {
        "ok": True,
        "executed": False,
        "intent": parsed.get("intent"),
        "command": parsed.get("command"),
        "session_status": session_status,
        "parsed": parsed,
        "reason": "Intent parsed but command execution is not implemented in Stage 5P-5A.",
    }
# STAGE_5P5A_STUDY_SESSION_COMMAND_LIFECYCLE_END





@app.post("/public/study/decks")
@app.post("/api/study/decks")
async def public_study_create_deck(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    title = payload.get("title") if isinstance(payload, dict) else None
    description = payload.get("description") if isinstance(payload, dict) else None

    if not isinstance(title, str) or not title.strip():
        raise HTTPException(status_code=400, detail="title is required.")

    title = title.strip()[:200]
    description = str(description).strip()[:2000] if description is not None else None
    if description == "":
        description = None

    now = datetime.now(timezone.utc).isoformat()

    with db() as conn:
        cur = conn.execute(
            """
            INSERT INTO study_decks (
                user_id,
                title,
                description,
                created_at,
                updated_at,
                archived_at
            )
            VALUES (?, ?, ?, ?, ?, NULL)
            """,
            (
                user_id,
                title,
                description,
                now,
                now,
            ),
        )

        deck_id = cur.lastrowid

        row = conn.execute(
            """
            SELECT *
            FROM study_decks
            WHERE id = ?
            """,
            (deck_id,),
        ).fetchone()

    return {
        "ok": True,
        "deck": row_to_dict(row),
    }


@app.get("/public/study/decks")
@app.get("/api/study/decks")
async def public_study_list_decks(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    with db() as conn:
        rows = conn.execute(
            """
            SELECT
                d.*,
                COUNT(DISTINCT c.id) AS card_count,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 1 THEN r.id END), 0) AS correct_reviews,
                COUNT(DISTINCT r.id) AS total_reviews
            FROM study_decks d
            LEFT JOIN study_cards c
                ON c.deck_id = d.id
               AND c.archived_at IS NULL
            LEFT JOIN study_reviews r
                ON r.deck_id = d.id
            WHERE d.user_id = ?
              AND d.archived_at IS NULL
            GROUP BY d.id
            ORDER BY d.updated_at DESC, d.id DESC
            """,
            (user_id,),
        ).fetchall()

    decks = []
    for row in rows:
        item = row_to_dict(row)
        total_reviews = int(item.get("total_reviews") or 0)
        correct_reviews = int(item.get("correct_reviews") or 0)
        item["accuracy"] = round(correct_reviews / total_reviews, 4) if total_reviews else None
        decks.append(item)

    return {
        "ok": True,
        "user_id": user_id,
        "count": len(decks),
        "decks": decks,
    }



@app.delete("/public/study/decks/{deck_id}")
@app.delete("/api/study/decks/{deck_id}")
async def public_study_delete_deck(deck_id: int, request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    deck = _study_deck_for_user(deck_id, user_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found.")

    now = datetime.now(timezone.utc).isoformat()
    with db() as conn:
        conn.execute(
            "UPDATE study_decks SET archived_at = ?, updated_at = ? WHERE id = ? AND user_id = ?",
            (now, now, int(deck_id), int(user_id)),
        )
        conn.execute(
            "UPDATE study_cards SET archived_at = ?, updated_at = ? WHERE deck_id = ? AND user_id = ? AND archived_at IS NULL",
            (now, now, int(deck_id), int(user_id)),
        )
        conn.commit()

    return {"ok": True, "deck_id": int(deck_id), "archived_at": now}


@app.post("/public/study/decks/{deck_id}/cards")
@app.post("/api/study/decks/{deck_id}/cards")
async def public_study_create_card(deck_id: int, request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    deck = _study_deck_for_user(deck_id, user_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found.")

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    question = payload.get("question") if isinstance(payload, dict) else None
    answer = payload.get("answer") if isinstance(payload, dict) else None
    explanation = payload.get("explanation") if isinstance(payload, dict) else None
    difficulty = payload.get("difficulty") if isinstance(payload, dict) else None
    tags = _study_parse_tags(payload.get("tags") if isinstance(payload, dict) else None)

    if not isinstance(question, str) or not question.strip():
        raise HTTPException(status_code=400, detail="question is required.")

    if not isinstance(answer, str) or not answer.strip():
        raise HTTPException(status_code=400, detail="answer is required.")

    question = question.strip()[:4000]
    answer = answer.strip()[:4000]
    explanation = str(explanation).strip()[:4000] if explanation is not None else None
    if explanation == "":
        explanation = None

    difficulty = str(difficulty).strip().lower()[:40] if difficulty is not None else None
    if difficulty == "":
        difficulty = None

    now = datetime.now(timezone.utc).isoformat()

    with db() as conn:
        cur = conn.execute(
            """
            INSERT INTO study_cards (
                user_id,
                deck_id,
                question,
                answer,
                explanation,
                difficulty,
                tags_json,
                created_at,
                updated_at,
                archived_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
            """,
            (
                user_id,
                int(deck_id),
                question,
                answer,
                explanation,
                difficulty,
                json.dumps(tags, ensure_ascii=False),
                now,
                now,
            ),
        )

        card_id = cur.lastrowid

        conn.execute(
            """
            UPDATE study_decks
            SET updated_at = ?
            WHERE id = ?
              AND user_id = ?
            """,
            (
                now,
                int(deck_id),
                user_id,
            ),
        )

        row = conn.execute(
            """
            SELECT *
            FROM study_cards
            WHERE id = ?
            """,
            (card_id,),
        ).fetchone()

    return {
        "ok": True,
        "card": _study_card_to_public(row),
    }


@app.get("/public/study/decks/{deck_id}/cards")
@app.get("/api/study/decks/{deck_id}/cards")
async def public_study_list_cards(deck_id: int, request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    deck = _study_deck_for_user(deck_id, user_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found.")

    with db() as conn:
        rows = conn.execute(
            """
            SELECT
                c.*,
                COUNT(r.id) AS review_count,
                COALESCE(SUM(CASE WHEN r.was_correct = 1 THEN 1 ELSE 0 END), 0) AS correct_count,
                MAX(r.reviewed_at) AS last_reviewed_at
            FROM study_cards c
            LEFT JOIN study_reviews r
                ON r.card_id = c.id
            WHERE c.user_id = ?
              AND c.deck_id = ?
              AND c.archived_at IS NULL
            GROUP BY c.id
            ORDER BY c.created_at ASC, c.id ASC
            """,
            (
                user_id,
                int(deck_id),
            ),
        ).fetchall()

    cards = []
    for row in rows:
        item = _study_card_to_public(row)
        review_count = int(item.get("review_count") or 0)
        correct_count = int(item.get("correct_count") or 0)
        item["accuracy"] = round(correct_count / review_count, 4) if review_count else None
        cards.append(item)

    return {
        "ok": True,
        "user_id": user_id,
        "deck": row_to_dict(deck),
        "count": len(cards),
        "cards": cards,
    }



@app.delete("/public/study/cards/{card_id}")
@app.delete("/api/study/cards/{card_id}")
async def public_study_delete_card(card_id: int, request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    card = _study_card_for_user(card_id, user_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found.")

    now = datetime.now(timezone.utc).isoformat()
    with db() as conn:
        conn.execute(
            "UPDATE study_cards SET archived_at = ?, updated_at = ? WHERE id = ? AND user_id = ?",
            (now, now, int(card_id), int(user_id)),
        )
        conn.commit()

    return {"ok": True, "card_id": int(card_id), "archived_at": now}


@app.post("/public/study/cards/{card_id}/reviews")
@app.post("/api/study/cards/{card_id}/reviews")
async def public_study_review_card(card_id: int, request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    card = _study_card_for_user(card_id, user_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found.")

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    was_correct = payload.get("was_correct") if isinstance(payload, dict) else None
    confidence = payload.get("confidence") if isinstance(payload, dict) else None
    response_time_ms = payload.get("response_time_ms") if isinstance(payload, dict) else None
    notes = payload.get("notes") if isinstance(payload, dict) else None

    if isinstance(was_correct, bool):
        was_correct_int = 1 if was_correct else 0
    elif was_correct in (0, 1, "0", "1"):
        was_correct_int = int(was_correct)
    else:
        raise HTTPException(status_code=400, detail="was_correct must be true or false.")

    try:
        confidence_int = int(confidence) if confidence is not None else None
    except Exception:
        raise HTTPException(status_code=400, detail="confidence must be an integer 1-5.")

    if confidence_int is not None and not (1 <= confidence_int <= 5):
        raise HTTPException(status_code=400, detail="confidence must be between 1 and 5.")

    try:
        response_time_int = int(response_time_ms) if response_time_ms is not None else None
    except Exception:
        raise HTTPException(status_code=400, detail="response_time_ms must be an integer.")

    if response_time_int is not None and response_time_int < 0:
        response_time_int = None

    notes = str(notes).strip()[:2000] if notes is not None else None
    if notes == "":
        notes = None

    reviewed_at = datetime.now(timezone.utc).isoformat()
    deck_id = int(card["deck_id"])

    with db() as conn:
        cur = conn.execute(
            """
            INSERT INTO study_reviews (
                user_id,
                deck_id,
                card_id,
                was_correct,
                confidence,
                response_time_ms,
                reviewed_at,
                notes
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                deck_id,
                int(card_id),
                was_correct_int,
                confidence_int,
                response_time_int,
                reviewed_at,
                notes,
            ),
        )

        review_id = cur.lastrowid

        conn.execute(
            """
            UPDATE study_decks
            SET updated_at = ?
            WHERE id = ?
              AND user_id = ?
            """,
            (
                reviewed_at,
                deck_id,
                user_id,
            ),
        )

        review = conn.execute(
            """
            SELECT *
            FROM study_reviews
            WHERE id = ?
            """,
            (review_id,),
        ).fetchone()

        stats = conn.execute(
            """
            SELECT
                COUNT(*) AS total_reviews,
                COALESCE(SUM(CASE WHEN was_correct = 1 THEN 1 ELSE 0 END), 0) AS correct_reviews
            FROM study_reviews
            WHERE user_id = ?
              AND card_id = ?
            """,
            (
                user_id,
                int(card_id),
            ),
        ).fetchone()

    total_reviews = int(stats["total_reviews"] or 0)
    correct_reviews = int(stats["correct_reviews"] or 0)

    return {
        "ok": True,
        "review": row_to_dict(review),
        "card_stats": {
            "card_id": int(card_id),
            "total_reviews": total_reviews,
            "correct_reviews": correct_reviews,
            "accuracy": round(correct_reviews / total_reviews, 4) if total_reviews else None,
        },
    }



# STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_ENDPOINT_BEGIN
@app.post("/system/study/totals/rebuild")
@app.post("/api/system/study/totals/rebuild")
async def system_study_totals_rebuild(request: Request):
    await _require_admin(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    requested_user_id = payload.get("user_id") if isinstance(payload, dict) else None

    if requested_user_id in (None, "", "all"):
        result = _study_rebuild_cumulative_totals()
    else:
        try:
            result = _study_rebuild_cumulative_totals(user_id=int(requested_user_id))
        except Exception:
            raise HTTPException(status_code=400, detail="user_id must be an integer or 'all'.")

    return result


@app.get("/public/study/totals")
@app.get("/api/study/totals")
async def public_study_totals(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    totals = _study_get_cumulative_totals_for_user(user_id)
    return {
        "ok": True,
        "user_id": user_id,
        "totals": totals,
    }
# STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_ENDPOINT_END


@app.get("/public/study/progress")
@app.get("/api/study/progress")
async def public_study_progress(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    with db() as conn:
        overall = conn.execute(
            """
            SELECT
                COUNT(DISTINCT d.id) AS deck_count,
                COUNT(DISTINCT c.id) AS card_count,
                COUNT(DISTINCT r.id) AS review_count,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 1 THEN r.id END), 0) AS correct_reviews
            FROM study_decks d
            LEFT JOIN study_cards c
                ON c.deck_id = d.id
               AND c.archived_at IS NULL
            LEFT JOIN study_reviews r
                ON r.deck_id = d.id
            WHERE d.user_id = ?
              AND d.archived_at IS NULL
            """,
            (user_id,),
        ).fetchone()

        by_deck_rows = conn.execute(
            """
            SELECT
                d.id AS deck_id,
                d.title,
                COUNT(DISTINCT c.id) AS card_count,
                COUNT(DISTINCT r.id) AS review_count,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 1 THEN r.id END), 0) AS correct_reviews,
                MAX(r.reviewed_at) AS last_reviewed_at
            FROM study_decks d
            LEFT JOIN study_cards c
                ON c.deck_id = d.id
               AND c.archived_at IS NULL
            LEFT JOIN study_reviews r
                ON r.deck_id = d.id
            WHERE d.user_id = ?
              AND d.archived_at IS NULL
            GROUP BY d.id
            ORDER BY d.updated_at DESC, d.id DESC
            """,
            (user_id,),
        ).fetchall()

        recent_rows = conn.execute(
            """
            SELECT
                r.id,
                r.deck_id,
                d.title AS deck_title,
                r.card_id,
                c.question,
                r.was_correct,
                r.confidence,
                r.response_time_ms,
                r.reviewed_at
            FROM study_reviews r
            JOIN study_decks d ON d.id = r.deck_id
            JOIN study_cards c ON c.id = r.card_id
            WHERE r.user_id = ?
            ORDER BY r.reviewed_at DESC, r.id DESC
            LIMIT 20
            """,
            (user_id,),
        ).fetchall()

    overall_data = row_to_dict(overall)
    total_reviews = int(overall_data.get("review_count") or 0)
    correct_reviews = int(overall_data.get("correct_reviews") or 0)
    overall_data["accuracy"] = round(correct_reviews / total_reviews, 4) if total_reviews else None

    by_deck = []
    for row in by_deck_rows:
        item = row_to_dict(row)
        review_count = int(item.get("review_count") or 0)
        correct_count = int(item.get("correct_reviews") or 0)
        item["accuracy"] = round(correct_count / review_count, 4) if review_count else None
        by_deck.append(item)

    return {
        "ok": True,
        "user_id": user_id,
        "overall": overall_data,
        "by_deck": by_deck,
        "recent_reviews": [row_to_dict(row) for row in recent_rows],
    }



# ---------------------------------------------------------------------
# Public study per-card stats and review queue selection
# ---------------------------------------------------------------------
def _study_bucket_for_card(card):
    """
    Classify a card for adaptive review.

    Buckets:
      new    = not reviewed yet, unless user manually marked difficulty
      hard   = clearly struggling
      medium = partially learned / needs reinforcement
      easy   = consistently correct with high confidence
    """
    total_reviews = int(card.get("total_reviews") or 0)
    accuracy = card.get("accuracy")
    avg_confidence = card.get("avg_confidence")
    recent_wrong_streak = int(card.get("recent_wrong_streak") or 0)
    manual_difficulty = str(card.get("difficulty") or "").strip().lower()

    if total_reviews == 0:
        if manual_difficulty in {"hard", "medium", "easy"}:
            return manual_difficulty
        return "new"

    try:
        accuracy_value = float(accuracy) if accuracy is not None else None
    except Exception:
        accuracy_value = None

    try:
        confidence_value = float(avg_confidence) if avg_confidence is not None else None
    except Exception:
        confidence_value = None

    # Truly struggling cards.
    if recent_wrong_streak >= 2:
        return "hard"

    if accuracy_value is not None and accuracy_value < 0.50:
        return "hard"

    if confidence_value is not None and confidence_value <= 2.0:
        return "hard"

    # Mastered / confidence-building cards.
    if (
        total_reviews >= 2
        and recent_wrong_streak == 0
        and accuracy_value is not None
        and accuracy_value >= 0.85
        and (confidence_value is None or confidence_value >= 4.0)
    ):
        return "easy"

    # Everything else is partially learned.
    return "medium"

def _study_sort_key_for_review(card):
    # Prefer never-reviewed cards, then oldest reviewed, then lower accuracy.
    last_reviewed = card.get("last_reviewed_at")
    never_reviewed_rank = 0 if not last_reviewed else 1
    accuracy = card.get("accuracy")
    accuracy_rank = accuracy if accuracy is not None else -1
    return (
        never_reviewed_rank,
        last_reviewed or "",
        accuracy_rank,
        int(card.get("id") or 0),
    )


def _study_card_stats_for_deck(user_id: int, deck_id: int):
    _study_init_tables()

    deck = _study_deck_for_user(deck_id, user_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found.")

    with db() as conn:
        rows = conn.execute(
            """
            SELECT
                c.*,
                COUNT(DISTINCT r.id) AS total_reviews,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 1 THEN r.id END), 0) AS correct_reviews,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 0 THEN r.id END), 0) AS incorrect_reviews,
                AVG(CASE WHEN r.confidence IS NOT NULL THEN r.confidence END) AS avg_confidence,
                AVG(CASE WHEN r.response_time_ms IS NOT NULL THEN r.response_time_ms END) AS avg_response_time_ms,
                MAX(r.reviewed_at) AS last_reviewed_at,
                (
                    SELECT r2.was_correct
                    FROM study_reviews r2
                    WHERE r2.card_id = c.id
                      AND r2.user_id = c.user_id
                    ORDER BY r2.reviewed_at DESC, r2.id DESC
                    LIMIT 1
                ) AS last_was_correct
            FROM study_cards c
            LEFT JOIN study_reviews r
                ON r.card_id = c.id
               AND r.user_id = c.user_id
            WHERE c.user_id = ?
              AND c.deck_id = ?
              AND c.archived_at IS NULL
            GROUP BY c.id
            ORDER BY c.created_at ASC, c.id ASC
            """,
            (
                int(user_id),
                int(deck_id),
            ),
        ).fetchall()

        review_history_rows = conn.execute(
            """
            SELECT
                card_id,
                was_correct,
                reviewed_at,
                id
            FROM study_reviews
            WHERE user_id = ?
              AND deck_id = ?
            ORDER BY card_id ASC, reviewed_at DESC, id DESC
            """,
            (
                int(user_id),
                int(deck_id),
            ),
        ).fetchall()

    recent_by_card = {}
    for row in review_history_rows:
        card_id = int(row["card_id"])
        recent_by_card.setdefault(card_id, [])
        if len(recent_by_card[card_id]) < 10:
            recent_by_card[card_id].append(int(row["was_correct"] or 0))

    cards = []
    for row in rows:
        item = _study_card_to_public(row)

        total_reviews = int(item.get("total_reviews") or 0)
        correct_reviews = int(item.get("correct_reviews") or 0)
        incorrect_reviews = int(item.get("incorrect_reviews") or 0)

        item["total_reviews"] = total_reviews
        item["correct_reviews"] = correct_reviews
        item["incorrect_reviews"] = incorrect_reviews
        item["accuracy"] = round(correct_reviews / total_reviews, 4) if total_reviews else None

        avg_confidence = item.get("avg_confidence")
        item["avg_confidence"] = round(float(avg_confidence), 2) if avg_confidence is not None else None

        avg_response_time = item.get("avg_response_time_ms")
        item["avg_response_time_ms"] = round(float(avg_response_time), 2) if avg_response_time is not None else None

        last_was_correct = item.get("last_was_correct")
        if last_was_correct is not None:
            item["last_was_correct"] = bool(last_was_correct)

        recent = recent_by_card.get(int(item["id"]), [])
        wrong_streak = 0
        for value in recent:
            if value == 0:
                wrong_streak += 1
            else:
                break

        correct_streak = 0
        for value in recent:
            if value == 1:
                correct_streak += 1
            else:
                break

        item["recent_wrong_streak"] = wrong_streak
        item["recent_correct_streak"] = correct_streak
        item["performance_bucket"] = _study_bucket_for_card(item)

        cards.append(item)

    bucket_counts = {
        "new": sum(1 for c in cards if c.get("performance_bucket") == "new"),
        "hard": sum(1 for c in cards if c.get("performance_bucket") == "hard"),
        "medium": sum(1 for c in cards if c.get("performance_bucket") == "medium"),
        "easy": sum(1 for c in cards if c.get("performance_bucket") == "easy"),
    }

    return {
        "deck": row_to_dict(deck),
        "cards": cards,
        "bucket_counts": bucket_counts,
    }


def _study_select_review_queue(cards, mode: str, limit: int):
    mode = str(mode or "balanced").strip().lower()
    if mode not in {"balanced", "new", "hard", "medium", "easy"}:
        raise HTTPException(status_code=400, detail="mode must be balanced, new, hard, medium, or easy.")

    try:
        limit = int(limit)
    except Exception:
        limit = 10

    if limit < 1:
        limit = 1
    if limit > 50:
        limit = 50

    groups = {
        "new": [],
        "hard": [],
        "medium": [],
        "easy": [],
    }

    for card in cards:
        bucket = card.get("performance_bucket") or "new"
        groups.setdefault(bucket, []).append(card)

    for bucket in groups:
        groups[bucket].sort(key=_study_sort_key_for_review)

    selected = []

    def add_from(bucket, count):
        nonlocal selected
        for card in groups.get(bucket, []):
            if len(selected) >= limit:
                return
            if len([c for c in selected if c["id"] == card["id"]]) == 0:
                selected.append(card)
                count -= 1
                if count <= 0:
                    return

    if mode == "new":
        for bucket in ["new", "hard", "medium", "easy"]:
            add_from(bucket, limit)
        explanation = "New mode prioritizes cards that have not been reviewed yet."

    elif mode == "balanced":
        # Balanced learning favors weak/new cards, but keeps some medium/easy practice.
        hard_target = max(1, round(limit * 0.40))
        medium_target = max(1, round(limit * 0.35))
        easy_target = max(0, limit - hard_target - medium_target)

        add_from("hard", hard_target)
        add_from("new", hard_target)
        add_from("medium", medium_target)
        add_from("easy", easy_target)

        # Fill leftovers with weakest/oldest cards.
        for bucket in ["hard", "new", "medium", "easy"]:
            add_from(bucket, limit)

        explanation = "Balanced mode mixes hard/new, medium, and easy cards so the user gets challenge plus reinforcement."

    elif mode == "hard":
        for bucket in ["hard", "new", "medium", "easy"]:
            add_from(bucket, limit)
        explanation = "Hard mode prioritizes cards with low accuracy, low confidence, or recent wrong streaks."

    elif mode == "medium":
        for bucket in ["medium", "new", "hard", "easy"]:
            add_from(bucket, limit)
        explanation = "Medium mode prioritizes cards that are partially learned but not yet easy."

    else:
        for bucket in ["easy", "medium", "new", "hard"]:
            add_from(bucket, limit)
        explanation = "Easy mode prioritizes cards the user usually gets right for confidence and reinforcement."

    return {
        "mode": mode,
        "limit": limit,
        "selection_explanation": explanation,
        "count": len(selected),
        "cards": selected[:limit],
    }


@app.get("/public/study/decks/{deck_id}/card-stats")
@app.get("/api/study/decks/{deck_id}/card-stats")
async def public_study_card_stats(deck_id: int, request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)

    data = _study_card_stats_for_deck(user_id=user_id, deck_id=deck_id)

    return {
        "ok": True,
        "user_id": user_id,
        "deck": data["deck"],
        "bucket_counts": data["bucket_counts"],
        "count": len(data["cards"]),
        "cards": data["cards"],
    }


@app.get("/public/study/decks/{deck_id}/review-queue")
@app.get("/api/study/decks/{deck_id}/review-queue")
async def public_study_review_queue(deck_id: int, request: Request, mode: str = "balanced", limit: int = 10):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)

    data = _study_card_stats_for_deck(user_id=user_id, deck_id=deck_id)
    queue = _study_select_review_queue(data["cards"], mode=mode, limit=limit)

    return {
        "ok": True,
        "user_id": user_id,
        "deck": data["deck"],
        "bucket_counts": data["bucket_counts"],
        **queue,
    }


# ---------------------------------------------------------------------
# Public companion study grading foundation
# ---------------------------------------------------------------------
import re as _companion_re
import difflib as _companion_difflib


def _companion_normalize_answer(value):
    text = str(value or "").strip().lower()
    text = text.replace("^", "")
    text = text.replace("{", "").replace("}", "")
    text = text.replace(" ", "")
    text = text.replace("\\", "")
    text = text.replace("−", "-")
    text = text.replace("∞", "infinity")
    text = _companion_re.sub(r"[^a-z0-9./+\-*=()]", "", text)
    return text


def _companion_tokenize_answer(value):
    text = str(value or "").strip().lower()
    return set(_companion_re.findall(r"[a-z0-9]+", text))


def _companion_grade_answer(stored_answer, user_answer):
    stored_norm = _companion_normalize_answer(stored_answer)
    user_norm = _companion_normalize_answer(user_answer)

    if not user_norm:
        return {
            "verdict": "incorrect",
            "confidence": 1.0,
            "feedback": "No answer was provided.",
        }

    if stored_norm and user_norm == stored_norm:
        return {
            "verdict": "correct",
            "confidence": 1.0,
            "feedback": "Your answer exactly matches the stored answer.",
        }

    ratio = _companion_difflib.SequenceMatcher(None, user_norm, stored_norm).ratio()

    stored_tokens = _companion_tokenize_answer(stored_answer)
    user_tokens = _companion_tokenize_answer(user_answer)

    token_overlap = 0.0
    if stored_tokens:
        token_overlap = len(stored_tokens & user_tokens) / len(stored_tokens)

    # High similarity: record as correct.
    if ratio >= 0.88 or token_overlap >= 0.90:
        return {
            "verdict": "correct",
            "confidence": round(max(ratio, token_overlap), 4),
            "feedback": "Your answer is close enough to the stored answer to count as correct.",
        }

    # Low similarity: record as incorrect.
    if ratio <= 0.35 and token_overlap <= 0.30:
        return {
            "verdict": "incorrect",
            "confidence": round(1.0 - max(ratio, token_overlap), 4),
            "feedback": "Your answer does not appear to match the stored answer.",
        }

    # Middle area: do not write review automatically.
    return {
        "verdict": "unsure",
        "confidence": round(max(ratio, token_overlap), 4),
        "feedback": "I am not fully sure whether this should count as correct. Please confirm.",
    }


@app.post("/public/companion/study/grade")
@app.post("/api/companion/study/grade")
async def public_companion_study_grade(request: Request):
    await _require_public_api_key(request)
    user_id = _study_current_user_id(request)
    _study_init_tables()

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    card_id = payload.get("card_id") if isinstance(payload, dict) else None
    user_answer = payload.get("user_answer") if isinstance(payload, dict) else None
    response_time_ms = payload.get("response_time_ms") if isinstance(payload, dict) else None

    if card_id is None:
        raise HTTPException(status_code=400, detail="card_id is required.")

    if not isinstance(user_answer, str):
        raise HTTPException(status_code=400, detail="user_answer must be a string.")

    card = _study_card_for_user(int(card_id), user_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found.")

    grade = _companion_grade_answer(card["answer"], user_answer)

    saved_review = False
    review_data = None

    # Only auto-save when the grader is confident enough to choose correct/incorrect.
    if grade["verdict"] in {"correct", "incorrect"}:
        was_correct_int = 1 if grade["verdict"] == "correct" else 0

        try:
            response_time_int = int(response_time_ms) if response_time_ms is not None else None
        except Exception:
            response_time_int = None

        reviewed_at = datetime.now(timezone.utc).isoformat()

        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO study_reviews (
                    user_id,
                    deck_id,
                    card_id,
                    was_correct,
                    confidence,
                    response_time_ms,
                    reviewed_at,
                    notes
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    user_id,
                    int(card["deck_id"]),
                    int(card["id"]),
                    was_correct_int,
                    5 if was_correct_int else 2,
                    response_time_int,
                    reviewed_at,
                    f"Companion auto-grade: {grade['feedback']}",
                ),
            )

            review_id = cur.lastrowid

            conn.execute(
                """
                UPDATE study_decks
                SET updated_at = ?
                WHERE id = ?
                  AND user_id = ?
                """,
                (
                    reviewed_at,
                    int(card["deck_id"]),
                    user_id,
                ),
            )

            review = conn.execute(
                """
                SELECT *
                FROM study_reviews
                WHERE id = ?
                """,
                (review_id,),
            ).fetchone()

        saved_review = True
        review_data = row_to_dict(review)

    return {
        "ok": True,
        "user_id": user_id,
        "card": _study_card_to_public(card),
        "user_answer": user_answer,
        "verdict": grade["verdict"],
        "confidence": grade["confidence"],
        "feedback": grade["feedback"],
        "saved_review": saved_review,
        "review": review_data,
        "needs_user_confirmation": grade["verdict"] == "unsure",
    }


# ---------------------------------------------------------------------
# Public generic companion chat with user context
# ---------------------------------------------------------------------
def _companion_build_study_context(user_id: int):
    """
    Build a compact study context summary for the companion.
    This is read-only context. It does not modify study data.
    """
    _study_init_tables()

    with db() as conn:
        decks = conn.execute(
            """
            SELECT
                d.id,
                d.title,
                d.description,
                COUNT(DISTINCT c.id) AS card_count,
                COUNT(DISTINCT r.id) AS review_count,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 1 THEN r.id END), 0) AS correct_reviews,
                MAX(r.reviewed_at) AS last_reviewed_at
            FROM study_decks d
            LEFT JOIN study_cards c
                ON c.deck_id = d.id
               AND c.archived_at IS NULL
            LEFT JOIN study_reviews r
                ON r.deck_id = d.id
            WHERE d.user_id = ?
              AND d.archived_at IS NULL
            GROUP BY d.id
            ORDER BY d.updated_at DESC, d.id DESC
            LIMIT 12
            """,
            (int(user_id),),
        ).fetchall()

        recent_reviews = conn.execute(
            """
            SELECT
                r.id,
                r.deck_id,
                d.title AS deck_title,
                r.card_id,
                c.question,
                c.answer,
                r.was_correct,
                r.confidence,
                r.reviewed_at
            FROM study_reviews r
            JOIN study_decks d ON d.id = r.deck_id
            JOIN study_cards c ON c.id = r.card_id
            WHERE r.user_id = ?
            ORDER BY r.reviewed_at DESC, r.id DESC
            LIMIT 12
            """,
            (int(user_id),),
        ).fetchall()

        hard_cards = conn.execute(
            """
            SELECT
                c.id,
                c.deck_id,
                d.title AS deck_title,
                c.question,
                c.answer,
                c.difficulty,
                COUNT(DISTINCT r.id) AS total_reviews,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 1 THEN r.id END), 0) AS correct_reviews,
                COALESCE(COUNT(DISTINCT CASE WHEN r.was_correct = 0 THEN r.id END), 0) AS incorrect_reviews,
                MAX(r.reviewed_at) AS last_reviewed_at
            FROM study_cards c
            JOIN study_decks d ON d.id = c.deck_id
            LEFT JOIN study_reviews r
                ON r.card_id = c.id
               AND r.user_id = c.user_id
            WHERE c.user_id = ?
              AND c.archived_at IS NULL
              AND d.archived_at IS NULL
            GROUP BY c.id
            HAVING total_reviews = 0
                OR incorrect_reviews > correct_reviews
            ORDER BY incorrect_reviews DESC, total_reviews ASC, c.updated_at DESC
            LIMIT 12
            """,
            (int(user_id),),
        ).fetchall()

    deck_items = []
    for row in decks:
        item = row_to_dict(row)
        reviews = int(item.get("review_count") or 0)
        correct = int(item.get("correct_reviews") or 0)
        item["accuracy"] = round(correct / reviews, 4) if reviews else None
        deck_items.append(item)

    hard_items = []
    for row in hard_cards:
        item = row_to_dict(row)
        reviews = int(item.get("total_reviews") or 0)
        correct = int(item.get("correct_reviews") or 0)
        item["accuracy"] = round(correct / reviews, 4) if reviews else None
        hard_items.append(item)

    return {
        "decks": deck_items,
        "recent_reviews": [row_to_dict(row) for row in recent_reviews],
        "needs_attention_cards": hard_items,
    }


def _companion_build_calendar_context(user_id: int):
    """
    Placeholder for future calendar/mood/medication context.
    Keep this shape stable so the companion prompt can grow later.
    """
    return {
        "status": "calendar_not_enabled_yet",
        "events": [],
        "reminders": [],
        "mood_checkins": [],
        "medication_checkins": [],
    }


def _companion_build_context(user_id: int):
    return {
        "study": _companion_build_study_context(user_id),
        "calendar": _companion_build_calendar_context(user_id),
    }


def _companion_prompt_from_context(user_message: str, context: dict):
    context_json = json.dumps(context, ensure_ascii=False, indent=2)

    return f"""You are a helpful personal AI companion.

You can use the user's private app context below to help them.
The context may include study decks, cards, recent reviews, hard cards, and future calendar/reminder data.

Rules:
- Be friendly, concise, and useful.
- Do not claim calendar/reminder features are available unless context says they are enabled.
- If the user asks to study, use their study context to suggest what to review.
- If the user asks about progress, summarize their study progress.
- If the user asks to create or modify data, explain what you would do, but do not claim it was saved unless a backend action actually saved it.
- If unsure, ask a short follow-up question.

USER_CONTEXT_JSON:
{context_json}

USER_MESSAGE:
{user_message}
"""


@app.get("/public/companion/context")
@app.get("/api/companion/context")
async def public_companion_context(request: Request):
    await _require_public_api_key(request)
    user_row = _auth_current_user_from_request(request)
    user_id = int(user_row["id"])

    return {
        "ok": True,
        "user_id": user_id,
        "context": _companion_build_context(user_id),
    }


@app.post("/public/companion/chat")
@app.post("/api/companion/chat")
async def public_companion_chat(request: Request):
    await _require_public_api_key(request)
    user_row = _auth_current_user_from_request(request)
    user_id = int(user_row["id"])

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Request body must be JSON.")

    message = payload.get("message") if isinstance(payload, dict) else None
    requested_model = payload.get("requested_model") if isinstance(payload, dict) else None

    if not isinstance(message, str) or not message.strip():
        raise HTTPException(status_code=400, detail="message is required.")

    message = message.strip()

    if len(message) > 4000:
        raise HTTPException(status_code=400, detail="message is too long. Max characters: 4000.")

    context = _companion_build_context(user_id)
    prompt = _companion_prompt_from_context(message, context)

    job = _public_create_ollama_job(
        prompt=prompt,
        requested_model=requested_model or _public_default_model(),
        user_id=user_id,
    )

    return {
        "ok": True,
        "user_id": user_id,
        "job_id": job["id"],
        "status": job["status"],
        "poll_url": f"/public/jobs/{job['id']}",
        "message": "Companion response queued. Poll the job URL for the result.",
    }

# ============================================================
# System status dashboard endpoints
# Added for always-visible alexhartel.com wrapper/header
# ============================================================

import os as _sys_os
import json as _sys_json
import time as _sys_time
import socket as _sys_socket
import shutil as _sys_shutil
import platform as _sys_platform
import subprocess as _sys_subprocess
from datetime import datetime as _sys_datetime, timezone as _sys_timezone
from pathlib import Path as _sys_Path
from fastapi import Body as _sys_Body

_SYSTEM_STATE_DIR = _sys_Path(_sys_os.getenv("SYSTEM_STATE_DIR", ".system_state"))
_SYSTEM_STATE_DIR.mkdir(exist_ok=True)

_SYSTEM_PVESO_HOST = _sys_os.getenv("SYSTEM_PVESO_HOST", "100.88.194.19")
_SYSTEM_PVESO_SSH = _sys_os.getenv("SYSTEM_PVESO_SSH", f"root@{_SYSTEM_PVESO_HOST}")

# Your last known Wake-on-LAN values.
# You can override these in .env or shell later.
_SYSTEM_PVESO_WOL_MAC = _sys_os.getenv("SYSTEM_PVESO_WOL_MAC", "d8:bb:c1:03:fc:33")
_SYSTEM_PVESO_WOL_BROADCAST = _sys_os.getenv("SYSTEM_PVESO_WOL_BROADCAST", "192.168.0.255")

_SYSTEM_BOOTING_UNTIL_FILE = _SYSTEM_STATE_DIR / "pveso_booting_until.txt"


def _system_now_iso():
    return _sys_datetime.now(_sys_timezone.utc).isoformat()


def _system_run(cmd, timeout=5):
    try:
        r = _sys_subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=timeout,
        )
        return {
            "ok": r.returncode == 0,
            "returncode": r.returncode,
            "stdout": (r.stdout or "").strip(),
            "stderr": (r.stderr or "").strip(),
        }
    except Exception as e:
        return {
            "ok": False,
            "returncode": None,
            "stdout": "",
            "stderr": str(e),
        }


def _system_tcp_check(host, port, timeout=2):
    try:
        with _sys_socket.create_connection((host, port), timeout=timeout):
            return True
    except Exception:
        return False


def _system_http_check(url, timeout=3):
    try:
        import urllib.request
        req = urllib.request.Request(url, headers={"User-Agent": "edge-system-status/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return {
                "ok": 200 <= resp.status < 500,
                "status_code": resp.status,
                "error": None,
            }
    except Exception as e:
        return {
            "ok": False,
            "status_code": None,
            "error": str(e),
        }


def _system_ssh_check():
    return _system_run(
        [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=4",
            "-o", "StrictHostKeyChecking=accept-new",
            _SYSTEM_PVESO_SSH,
            "echo online",
        ],
        timeout=6,
    )


def _system_pct_status(ctid):
    r = _system_run(
        [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=4",
            "-o", "StrictHostKeyChecking=accept-new",
            _SYSTEM_PVESO_SSH,
            f"pct status {ctid}",
        ],
        timeout=8,
    )

    if not r["ok"]:
        return {
            "state": "error",
            "detail": r["stderr"] or r["stdout"] or "pct status failed",
        }

    out = r["stdout"].lower()

    if "status: running" in out:
        return {
            "state": "online",
            "detail": r["stdout"],
        }

    if "status: stopped" in out:
        return {
            "state": "offline",
            "detail": r["stdout"],
        }

    return {
        "state": "unknown",
        "detail": r["stdout"],
    }


def _system_read_booting_marker():
    try:
        until = float(_SYSTEM_BOOTING_UNTIL_FILE.read_text().strip())
        remaining = int(until - _sys_time.time())

        if remaining > 0:
            return {
                "active": True,
                "remaining_seconds": remaining,
                "until_epoch": until,
            }
    except Exception:
        pass

    return {
        "active": False,
        "remaining_seconds": 0,
        "until_epoch": None,
    }


def _system_mark_booting(seconds=600):
    until = _sys_time.time() + seconds
    _SYSTEM_BOOTING_UNTIL_FILE.write_text(str(until))
    return until


def _system_laptop_specs():
    cpu_name = _sys_platform.processor() or "unknown"
    machine = _sys_platform.machine()
    system = _sys_platform.system()
    release = _sys_platform.release()

    nproc = _system_run(["bash", "-lc", "nproc"], timeout=2)
    ram = _system_run(["bash", "-lc", "free -h | awk '/Mem:/ {print $2}'"], timeout=2)
    disk = _system_run(["bash", "-lc", "df -h / | awk 'NR==2 {print $2}'"], timeout=2)

    return {
        "cpu": cpu_name,
        "machine": machine,
        "os": f"{system} {release}",
        "cores": nproc["stdout"] if nproc["ok"] else "unknown",
        "ram": ram["stdout"] if ram["ok"] else "unknown",
        "root_disk": disk["stdout"] if disk["ok"] else "unknown",
    }



def _system_systemd_unit_facts(unit_name):
    active_result = _system_run(["systemctl", "is-active", unit_name], timeout=2)
    enabled_result = _system_run(["systemctl", "is-enabled", unit_name], timeout=2)

    return {
        "unit": unit_name,
        "active": (active_result.get("stdout") or "").strip() or "unknown",
        "enabled": (enabled_result.get("stdout") or "").strip() or "unknown",
    }


def _system_frontend_wrapper_status(checked_at):
    facts = _system_systemd_unit_facts("edge-wrapper-ui.service")
    active = facts.get("active") or "unknown"
    enabled = facts.get("enabled") or "unknown"

    if active == "active":
        state = "online"
    elif active in {"activating", "reloading"}:
        state = "booting"
    elif active in {"failed", "inactive"}:
        state = "offline"
    else:
        state = "unknown"

    return {
        "id": "frontend-wrapper",
        "name": "Frontend Wrapper",
        "state": state,
        "checked_at": checked_at,
        "detail": f"edge-wrapper-ui.service active: {active}, enabled: {enabled}",
        "service_active": active == "active",
        "service_enabled": enabled,
    }


def _system_queue_status_from_worker(checked_at, worker_service):
    queue = worker_service.get("queue") if isinstance(worker_service, dict) else {}
    worker_state = worker_service.get("state") if isinstance(worker_service, dict) else "unknown"

    if worker_state == "online":
        state = "online"
    elif worker_state in {"paused", "degraded", "booting"}:
        state = "degraded"
    elif worker_state == "offline":
        state = "offline"
    else:
        state = "unknown"

    return {
        "id": "queue",
        "name": "Queue",
        "state": state,
        "checked_at": checked_at,
        "detail": (
            f"queued {queue.get('queued', 0)}, "
            f"running {queue.get('running', 0)}, "
            f"complete {queue.get('complete', 0)}, "
            f"failed {queue.get('failed', 0)}"
        ),
        "queue": queue,
    }


def _system_power_automation_status(checked_at):
    power_auto = _system_systemd_unit_facts("edge-queue-power-auto-tick.timer")
    remediation = _system_systemd_unit_facts("edge-queue-remediation-tick.timer")
    legacy = _system_systemd_unit_facts("edge-queue-scheduler-tick.timer")

    power_auto_active = power_auto.get("active") == "active"
    remediation_active = remediation.get("active") == "active"
    legacy_active = legacy.get("active") == "active"
    legacy_enabled = legacy.get("enabled") == "enabled"

    if power_auto_active and remediation_active and legacy_active:
        state = "online"
        detail_prefix = "All power/scheduler timers are active."
    elif power_auto_active and remediation_active and not legacy_active and not legacy_enabled:
        state = "degraded"
        detail_prefix = "Modern power/remediation timers are active; legacy /tick scheduler is intentionally disabled until controlled restart."
    elif power_auto_active or remediation_active:
        state = "degraded"
        detail_prefix = "Some power automation timers are active."
    else:
        state = "offline"
        detail_prefix = "Power automation timers are not active."

    return {
        "id": "power-automation",
        "name": "Power Automation",
        "state": state,
        "checked_at": checked_at,
        "detail": (
            f"{detail_prefix} "
            f"power-auto: {power_auto.get('active')}/{power_auto.get('enabled')}, "
            f"remediation: {remediation.get('active')}/{remediation.get('enabled')}, "
            f"legacy-scheduler: {legacy.get('active')}/{legacy.get('enabled')}"
        ),
        "timers": {
            "edge-queue-power-auto-tick.timer": power_auto,
            "edge-queue-remediation-tick.timer": remediation,
            "edge-queue-scheduler-tick.timer": legacy,
        },
    }


def _system_status_normalized_block(nodes, services):
    node_by_id = {
        node.get("id"): node
        for node in nodes
        if isinstance(node, dict)
    }
    service_by_id = {
        service.get("id"): service
        for service in services
        if isinstance(service, dict)
    }

    def node_state(node_id, fallback="unknown"):
        node = node_by_id.get(node_id)
        if not node:
            return fallback
        return node.get("state") or fallback

    def service_state(service_id, fallback="unknown"):
        service = service_by_id.get(service_id)
        if not service:
            return fallback
        return service.get("state") or fallback

    def master_api_state():
        master = node_by_id.get("master-laptop")
        if not isinstance(master, dict):
            return service_state("backend-api")

        for service in master.get("services") or []:
            if not isinstance(service, dict):
                continue
            if service.get("name") == "edge-queue-controller":
                return service.get("state") or "unknown"

        return service_state("backend-api")

    return {
        "schema_version": 1,
        "infrastructure": [
            {
                "id": "controller-node",
                "name": "Controller Node",
                "state": node_state("master-laptop"),
                "members": ["master-laptop"],
            },
            {
                "id": "server-nodes",
                "name": "Server Nodes",
                "state": node_state("pveso"),
                "members": ["pveso"],
            },
            {
                "id": "cpu-nodes",
                "name": "CPU Nodes",
                "state": node_state("ct-101"),
                "members": ["ct-101"],
            },
            {
                "id": "gpu-nodes",
                "name": "GPU Nodes",
                "state": "planned",
                "members": [],
            },
            {
                "id": "storage-nodes",
                "name": "Storage Nodes",
                "state": "planned",
                "members": [],
            },
        ],
        "platform": [
            {
                "id": "backend-api",
                "name": "Backend API",
                "state": master_api_state(),
            },
            {
                "id": "frontend-wrapper",
                "name": "Frontend Wrapper",
                "state": service_state("frontend-wrapper"),
            },
            {
                "id": "queue",
                "name": "Queue",
                "state": service_state("queue"),
            },
            {
                "id": "workers",
                "name": "Workers",
                "state": node_state("ct-101"),
            },
            {
                "id": "ct101-laptop-queue-worker",
                "name": "CT101 Laptop Queue Worker",
                "state": service_state("ct101-laptop-queue-worker"),
                # STAGE_5G26_NORMALIZED_WORKER_DETAIL_FIELD_V1
                "detail": next(
                    (
                        service.get("detail")
                        for service in services
                        if service.get("id") == "ct101-laptop-queue-worker"
                    ),
                    "Managed CT101 worker processing queued chat jobs.",
                ),
            },
            {
                "id": "power-automation",
                "name": "Power Automation",
                "state": service_state("power-automation"),
            },
        ],
    }


# STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1
def _system_queue_depth_summary():
    summary = {
        "queued": 0,
        "running": 0,
        "complete": 0,
        "failed": 0,
        "other": 0,
    }

    try:
        from edge_modules.chat_queue_persistence import _psql_at
        rows = _psql_at("SELECT status || E'\\t' || COUNT(*)::text FROM app_jobs WHERE job_type = 'ollama_chat' GROUP BY status ORDER BY status;").strip()
        for line in rows.splitlines():
            parts = line.split("\t")
            if len(parts) != 2:
                continue
            status, count_text = parts
            try:
                count = int(count_text)
            except Exception:
                count = 0
            if status in summary:
                summary[status] = count
            else:
                summary["other"] += count
    except Exception as exc:
        summary["error"] = str(exc)

    return summary


def _system_ct101_laptop_queue_worker_status(checked_at, *, pveso_state, ct101_state):
    queue_summary = _system_queue_depth_summary()
    base = {
        "id": "ct101-laptop-queue-worker",
        "name": "CT101 Laptop Queue Worker",
        "state": "unknown",
        "checked_at": checked_at,
        "detail": "Managed worker status has not been checked yet.",
        "queue": queue_summary,
    }

    if pveso_state != "online":
        base.update({
            "state": pveso_state or "offline",
            "detail": "Main Proxmox server is not online.",
            "service_active": False,
            "paused": None,
            "preflight_ok": False,
        })
        return base

    if ct101_state != "online":
        base.update({
            "state": ct101_state or "offline",
            "detail": "CT101 container is not online.",
            "service_active": False,
            "paused": None,
            "preflight_ok": False,
        })
        return base

    remote_script = r'''
set -u
SERVICE="ai-platform-laptop-queue-worker.service"
ENV_FILE="/etc/ai-platform/laptop-queue-worker.env"
PAUSE_FILE="/etc/ai-platform/laptop-queue-worker.paused"
PREFLIGHT="/opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh"

service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)"

if [ -f "$PAUSE_FILE" ]; then paused="yes"; else paused="no"; fi

worker_id=""
worker_node_id=""
model=""
max_jobs=""
real_user_jobs=""
synthetic_only=""
base_url=""
ollama_url=""

if [ -f "$ENV_FILE" ]; then
  worker_id="$(awk -F= '$1=="LAPTOP_QUEUE_WORKER_ID"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  worker_node_id="$(awk -F= '$1=="LAPTOP_QUEUE_WORKER_NODE_ID"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  model="$(awk -F= '$1=="LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  max_jobs="$(awk -F= '$1=="LAPTOP_QUEUE_MAX_JOBS_PER_RUN"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  real_user_jobs="$(awk -F= '$1=="LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  synthetic_only="$(awk -F= '$1=="LAPTOP_QUEUE_SYNTHETIC_ONLY"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  base_url="$(awk -F= '$1=="LAPTOP_QUEUE_BASE_URL"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
  ollama_url="$(awk -F= '$1=="LAPTOP_QUEUE_OLLAMA_BASE_URL"{print substr($0, index($0, "=")+1); exit}' "$ENV_FILE")"
fi

preflight_ok="no"
if [ -x "$PREFLIGHT" ]; then
  if "$PREFLIGHT" >/tmp/stage5g24-worker-preflight.out 2>/tmp/stage5g24-worker-preflight.err; then
    preflight_ok="yes"
  fi
fi

last_log="$(journalctl -u "$SERVICE" --no-pager -n 1 2>/dev/null | sed 's/[[:cntrl:]]//g' | tail -n 1 || true)"

printf 'service_active=%s\n' "$service_active"
printf 'service_enabled=%s\n' "$service_enabled"
printf 'paused=%s\n' "$paused"
printf 'worker_id=%s\n' "$worker_id"
printf 'worker_node_id=%s\n' "$worker_node_id"
printf 'model=%s\n' "$model"
printf 'max_jobs=%s\n' "$max_jobs"
printf 'real_user_jobs=%s\n' "$real_user_jobs"
printf 'synthetic_only=%s\n' "$synthetic_only"
printf 'base_url_set=%s\n' "$([ -n "$base_url" ] && echo yes || echo no)"
printf 'ollama_url_set=%s\n' "$([ -n "$ollama_url" ] && echo yes || echo no)"
printf 'preflight_ok=%s\n' "$preflight_ok"
printf 'last_log=%s\n' "$last_log"
'''

    try:
        proc = subprocess.run(
            [
                "ssh",
                f"root@{_SYSTEM_PVESO_HOST}",
                "pct",
                "exec",
                "101",
                "--",
                "bash",
                "-s",
            ],
            input=remote_script,
            text=True,
            capture_output=True,
            timeout=18,
        )

        facts = {}
        for line in (proc.stdout or '').splitlines():
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            facts[k.strip()] = v.strip()

        if proc.returncode != 0:
            base.update({
                "state": "degraded",
                "detail": "Managed worker status command failed.",
                "service_active": False,
                "paused": None,
                "preflight_ok": False,
                "error": (proc.stderr or "").strip()[:240],
            })
            return base

        service_active = facts.get("service_active") == "active"
        paused = facts.get("paused") == "yes"
        preflight_ok = facts.get("preflight_ok") == "yes"

        if service_active and preflight_ok and not paused:
            state = "online"
        elif service_active and paused:
            state = "paused"
        elif service_active and not preflight_ok:
            state = "degraded"
        else:
            state = "offline"

        detail_parts = [
            f"service: {facts.get('service_active') or 'unknown'}",
            f"preflight: {'ok' if preflight_ok else 'failed'}",
            f"paused: {'yes' if paused else 'no'}",
        ]

        if facts.get("model"):
            detail_parts.append(f"model: {facts.get('model')}")
        if facts.get("max_jobs"):
            detail_parts.append(f"max jobs/run: {facts.get('max_jobs')}")

        # STAGE_5G26_NORMALIZED_WORKER_DETAIL_QUEUE_SUMMARY_V1
        # Keep the normalized UI detail useful without exposing prompts,
        # tokens, raw environment values, or user message contents.
        detail_parts.append(
            "queue: "
            f"queued {queue_summary.get('queued', 0)}, "
            f"running {queue_summary.get('running', 0)}, "
            f"failed {queue_summary.get('failed', 0)}"
        )

        max_jobs_value = None
        if str(facts.get("max_jobs") or "").isdigit():
            max_jobs_value = int(facts.get("max_jobs"))

        base.update({
            "state": state,
            "detail": ", ".join(detail_parts),
            "service_active": service_active,
            "service_enabled": facts.get("service_enabled") or "unknown",
            "paused": paused,
            "preflight_ok": preflight_ok,
            "worker_id": facts.get("worker_id") or None,
            "worker_node_id": facts.get("worker_node_id") or None,
            "model": facts.get("model") or None,
            "max_jobs_per_run": max_jobs_value,
            "real_user_jobs_enabled": facts.get("real_user_jobs") == "1",
            "synthetic_only": facts.get("synthetic_only") == "1",
            "base_url_set": facts.get("base_url_set") == "yes",
            "ollama_url_set": facts.get("ollama_url_set") == "yes",
            "last_log": facts.get("last_log") or None,
        })
        return base

    except Exception as exc:
        base.update({
            "state": "degraded",
            "detail": "Managed worker status check failed.",
            "service_active": False,
            "paused": None,
            "preflight_ok": False,
            "error": str(exc),
        })
        return base

@app.get("/system/local-health")
def system_local_health():
    return {
        "ok": True,
        "service": "edge-queue-controller",
        "detail": "Local controller process is responding.",
    }


@app.get("/system/status")
def system_status():
    """
    Public-safe status summary for the always-visible site wrapper.

    This should expose friendly status only.
    Do not expose passwords, tokens, SSH keys, or sensitive internal details.
    """

    checked_at = _system_now_iso()
    booting_marker = _system_read_booting_marker()

    # Master laptop is this process.
    master_node = {
        "id": "master-laptop",
        "name": "Controller Node",
        "role": "master",
        "state": "online",
        "checked_at": checked_at,
        "specs": _system_laptop_specs(),
        "services": [
            {
                "name": "edge-queue-controller",
                "state": "online",
                "detail": "This API process is responding.",
            }
        ],
    }

    # Check pveso.
    pveso_tcp_ssh = _system_tcp_check(_SYSTEM_PVESO_HOST, 22, timeout=2)
    pveso_ssh = _system_ssh_check() if pveso_tcp_ssh else {
        "ok": False,
        "stdout": "",
        "stderr": "SSH port unreachable",
    }

    if pveso_ssh["ok"]:
        pveso_state = "online"
        pveso_detail = "SSH reachable."
    elif booting_marker["active"]:
        pveso_state = "booting"
        pveso_detail = f"Boot marker active. About {booting_marker['remaining_seconds']} seconds remaining."
    else:
        pveso_state = "offline"
        pveso_detail = pveso_ssh["stderr"] or "Server unreachable."

    pveso_node = {
        "id": "pveso",
        "name": "Main Proxmox Server",
        "role": "compute-host",
        "state": pveso_state,
        "checked_at": checked_at,
        "address": _SYSTEM_PVESO_HOST,
        "detail": pveso_detail,
        "specs": {
            "cpu": "Intel Core i9-10900K",
            "gpu": "AMD RX 6900 XT",
            "hypervisor": "Proxmox VE",
        },
    }

    workers = []

    if pveso_state == "online":
        ct101 = _system_pct_status("101")
    elif pveso_state == "booting":
        ct101 = {"state": "booting", "detail": "Waiting for pveso to finish booting."}
    else:
        ct101 = {"state": "offline", "detail": "pveso is offline."}

    workers.append({
        "id": "ct-101",
        "name": "LLM Worker",
        "role": "container",
        "state": ct101["state"],
        "checked_at": checked_at,
        "detail": ct101["detail"],
        "services": ["Ollama", "AI Platform API", "TTS", "Whisper"],
    })

    # Service checks.
    # These are intentionally friendly/high-level.
    services = []

    # The Study API lives in this same controller, but the frontend may access it
    # through /api/backend/... while the direct FastAPI path may be different.
    # Try several safe candidates and mark it online if any respond.
    study_candidates = [
        "http://127.0.0.1:7070/system/local-health",
        "http://127.0.0.1:7070/health",
        "http://127.0.0.1:7070/public/study/progress",
        "http://127.0.0.1:7070/public/study/decks",
    ]

    study_check = None
    study_url_used = None

    for url in study_candidates:
        c = _system_http_check(url, timeout=2)
        if c["ok"]:
            study_check = c
            study_url_used = url
            break
        if study_check is None:
            study_check = c
            study_url_used = url

    services.append({
        "id": "study-api",
        "name": "Study API",
        "state": "online" if study_check and study_check["ok"] else "degraded",
        "checked_at": checked_at,
        "detail": (
            f"HTTP {study_check['status_code']} via {study_url_used}"
            if study_check and study_check["ok"]
            else f"Study route not confirmed. Last check: {study_check['error'] if study_check else 'unknown'}"
        ),
    })

    ct101_worker_service = _system_ct101_laptop_queue_worker_status(
        checked_at,
        pveso_state=pveso_state,
        ct101_state=ct101["state"],
    )
    services.append(ct101_worker_service)

    # Stage 7X-6: provide public-safe service records for normalized platform
    # cards so the System UI does not fall back to unknown placeholders.
    services.append(_system_frontend_wrapper_status(checked_at))
    services.append(_system_queue_status_from_worker(checked_at, ct101_worker_service))
    services.append(_system_power_automation_status(checked_at))

    # These services depend on pveso. If pveso is offline, skip public-domain checks
    # so DNS/proxy failures do not make the entire system look broken.
    all_items = [master_node, pveso_node] + workers + services
    states = [item.get("state") for item in all_items]

    critical_states = {
        "master": master_node.get("state"),
        "pveso": pveso_node.get("state"),
    }

    if critical_states["master"] == "error":
        overall_state = "error"
    elif pveso_state == "booting" or any(s == "booting" for s in states):
        overall_state = "booting"
    elif pveso_state == "offline" or any(s in ("offline", "degraded", "error") for s in states):
        overall_state = "degraded"
    else:
        overall_state = "online"

    nodes = [
        master_node,
        pveso_node,
        *workers,
    ]

    return {
        "ok": True,
        "checked_at": checked_at,
        "overall_state": overall_state,
        "nodes": nodes,
        "services": services,
        "normalized": _system_status_normalized_block(nodes, services),
    }


@app.post("/system/pveso/boot")
def system_boot_pveso(payload: dict = _sys_Body(default={})):
    """
    Sends Wake-on-LAN for pveso and marks the node as booting.

    Safety:
    - Keep this behind your authenticated dashboard / Cloudflare Access.
    - Do not expose this publicly without auth.
    """

    confirm = payload.get("confirm") if isinstance(payload, dict) else None
    required = "BOOT_PVESO"

    if confirm != required:
        return {
            "ok": False,
            "boot_sent": False,
            "blocked_reason": "Missing confirmation phrase.",
            "required_confirm": required,
            "example_body": {"confirm": required},
        }

    if not _SYSTEM_PVESO_WOL_MAC:
        return {
            "ok": False,
            "boot_sent": False,
            "error": "SYSTEM_PVESO_WOL_MAC is not configured.",
        }

    wakeonlan = _sys_shutil.which("wakeonlan")
    etherwake = _sys_shutil.which("etherwake")

    if wakeonlan:
        cmd = [
            wakeonlan,
            "-i",
            _SYSTEM_PVESO_WOL_BROADCAST,
            _SYSTEM_PVESO_WOL_MAC,
        ]
    elif etherwake:
        cmd = [
            etherwake,
            _SYSTEM_PVESO_WOL_MAC,
        ]
    else:
        return {
            "ok": False,
            "boot_sent": False,
            "error": "Neither wakeonlan nor etherwake is installed.",
            "install_hint": "sudo apt install wakeonlan",
        }

    result = _system_run(cmd, timeout=8)

    if result["ok"]:
        until = _system_mark_booting(seconds=600)
        return {
            "ok": True,
            "boot_sent": True,
            "state": "booting",
            "booting_until_epoch": until,
            "detail": result["stdout"] or "Wake-on-LAN packet sent.",
        }

    return {
        "ok": False,
        "boot_sent": False,
        "error": result["stderr"] or result["stdout"] or "Wake-on-LAN failed.",
    }


# ============================================================
# Internal system session identity endpoint
# Used by public_gateway.py to determine whether a logged-in user is admin.
# Requires valid Bearer session token but does not require the public API key.
# ============================================================



# STAGE_5P11T_SESSION_ME_PRESENCE_TOUCH_BEGIN
def _stage5p11t_touch_authenticated_web_presence_from_session_me(request: Request, user_row):
    """
    /system/session/me is already called by the logged-in browser.

    Use it as the reliable authenticated presence heartbeat so power automation
    can keep pveso + CT101 online for logged-in users even when there are no
    queued jobs.
    """
    if not user_row:
        return {
            "ok": False,
            "reason": "missing_user_row",
        }

    try:
        _web_presence_init_tables()

        user_id = int(user_row["id"])
        role = str(user_row["role"] if "role" in user_row.keys() else "").strip().lower()
        is_admin = 1 if role == "admin" else 0

        now = _web_presence_now()
        route = request.headers.get("x-ah-route") or request.headers.get("referer") or "/session/me"
        route = str(route or "/session/me")[:250]

        visibility = request.headers.get("x-ah-visibility") or "visible"
        visibility = str(visibility or "visible")[:50]

        # One row per authenticated user is enough for power policy.
        visitor_id = f"session-me-user-{user_id}"

        user_agent = request.headers.get("user-agent", "")
        xff = request.headers.get("x-forwarded-for", "")
        client_host = getattr(request.client, "host", "") if request.client else ""

        user_agent_hash = _web_presence_hash(user_agent)
        ip_hash = _web_presence_hash(xff or client_host)

        metadata = {
            "reason": "session-me-authenticated-touch",
            "logged_in": True,
            "source": "/system/session/me",
        }

        with sqlite3.connect(DB_PATH) as conn:
            conn.execute(
                """
                INSERT INTO web_presence (
                    visitor_id,
                    user_id,
                    route,
                    is_authenticated,
                    is_admin,
                    active_seconds,
                    visibility,
                    first_seen_at,
                    last_seen_at,
                    user_agent_hash,
                    ip_hash,
                    metadata_json
                )
                VALUES (?, ?, ?, 1, ?, 20, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(visitor_id) DO UPDATE SET
                    user_id = excluded.user_id,
                    route = excluded.route,
                    is_authenticated = 1,
                    is_admin = excluded.is_admin,
                    active_seconds = MAX(web_presence.active_seconds, excluded.active_seconds),
                    visibility = excluded.visibility,
                    last_seen_at = excluded.last_seen_at,
                    user_agent_hash = excluded.user_agent_hash,
                    ip_hash = excluded.ip_hash,
                    metadata_json = excluded.metadata_json
                """,
                (
                    visitor_id,
                    user_id,
                    route,
                    is_admin,
                    visibility,
                    now,
                    now,
                    user_agent_hash,
                    ip_hash,
                    json.dumps(metadata),
                ),
            )
            conn.commit()

        return {
            "ok": True,
            "visitor_id": visitor_id,
            "user_id": user_id,
            "is_admin": bool(is_admin),
            "seen_at": now,
        }
    except Exception as e:
        return {
            "ok": False,
            "reason": "presence_touch_failed",
            "error": str(e),
        }
# STAGE_5P11T_SESSION_ME_PRESENCE_TOUCH_END


@app.get("/system/session/me")
async def system_session_me(request: Request):
    _account_init_tables()
    user_row = _auth_current_user_from_request(request)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (user_row["id"],),
        ).fetchone()

    # STAGE_5P11T_SESSION_ME_PRESENCE_CALL_BEGIN
    presence_touch = _stage5p11t_touch_authenticated_web_presence_from_session_me(request, row)
    # STAGE_5P11T_SESSION_ME_PRESENCE_CALL_END

    return {
        "ok": True,
        "user": _account_enriched_public_user(row),
        "presence_touch": presence_touch,
    }


# ============================================================
# Internal system session auth endpoints
# Local/dev trusted endpoints used by wrapper-ui local proxy.
# These do NOT require EDGE_PUBLIC_API_KEY.
# Do NOT expose these directly through the public gateway.
# ============================================================

@app.post("/system/session/login")
async def system_session_login(request: Request):
    _auth_init_tables()

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    email = _auth_normalize_email(payload.get("email") if isinstance(payload, dict) else "")
    password = payload.get("password") if isinstance(payload, dict) else ""

    if not email or not isinstance(password, str):
        raise HTTPException(status_code=400, detail="Email and password are required.")

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE email = ?
            """,
            (email,),
        ).fetchone()

        if not row:
            if _auth_pending_signup_exists(email):
                raise HTTPException(status_code=403, detail="Email verification required. Check your email to finish creating your account.")
            raise HTTPException(status_code=401, detail="Invalid email or password.")

        if not _auth_verify_password(password, row["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid email or password.")

        now = _auth_now_iso()
        conn.execute(
            """
            UPDATE app_users
            SET last_login_at = ?, updated_at = ?
            WHERE id = ?
            """,
            (now, now, row["id"]),
        )
        conn.commit()

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


@app.post("/system/session/register")
async def system_session_register(request: Request):
    _auth_init_tables()

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    email = _auth_normalize_email(payload.get("email") or "")
    password = str(payload.get("password") or "")
    display_name = str(payload.get("display_name") or "").strip() or None

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required.")

    if len(password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters.")

    password_hash = _auth_hash_password(password)
    _, _, delivery = _auth_create_or_update_pending_signup(email, password_hash, display_name)

    return _auth_pending_signup_response(email, delivery)




@app.post("/system/session/logout")
async def system_session_logout(request: Request):
    token = _auth_get_bearer_token(request)

    if not token:
        return {"ok": True, "logged_out": False}

    token_hash = _auth_hash_token(token)
    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            UPDATE user_sessions
            SET revoked_at = ?, updated_at = ?
            WHERE token_hash = ?
              AND revoked_at IS NULL
            """,
            (now, now, token_hash),
        )
        conn.commit()

    return {"ok": True, "logged_out": True}


# ============================================================
# Account roles, plans, credits, and quotas
# Foundation for admin access, billing, free credits, monthly passes.
# ============================================================

def _account_column_exists(conn, table: str, column: str) -> bool:
    rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
    return any(row[1] == column for row in rows)


def _account_add_column_if_missing(conn, table: str, column: str, ddl: str):
    if not _account_column_exists(conn, table, column):
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {ddl}")


def _account_init_tables():
    _auth_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        _account_add_column_if_missing(conn, "app_users", "role", "role TEXT NOT NULL DEFAULT 'user'")
        _account_add_column_if_missing(conn, "app_users", "plan", "plan TEXT NOT NULL DEFAULT 'free'")
        _account_add_column_if_missing(conn, "app_users", "billing_status", "billing_status TEXT NOT NULL DEFAULT 'none'")
        _account_add_column_if_missing(conn, "app_users", "credit_balance", "credit_balance INTEGER NOT NULL DEFAULT 100")
        _account_add_column_if_missing(conn, "app_users", "monthly_credit_allowance", "monthly_credit_allowance INTEGER NOT NULL DEFAULT 100")
        _account_add_column_if_missing(conn, "app_users", "storage_quota_mb", "storage_quota_mb INTEGER NOT NULL DEFAULT 100")
        _account_add_column_if_missing(conn, "app_users", "monthly_pass_expires_at", "monthly_pass_expires_at TEXT")

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_credit_ledger (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                delta INTEGER NOT NULL,
                reason TEXT NOT NULL,
                metadata_json TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS user_usage_limits (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                usage_type TEXT NOT NULL,
                period_start TEXT NOT NULL,
                period_end TEXT NOT NULL,
                used_amount INTEGER NOT NULL DEFAULT 0,
                limit_amount INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                UNIQUE(user_id, usage_type, period_start, period_end),
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.commit()


def _account_admin_email_set():
    return {
        item.strip().lower()
        for item in os.getenv("ADMIN_EMAILS", "").split(",")
        if item.strip()
    }


def _account_enriched_public_user(row):
    base = _auth_public_user(row)

    role = str(row["role"] if "role" in row.keys() and row["role"] else "user").lower()
    email = str(base.get("email") or "").lower()

    # Bootstrap fallback: ADMIN_EMAILS can still mark an account admin,
    # but the database role is the long-term source of truth.
    is_bootstrap_admin = email in _account_admin_email_set()
    is_admin = role == "admin" or is_bootstrap_admin

    if is_bootstrap_admin and role != "admin":
        role = "admin"

    base.update({
        "role": role,
        "is_admin": bool(is_admin),
        "plan": row["plan"] if "plan" in row.keys() else "free",
        "billing_status": row["billing_status"] if "billing_status" in row.keys() else "none",
        "credit_balance": int(row["credit_balance"] if "credit_balance" in row.keys() and row["credit_balance"] is not None else 0),
        "monthly_credit_allowance": int(row["monthly_credit_allowance"] if "monthly_credit_allowance" in row.keys() and row["monthly_credit_allowance"] is not None else 0),
        "storage_quota_mb": int(row["storage_quota_mb"] if "storage_quota_mb" in row.keys() and row["storage_quota_mb"] is not None else 0),
        "monthly_pass_expires_at": row["monthly_pass_expires_at"] if "monthly_pass_expires_at" in row.keys() else None,
    })

    return base


@app.post("/system/account/bootstrap-admin")
async def system_account_bootstrap_admin(request: Request):
    """
    Promote the current logged-in account to admin if its email is listed in ADMIN_EMAILS.
    This is a bootstrap endpoint for the platform owner.
    """
    _account_init_tables()

    user_row = _auth_current_user_from_request(request)
    email = str(user_row["email"]).strip().lower()

    if email not in _account_admin_email_set():
        raise HTTPException(status_code=403, detail="This account is not listed in ADMIN_EMAILS.")

    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute(
            """
            UPDATE app_users
            SET role = 'admin',
                plan = CASE WHEN plan = 'free' THEN 'pro' ELSE plan END,
                billing_status = CASE WHEN billing_status = 'none' THEN 'active' ELSE billing_status END,
                credit_balance = MAX(credit_balance, 10000),
                monthly_credit_allowance = MAX(monthly_credit_allowance, 10000),
                storage_quota_mb = MAX(storage_quota_mb, 10240),
                updated_at = ?
            WHERE id = ?
            """,
            (now, user_row["id"]),
        )
        conn.commit()

        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (user_row["id"],),
        ).fetchone()

    return {
        "ok": True,
        "user": _account_enriched_public_user(row),
    }


@app.get("/system/account/me")
async def system_account_me(request: Request):
    _account_init_tables()
    user_row = _auth_current_user_from_request(request)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (user_row["id"],),
        ).fetchone()

    return {
        "ok": True,
        "user": _account_enriched_public_user(row),
    }


# ============================================================
# Credit accounting engine
# Safe foundation for GPU sessions, cloud storage, RAG, billing, and paid usage.
# ============================================================

import json as _credit_json
import secrets as _credit_secrets
from edge_modules.credits import (
    credit_pool_active_reserved_totals as _credit_pool_active_reserved_totals_impl,
    credit_pool_add_ledger as _credit_pool_add_ledger_impl,
    credit_pool_find_reservation as _credit_pool_find_reservation_impl,
    credit_pool_grant_free_to_email as _credit_pool_grant_free_to_email_impl,
    credit_pool_grant_free_to_user_on_conn as _credit_pool_grant_free_to_user_on_conn_impl,
    credit_pool_grant_paid_to_email as _credit_pool_grant_paid_to_email_impl,
    credit_pool_sync_legacy_total as _credit_pool_sync_legacy_total_impl,
)
from edge_modules.credit_helpers import (
    ad_hash as _ad_hash,
    ad_iso_to_epoch as _ad_iso_to_epoch,
    credit_json_dumps as _credit_json_dumps,
    credit_pool_debit_plan as _credit_pool_debit_plan,
    parse_payload_amount as _credit_parse_payload_amount,
)
from edge_modules.rewarded_ads import (
    ad_request_ip as _ad_request_ip,
    ad_reward_claim_for_user as _ad_reward_claim_for_user,
    ad_reward_counts as _ad_reward_counts,
    ad_reward_init_tables as _rewarded_ad_init_tables_impl,
    ad_reward_settings as _ad_reward_settings,
    ad_reward_status_for_user as _ad_reward_status_for_user,
)


def _credit_init_tables():
    _account_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS credit_reservations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                reservation_token TEXT NOT NULL UNIQUE,
                amount INTEGER NOT NULL,
                reason TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'reserved',
                metadata_json TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                expires_at TEXT,
                committed_at TEXT,
                refunded_at TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.commit()


def _credit_get_user_row(request: Request):
    _credit_init_tables()
    auth_row = _auth_current_user_from_request(request)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (auth_row["id"],),
        ).fetchone()

    if not row:
        raise HTTPException(status_code=401, detail="User not found.")

    return row


def _credit_require_admin(request: Request):
    row = _credit_get_user_row(request)
    user = _account_enriched_public_user(row)

    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="Admin access required.")

    return row




def _credit_get_active_reserved_total(conn, user_id: int) -> int:
    row = conn.execute(
        """
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM credit_reservations
        WHERE user_id = ?
          AND status = 'reserved'
        """,
        (user_id,),
    ).fetchone()

    return int(row["total"] if row and row["total"] is not None else 0)


def _credit_add_ledger(conn, user_id: int, delta: int, reason: str, metadata=None):
    now = _auth_now_iso()

    conn.execute(
        """
        INSERT INTO user_credit_ledger (
            user_id,
            delta,
            reason,
            metadata_json,
            created_at
        )
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            user_id,
            int(delta),
            str(reason),
            _credit_json_dumps(metadata),
            now,
        ),
    )


def _credit_public_summary_for_user(user_id: int):
    _credit_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="User not found.")

        reserved_total = _credit_get_active_reserved_total(conn, user_id)

        reservations = conn.execute(
            """
            SELECT
                id,
                reservation_token,
                amount,
                reason,
                status,
                metadata_json,
                created_at,
                updated_at,
                expires_at,
                committed_at,
                refunded_at
            FROM credit_reservations
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 20
            """,
            (user_id,),
        ).fetchall()

        ledger = conn.execute(
            """
            SELECT
                id,
                delta,
                reason,
                metadata_json,
                created_at
            FROM user_credit_ledger
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 50
            """,
            (user_id,),
        ).fetchall()

    user = _account_enriched_public_user(row)

    return {
        "ok": True,
        "user": user,
        "credits": {
            "available": int(user.get("credit_balance") or 0),
            "reserved": int(reserved_total),
            "monthly_allowance": int(user.get("monthly_credit_allowance") or 0),
            "plan": user.get("plan"),
            "billing_status": user.get("billing_status"),
            "storage_quota_mb": int(user.get("storage_quota_mb") or 0),
        },
        "reservations": [
            {
                "id": r["id"],
                "reservation_token": r["reservation_token"],
                "amount": r["amount"],
                "reason": r["reason"],
                "status": r["status"],
                "metadata": _credit_json.loads(r["metadata_json"]) if r["metadata_json"] else None,
                "created_at": r["created_at"],
                "updated_at": r["updated_at"],
                "expires_at": r["expires_at"],
                "committed_at": r["committed_at"],
                "refunded_at": r["refunded_at"],
            }
            for r in reservations
        ],
        "ledger": [
            {
                "id": l["id"],
                "delta": l["delta"],
                "reason": l["reason"],
                "metadata": _credit_json.loads(l["metadata_json"]) if l["metadata_json"] else None,
                "created_at": l["created_at"],
            }
            for l in ledger
        ],
    }


def _credit_find_reservation(conn, user_id: int, payload):
    reservation_id = payload.get("reservation_id")
    reservation_token = payload.get("reservation_token")

    if reservation_id:
        row = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE id = ?
              AND user_id = ?
            """,
            (int(reservation_id), user_id),
        ).fetchone()
    elif reservation_token:
        row = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE reservation_token = ?
              AND user_id = ?
            """,
            (str(reservation_token), user_id),
        ).fetchone()
    else:
        raise HTTPException(status_code=400, detail="reservation_id or reservation_token is required.")

    if not row:
        raise HTTPException(status_code=404, detail="Reservation not found.")

    return row


@app.get("/system/account/credits")
async def system_account_credits(request: Request):
    row = _credit_get_user_row(request)
    return _credit_public_summary_for_user(int(row["id"]))


@app.post("/system/credits/reserve")
async def system_credits_reserve(request: Request):
    row = _credit_get_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    amount = _credit_parse_payload_amount(payload, "amount")
    reason = str(payload.get("reason") or "reservation").strip()[:120]
    metadata = payload.get("metadata")
    now = _auth_now_iso()
    token = _credit_secrets.token_urlsafe(32)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        current = conn.execute(
            """
            SELECT credit_balance
            FROM app_users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()

        available = int(current["credit_balance"] if current else 0)

        if amount > available:
            raise HTTPException(
                status_code=402,
                detail=f"Insufficient credits. Required {amount}, available {available}.",
            )

        conn.execute("BEGIN IMMEDIATE")

        conn.execute(
            """
            UPDATE app_users
            SET credit_balance = credit_balance - ?,
                updated_at = ?
            WHERE id = ?
            """,
            (amount, now, user_id),
        )

        conn.execute(
            """
            INSERT INTO credit_reservations (
                user_id,
                reservation_token,
                amount,
                reason,
                status,
                metadata_json,
                created_at,
                updated_at,
                expires_at
            )
            VALUES (?, ?, ?, ?, 'reserved', ?, ?, ?, ?)
            """,
            (
                user_id,
                token,
                amount,
                reason,
                _credit_json_dumps(metadata),
                now,
                now,
                payload.get("expires_at"),
            ),
        )

        reservation_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

        _credit_add_ledger(
            conn,
            user_id,
            -amount,
            f"reserve:{reason}",
            {
                "reservation_id": reservation_id,
                "reservation_token": token,
                "metadata": metadata,
            },
        )

        conn.commit()

    result = _credit_public_summary_for_user(user_id)
    result["reservation"] = {
        "id": reservation_id,
        "reservation_token": token,
        "amount": amount,
        "reason": reason,
        "status": "reserved",
    }
    return result


@app.post("/system/credits/commit")
async def system_credits_commit(request: Request):
    row = _credit_get_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    final_amount = payload.get("final_amount")
    metadata = payload.get("metadata")
    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        reservation = _credit_find_reservation(conn, user_id, payload)

        if reservation["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Reservation is already {reservation['status']}.")

        reserved_amount = int(reservation["amount"])
        settle_amount = reserved_amount if final_amount is None else int(final_amount)

        if settle_amount < 0:
            raise HTTPException(status_code=400, detail="final_amount cannot be negative.")

        if settle_amount < reserved_amount:
            refund = reserved_amount - settle_amount

            conn.execute(
                """
                UPDATE app_users
                SET credit_balance = credit_balance + ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (refund, now, user_id),
            )

            _credit_add_ledger(
                conn,
                user_id,
                refund,
                f"release_unused:{reservation['reason']}",
                {
                    "reservation_id": reservation["id"],
                    "reserved_amount": reserved_amount,
                    "final_amount": settle_amount,
                    "metadata": metadata,
                },
            )

        elif settle_amount > reserved_amount:
            extra = settle_amount - reserved_amount

            current = conn.execute(
                """
                SELECT credit_balance
                FROM app_users
                WHERE id = ?
                """,
                (user_id,),
            ).fetchone()

            available = int(current["credit_balance"] if current else 0)

            if extra > available:
                raise HTTPException(
                    status_code=402,
                    detail=f"Insufficient credits for overage. Required extra {extra}, available {available}.",
                )

            conn.execute(
                """
                UPDATE app_users
                SET credit_balance = credit_balance - ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (extra, now, user_id),
            )

            _credit_add_ledger(
                conn,
                user_id,
                -extra,
                f"commit_overage:{reservation['reason']}",
                {
                    "reservation_id": reservation["id"],
                    "reserved_amount": reserved_amount,
                    "final_amount": settle_amount,
                    "metadata": metadata,
                },
            )

        conn.execute(
            """
            UPDATE credit_reservations
            SET status = 'committed',
                updated_at = ?,
                committed_at = ?,
                metadata_json = COALESCE(?, metadata_json)
            WHERE id = ?
            """,
            (
                now,
                now,
                _credit_json_dumps(metadata) if metadata is not None else None,
                reservation["id"],
            ),
        )

        _credit_add_ledger(
            conn,
            user_id,
            0,
            f"commit:{reservation['reason']}",
            {
                "reservation_id": reservation["id"],
                "reserved_amount": reserved_amount,
                "final_amount": settle_amount,
                "metadata": metadata,
            },
        )

        conn.commit()

    return _credit_public_summary_for_user(user_id)


@app.post("/system/credits/refund")
async def system_credits_refund(request: Request):
    row = _credit_get_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    now = _auth_now_iso()
    metadata = payload.get("metadata")

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        reservation = _credit_find_reservation(conn, user_id, payload)

        if reservation["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Reservation is already {reservation['status']}.")

        amount = int(reservation["amount"])

        conn.execute(
            """
            UPDATE app_users
            SET credit_balance = credit_balance + ?,
                updated_at = ?
            WHERE id = ?
            """,
            (amount, now, user_id),
        )

        conn.execute(
            """
            UPDATE credit_reservations
            SET status = 'refunded',
                updated_at = ?,
                refunded_at = ?,
                metadata_json = COALESCE(?, metadata_json)
            WHERE id = ?
            """,
            (
                now,
                now,
                _credit_json_dumps(metadata) if metadata is not None else None,
                reservation["id"],
            ),
        )

        _credit_add_ledger(
            conn,
            user_id,
            amount,
            f"refund:{reservation['reason']}",
            {
                "reservation_id": reservation["id"],
                "reservation_token": reservation["reservation_token"],
                "metadata": metadata,
            },
        )

        conn.commit()

    return _credit_public_summary_for_user(user_id)


@app.post("/system/credits/grant")
async def system_credits_grant(request: Request):
    admin_row = _credit_require_admin(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    amount = _credit_parse_payload_amount(payload, "amount")
    reason = str(payload.get("reason") or "admin_grant").strip()[:120]
    target_email = _auth_normalize_email(payload.get("email") or "")
    target_user_id = payload.get("user_id")
    metadata = payload.get("metadata")
    now = _auth_now_iso()

    if not target_email and not target_user_id:
        raise HTTPException(status_code=400, detail="email or user_id is required.")

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        if target_user_id:
            target = conn.execute(
                """
                SELECT *
                FROM app_users
                WHERE id = ?
                """,
                (int(target_user_id),),
            ).fetchone()
        else:
            target = conn.execute(
                """
                SELECT *
                FROM app_users
                WHERE email = ?
                """,
                (target_email,),
            ).fetchone()

        if not target:
            raise HTTPException(status_code=404, detail="Target user not found.")

        conn.execute(
            """
            UPDATE app_users
            SET credit_balance = credit_balance + ?,
                updated_at = ?
            WHERE id = ?
            """,
            (amount, now, int(target["id"])),
        )

        _credit_add_ledger(
            conn,
            int(target["id"]),
            amount,
            f"grant:{reason}",
            {
                "admin_user_id": int(admin_row["id"]),
                "admin_email": admin_row["email"],
                "metadata": metadata,
            },
        )

        conn.commit()

    return _credit_public_summary_for_user(int(target["id"]))


# ============================================================
# Credit pool engine v2
# Separates free/local credits from paid credits.
#
# Rule:
# - free_credit_balance can only be used for service_class='local'
# - paid_credit_balance can be used for local or external_paid
# - external_paid jobs may ONLY use paid credits
# ============================================================

def _credit_pool_init_tables():
    _credit_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        _account_add_column_if_missing(conn, "app_users", "free_credit_balance", "free_credit_balance INTEGER NOT NULL DEFAULT 100")
        _account_add_column_if_missing(conn, "app_users", "paid_credit_balance", "paid_credit_balance INTEGER NOT NULL DEFAULT 0")
        _account_add_column_if_missing(conn, "app_users", "monthly_free_credit_allowance", "monthly_free_credit_allowance INTEGER NOT NULL DEFAULT 100")
        _account_add_column_if_missing(conn, "app_users", "monthly_paid_credit_allowance", "monthly_paid_credit_allowance INTEGER NOT NULL DEFAULT 0")

        _account_add_column_if_missing(conn, "credit_reservations", "service_class", "service_class TEXT NOT NULL DEFAULT 'local'")
        _account_add_column_if_missing(conn, "credit_reservations", "free_amount", "free_amount INTEGER NOT NULL DEFAULT 0")
        _account_add_column_if_missing(conn, "credit_reservations", "paid_amount", "paid_amount INTEGER NOT NULL DEFAULT 0")

        _account_add_column_if_missing(conn, "user_credit_ledger", "free_delta", "free_delta INTEGER NOT NULL DEFAULT 0")
        _account_add_column_if_missing(conn, "user_credit_ledger", "paid_delta", "paid_delta INTEGER NOT NULL DEFAULT 0")
        _account_add_column_if_missing(conn, "user_credit_ledger", "service_class", "service_class TEXT")

        # One-time-ish sync for existing users:
        # If new pools are still at defaults but legacy credit_balance is higher,
        # keep the current balance as free/local credits.
        rows = conn.execute(
            """
            SELECT id, credit_balance, free_credit_balance, paid_credit_balance
            FROM app_users
            """
        ).fetchall()

        for row in rows:
            user_id = int(row[0])
            legacy = int(row[1] or 0)
            free = int(row[2] or 0)
            paid = int(row[3] or 0)

            if legacy > free + paid:
                conn.execute(
                    """
                    UPDATE app_users
                    SET free_credit_balance = ?,
                        credit_balance = ?,
                        updated_at = ?
                    WHERE id = ?
                    """,
                    (legacy, legacy, _auth_now_iso(), user_id),
                )

        conn.commit()


def _credit_pool_user_row(request: Request):
    _credit_pool_init_tables()
    auth_row = _auth_current_user_from_request(request)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (auth_row["id"],),
        ).fetchone()

    if not row:
        raise HTTPException(status_code=401, detail="User not found.")

    return row


def _credit_pool_require_admin(request: Request):
    row = _credit_pool_user_row(request)
    user = _account_enriched_public_user(row)

    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="Admin access required.")

    return row


def _credit_pool_active_reserved_totals(conn, user_id: int):
    return _credit_pool_active_reserved_totals_impl(conn, user_id)




def _credit_pool_sync_legacy_total(conn, user_id: int):
    return _credit_pool_sync_legacy_total_impl(
        conn,
        user_id,
        now_iso=_auth_now_iso,
    )




def _credit_pool_add_ledger(conn, user_id: int, free_delta: int, paid_delta: int, reason: str, service_class: str, metadata=None):
    return _credit_pool_add_ledger_impl(
        conn,
        user_id,
        free_delta,
        paid_delta,
        reason,
        service_class,
        metadata,
        now_iso=_auth_now_iso,
        credit_json_dumps=_credit_json_dumps,
    )




def _credit_pool_summary(user_id: int):
    _credit_pool_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        row = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="User not found.")

        free_reserved, paid_reserved = _credit_pool_active_reserved_totals(conn, user_id)

        reservations = conn.execute(
            """
            SELECT
                id,
                reservation_token,
                amount,
                free_amount,
                paid_amount,
                service_class,
                reason,
                status,
                metadata_json,
                created_at,
                updated_at,
                expires_at,
                committed_at,
                refunded_at
            FROM credit_reservations
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 25
            """,
            (user_id,),
        ).fetchall()

        ledger = conn.execute(
            """
            SELECT
                id,
                delta,
                free_delta,
                paid_delta,
                service_class,
                reason,
                metadata_json,
                created_at
            FROM user_credit_ledger
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 75
            """,
            (user_id,),
        ).fetchall()

    user = _account_enriched_public_user(row)

    free_available = int(row["free_credit_balance"] or 0)
    paid_available = int(row["paid_credit_balance"] or 0)

    return {
        "ok": True,
        "user": user,
        "credits": {
            "free_available": free_available,
            "paid_available": paid_available,
            "total_available": free_available + paid_available,
            "free_reserved": free_reserved,
            "paid_reserved": paid_reserved,
            "total_reserved": free_reserved + paid_reserved,
            "monthly_free_allowance": int(row["monthly_free_credit_allowance"] or 0),
            "monthly_paid_allowance": int(row["monthly_paid_credit_allowance"] or 0),
            "plan": row["plan"],
            "billing_status": row["billing_status"],
            "storage_quota_mb": int(row["storage_quota_mb"] or 0),
            "rules": {
                "free_credits": "local_only",
                "paid_credits": "local_or_external_paid",
            },
        },
        "reservations": [
            {
                "id": r["id"],
                "reservation_token": r["reservation_token"],
                "amount": r["amount"],
                "free_amount": r["free_amount"],
                "paid_amount": r["paid_amount"],
                "service_class": r["service_class"],
                "reason": r["reason"],
                "status": r["status"],
                "metadata": _credit_json.loads(r["metadata_json"]) if r["metadata_json"] else None,
                "created_at": r["created_at"],
                "updated_at": r["updated_at"],
                "expires_at": r["expires_at"],
                "committed_at": r["committed_at"],
                "refunded_at": r["refunded_at"],
            }
            for r in reservations
        ],
        "ledger": [
            {
                "id": l["id"],
                "delta": l["delta"],
                "free_delta": l["free_delta"],
                "paid_delta": l["paid_delta"],
                "service_class": l["service_class"],
                "reason": l["reason"],
                "metadata": _credit_json.loads(l["metadata_json"]) if l["metadata_json"] else None,
                "created_at": l["created_at"],
            }
            for l in ledger
        ],
    }



def _credit_pool_find_reservation(conn, user_id: int, payload):
    return _credit_pool_find_reservation_impl(conn, user_id, payload)




@app.get("/system/account/credit-pools")
async def system_account_credit_pools(request: Request):
    row = _credit_pool_user_row(request)
    return _credit_pool_summary(int(row["id"]))


@app.post("/system/credits/reserve-v2")
async def system_credits_reserve_v2(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    amount = _credit_parse_payload_amount(payload, "amount")
    reason = str(payload.get("reason") or "reservation").strip()[:120]
    service_class = str(payload.get("service_class") or "local").strip().lower()
    allow_paid_for_local = bool(payload.get("allow_paid_for_local", True))
    metadata = payload.get("metadata")
    now = _auth_now_iso()
    token = _credit_secrets.token_urlsafe(32)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        current = conn.execute(
            """
            SELECT free_credit_balance, paid_credit_balance
            FROM app_users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()

        free_available = int(current["free_credit_balance"] if current else 0)
        paid_available = int(current["paid_credit_balance"] if current else 0)

        free_amount, paid_amount = _credit_pool_debit_plan(
            free_available=free_available,
            paid_available=paid_available,
            amount=amount,
            service_class=service_class,
            allow_paid_for_local=allow_paid_for_local,
        )

        conn.execute(
            """
            UPDATE app_users
            SET free_credit_balance = free_credit_balance - ?,
                paid_credit_balance = paid_credit_balance - ?,
                updated_at = ?
            WHERE id = ?
            """,
            (free_amount, paid_amount, now, user_id),
        )

        conn.execute(
            """
            INSERT INTO credit_reservations (
                user_id,
                reservation_token,
                amount,
                free_amount,
                paid_amount,
                service_class,
                reason,
                status,
                metadata_json,
                created_at,
                updated_at,
                expires_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 'reserved', ?, ?, ?, ?)
            """,
            (
                user_id,
                token,
                amount,
                free_amount,
                paid_amount,
                service_class,
                reason,
                _credit_json_dumps(metadata),
                now,
                now,
                payload.get("expires_at"),
            ),
        )

        reservation_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

        _credit_pool_add_ledger(
            conn,
            user_id,
            -free_amount,
            -paid_amount,
            f"reserve:{reason}",
            service_class,
            {
                "reservation_id": reservation_id,
                "reservation_token": token,
                "amount": amount,
                "free_amount": free_amount,
                "paid_amount": paid_amount,
                "metadata": metadata,
            },
        )

        _credit_pool_sync_legacy_total(conn, user_id)
        conn.commit()

    result = _credit_pool_summary(user_id)
    result["reservation"] = {
        "id": reservation_id,
        "reservation_token": token,
        "amount": amount,
        "free_amount": free_amount,
        "paid_amount": paid_amount,
        "service_class": service_class,
        "reason": reason,
        "status": "reserved",
    }
    return result


@app.post("/system/credits/commit-v2")
async def system_credits_commit_v2(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    final_amount_raw = payload.get("final_amount")
    metadata = payload.get("metadata")
    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        reservation = _credit_pool_find_reservation(conn, user_id, payload)

        if reservation["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Reservation is already {reservation['status']}.")

        reserved_amount = int(reservation["amount"])
        service_class = reservation["service_class"]
        free_reserved = int(reservation["free_amount"] or 0)
        paid_reserved = int(reservation["paid_amount"] or 0)

        final_amount = reserved_amount if final_amount_raw is None else int(final_amount_raw)

        if final_amount < 0:
            raise HTTPException(status_code=400, detail="final_amount cannot be negative.")

        if final_amount < reserved_amount:
            refund_total = reserved_amount - final_amount

            # Refund paid first because paid credits are more valuable.
            paid_refund = min(paid_reserved, refund_total)
            remaining_refund = refund_total - paid_refund
            free_refund = min(free_reserved, remaining_refund)

            conn.execute(
                """
                UPDATE app_users
                SET free_credit_balance = free_credit_balance + ?,
                    paid_credit_balance = paid_credit_balance + ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (free_refund, paid_refund, now, user_id),
            )

            _credit_pool_add_ledger(
                conn,
                user_id,
                free_refund,
                paid_refund,
                f"release_unused:{reservation['reason']}",
                service_class,
                {
                    "reservation_id": reservation["id"],
                    "reserved_amount": reserved_amount,
                    "final_amount": final_amount,
                    "free_refund": free_refund,
                    "paid_refund": paid_refund,
                    "metadata": metadata,
                },
            )

        elif final_amount > reserved_amount:
            extra = final_amount - reserved_amount

            current = conn.execute(
                """
                SELECT free_credit_balance, paid_credit_balance
                FROM app_users
                WHERE id = ?
                """,
                (user_id,),
            ).fetchone()

            free_available = int(current["free_credit_balance"] if current else 0)
            paid_available = int(current["paid_credit_balance"] if current else 0)

            extra_free, extra_paid = _credit_pool_debit_plan(
                free_available=free_available,
                paid_available=paid_available,
                amount=extra,
                service_class=service_class,
                allow_paid_for_local=True,
            )

            conn.execute(
                """
                UPDATE app_users
                SET free_credit_balance = free_credit_balance - ?,
                    paid_credit_balance = paid_credit_balance - ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (extra_free, extra_paid, now, user_id),
            )

            _credit_pool_add_ledger(
                conn,
                user_id,
                -extra_free,
                -extra_paid,
                f"commit_overage:{reservation['reason']}",
                service_class,
                {
                    "reservation_id": reservation["id"],
                    "reserved_amount": reserved_amount,
                    "final_amount": final_amount,
                    "extra_free": extra_free,
                    "extra_paid": extra_paid,
                    "metadata": metadata,
                },
            )

        conn.execute(
            """
            UPDATE credit_reservations
            SET status = 'committed',
                updated_at = ?,
                committed_at = ?,
                metadata_json = COALESCE(?, metadata_json)
            WHERE id = ?
            """,
            (
                now,
                now,
                _credit_json_dumps(metadata) if metadata is not None else None,
                reservation["id"],
            ),
        )

        _credit_pool_add_ledger(
            conn,
            user_id,
            0,
            0,
            f"commit:{reservation['reason']}",
            service_class,
            {
                "reservation_id": reservation["id"],
                "reserved_amount": reserved_amount,
                "final_amount": final_amount,
                "metadata": metadata,
            },
        )

        _credit_pool_sync_legacy_total(conn, user_id)
        conn.commit()

    return _credit_pool_summary(user_id)


@app.post("/system/credits/refund-v2")
async def system_credits_refund_v2(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    metadata = payload.get("metadata")
    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        reservation = _credit_pool_find_reservation(conn, user_id, payload)

        if reservation["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Reservation is already {reservation['status']}.")

        free_amount = int(reservation["free_amount"] or 0)
        paid_amount = int(reservation["paid_amount"] or 0)

        conn.execute(
            """
            UPDATE app_users
            SET free_credit_balance = free_credit_balance + ?,
                paid_credit_balance = paid_credit_balance + ?,
                updated_at = ?
            WHERE id = ?
            """,
            (free_amount, paid_amount, now, user_id),
        )

        conn.execute(
            """
            UPDATE credit_reservations
            SET status = 'refunded',
                updated_at = ?,
                refunded_at = ?,
                metadata_json = COALESCE(?, metadata_json)
            WHERE id = ?
            """,
            (
                now,
                now,
                _credit_json_dumps(metadata) if metadata is not None else None,
                reservation["id"],
            ),
        )

        _credit_pool_add_ledger(
            conn,
            user_id,
            free_amount,
            paid_amount,
            f"refund:{reservation['reason']}",
            reservation["service_class"],
            {
                "reservation_id": reservation["id"],
                "reservation_token": reservation["reservation_token"],
                "free_amount": free_amount,
                "paid_amount": paid_amount,
                "metadata": metadata,
            },
        )

        _credit_pool_sync_legacy_total(conn, user_id)
        conn.commit()

    return _credit_pool_summary(user_id)


@app.post("/system/credits/grant-free")
async def system_credits_grant_free(request: Request):
    admin_row = _credit_pool_require_admin(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    amount = _credit_parse_payload_amount(payload, "amount")
    reason = str(payload.get("reason") or "admin_grant_free").strip()[:120]
    target_email = _auth_normalize_email(payload.get("email") or "")
    metadata = payload.get("metadata")

    if not target_email:
        raise HTTPException(status_code=400, detail="email is required.")

    target_id = _credit_pool_grant_free_to_email_impl(
        db_path=DB_PATH,
        email=target_email,
        amount=amount,
        reason=reason,
        admin_user_id=int(admin_row["id"]),
        admin_email=admin_row["email"],
        metadata=metadata,
        now_iso=_auth_now_iso,
        credit_json_dumps=_credit_json_dumps,
    )

    return _credit_pool_summary(target_id)




@app.post("/system/credits/grant-paid")
async def system_credits_grant_paid(request: Request):
    admin_row = _credit_pool_require_admin(request)

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    amount = _credit_parse_payload_amount(payload, "amount")
    reason = str(payload.get("reason") or "admin_grant_paid").strip()[:120]
    target_email = _auth_normalize_email(payload.get("email") or "")
    metadata = payload.get("metadata")

    if not target_email:
        raise HTTPException(status_code=400, detail="email is required.")

    target_id = _credit_pool_grant_paid_to_email_impl(
        db_path=DB_PATH,
        email=target_email,
        amount=amount,
        reason=reason,
        admin_user_id=int(admin_row["id"]),
        admin_email=admin_row["email"],
        metadata=metadata,
        now_iso=_auth_now_iso,
        credit_json_dumps=_credit_json_dumps,
    )

    return _credit_pool_summary(target_id)




# ============================================================
# Rewarded ad free-credit engine
#
# IMPORTANT:
# - This is local/mock reward claiming for development.
# - Real production use must verify reward completion with the ad provider.
# - Rewards grant FREE/LOCAL credits only.
# - Ad-earned credits must never pay for external_paid services.
# ============================================================

import hashlib as _ad_hashlib


def _ad_reward_init_tables():
    return _rewarded_ad_init_tables_impl(
        db_path=DB_PATH,
        credit_pool_init_tables=_credit_pool_init_tables,
    )









@app.get("/system/ads/reward/status")
async def system_ads_reward_status(request: Request):
    row = _credit_pool_user_row(request)
    return _ad_reward_status_for_user(
        int(row["id"]),
        db_path=DB_PATH,
        init_tables=_ad_reward_init_tables,
        now_iso=_auth_now_iso,
    )


@app.post("/system/ads/reward/claim")
async def system_ads_reward_claim(request: Request):
    """
    Rewarded-ad claim endpoint.

    This route intentionally stays thin; claim rules live in edge_modules.rewarded_ads.
    Rewards grant free/local credits only.
    """
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    return _ad_reward_claim_for_user(
        request=request,
        payload=payload,
        user_id=user_id,
        db_path=DB_PATH,
        now_iso=_auth_now_iso,
        init_tables=_ad_reward_init_tables,
        credit_pool_summary=_credit_pool_summary,
        credit_pool_grant_free_to_user=_credit_pool_grant_free_to_user_on_conn_impl,
        ad_hash=_ad_hash,
        credit_json_dumps=_credit_json_dumps,
    )



# ============================================================
# Mock external GPU quote engine
#
# This does NOT start real cloud GPUs yet.
# It quotes mock external GPU sessions and reserves PAID credits only.
# Foundation for future RunPod/Vast/Lambda/etc integrations.
# ============================================================

import math as _gpu_math
import secrets as _gpu_secrets
from datetime import datetime as _gpu_datetime, timezone as _gpu_timezone, timedelta as _gpu_timedelta


def _gpu_quote_init_tables():
    _credit_pool_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS gpu_session_quotes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                quote_token TEXT NOT NULL UNIQUE,
                provider TEXT NOT NULL,
                gpu_id TEXT NOT NULL,
                gpu_name TEXT NOT NULL,
                duration_minutes INTEGER NOT NULL,
                service_class TEXT NOT NULL DEFAULT 'external_paid',
                provider_cost_cents INTEGER NOT NULL,
                fees_cents INTEGER NOT NULL,
                margin_cents INTEGER NOT NULL,
                tax_buffer_cents INTEGER NOT NULL,
                total_cents INTEGER NOT NULL,
                credits_required INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'quoted',
                reservation_token TEXT,
                metadata_json TEXT,
                created_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                reserved_at TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )
        conn.commit()


def _gpu_catalog():
    return [
        {
            "provider": "mock-cloud",
            "gpu_id": "rtx-4090",
            "name": "NVIDIA RTX 4090",
            "vram_gb": 24,
            "provider_cost_cents_per_hour": 400,
            "service_class": "external_paid",
            "description": "Mock high-end consumer GPU session.",
        },
        {
            "provider": "mock-cloud",
            "gpu_id": "a100-40gb",
            "name": "NVIDIA A100 40GB",
            "vram_gb": 40,
            "provider_cost_cents_per_hour": 1800,
            "service_class": "external_paid",
            "description": "Mock data-center GPU session.",
        },
        {
            "provider": "mock-cloud",
            "gpu_id": "h100-80gb",
            "name": "NVIDIA H100 80GB",
            "vram_gb": 80,
            "provider_cost_cents_per_hour": 3500,
            "service_class": "external_paid",
            "description": "Mock premium data-center GPU session.",
        },
    ]


def _gpu_find_catalog_item(gpu_id: str):
    gpu_id = str(gpu_id or "").strip().lower()

    for item in _gpu_catalog():
        if item["gpu_id"] == gpu_id:
            return item

    raise HTTPException(status_code=404, detail="GPU option not found.")


def _gpu_quote_settings():
    return {
        "credit_cents": int(os.getenv("CREDIT_CENTS", "1")),
        "platform_margin_pct": float(os.getenv("GPU_QUOTE_PLATFORM_MARGIN_PCT", "0.30")),
        "fee_buffer_pct": float(os.getenv("GPU_QUOTE_FEE_BUFFER_PCT", "0.08")),
        "tax_buffer_pct": float(os.getenv("GPU_QUOTE_TAX_BUFFER_PCT", "0.10")),
        "quote_ttl_minutes": int(os.getenv("GPU_QUOTE_TTL_MINUTES", "15")),
    }


def _gpu_now():
    return _gpu_datetime.now(_gpu_timezone.utc)


def _gpu_iso(dt):
    return dt.isoformat()


def _gpu_parse_iso(value):
    return _gpu_datetime.fromisoformat(str(value).replace("Z", "+00:00"))


def _gpu_calculate_quote(item, duration_minutes: int):
    settings = _gpu_quote_settings()

    duration_minutes = int(duration_minutes)

    if duration_minutes < 5:
        raise HTTPException(status_code=400, detail="duration_minutes must be at least 5.")

    if duration_minutes > 24 * 60:
        raise HTTPException(status_code=400, detail="duration_minutes cannot exceed 1440 for one quote.")

    hourly = int(item["provider_cost_cents_per_hour"])

    provider_cost = _gpu_math.ceil(hourly * (duration_minutes / 60.0))
    fees = _gpu_math.ceil(provider_cost * settings["fee_buffer_pct"])
    margin = _gpu_math.ceil(provider_cost * settings["platform_margin_pct"])
    tax_buffer = _gpu_math.ceil(provider_cost * settings["tax_buffer_pct"])
    total_cents = provider_cost + fees + margin + tax_buffer

    credit_cents = max(1, int(settings["credit_cents"]))
    credits_required = _gpu_math.ceil(total_cents / credit_cents)

    return {
        "provider_cost_cents": provider_cost,
        "fees_cents": fees,
        "margin_cents": margin,
        "tax_buffer_cents": tax_buffer,
        "total_cents": total_cents,
        "credits_required": credits_required,
        "credit_cents": credit_cents,
    }


@app.get("/system/gpu/catalog")
async def system_gpu_catalog(request: Request):
    _credit_pool_user_row(request)

    return {
        "ok": True,
        "mode": "mock",
        "detail": "Mock external GPU catalog. No real cloud GPUs are started yet.",
        "items": _gpu_catalog(),
        "pricing_rule": {
            "service_class": "external_paid",
            "requires": "paid credits only",
            "free_credits_allowed": False,
        },
    }


@app.post("/system/gpu/quote")
async def system_gpu_quote(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    gpu_id = str(payload.get("gpu_id") or "").strip().lower()

    try:
        duration_minutes = int(payload.get("duration_minutes"))
    except Exception:
        raise HTTPException(status_code=400, detail="duration_minutes must be an integer.")

    item = _gpu_find_catalog_item(gpu_id)
    quote = _gpu_calculate_quote(item, duration_minutes)

    _gpu_quote_init_tables()

    now = _gpu_now()
    settings = _gpu_quote_settings()
    expires_at = now + _gpu_timedelta(minutes=settings["quote_ttl_minutes"])
    quote_token = _gpu_secrets.token_urlsafe(32)

    metadata = {
        "input": payload,
        "quote_settings": settings,
        "note": "Mock quote only. No external provider instance is started.",
    }

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            INSERT INTO gpu_session_quotes (
                user_id,
                quote_token,
                provider,
                gpu_id,
                gpu_name,
                duration_minutes,
                service_class,
                provider_cost_cents,
                fees_cents,
                margin_cents,
                tax_buffer_cents,
                total_cents,
                credits_required,
                status,
                metadata_json,
                created_at,
                expires_at
            )
            VALUES (?, ?, ?, ?, ?, ?, 'external_paid', ?, ?, ?, ?, ?, ?, 'quoted', ?, ?, ?)
            """,
            (
                user_id,
                quote_token,
                item["provider"],
                item["gpu_id"],
                item["name"],
                duration_minutes,
                quote["provider_cost_cents"],
                quote["fees_cents"],
                quote["margin_cents"],
                quote["tax_buffer_cents"],
                quote["total_cents"],
                quote["credits_required"],
                _credit_json_dumps(metadata),
                _gpu_iso(now),
                _gpu_iso(expires_at),
            ),
        )
        conn.commit()

    return {
        "ok": True,
        "mode": "mock",
        "quote": {
            "quote_token": quote_token,
            "provider": item["provider"],
            "gpu_id": item["gpu_id"],
            "gpu_name": item["name"],
            "duration_minutes": duration_minutes,
            "service_class": "external_paid",
            "provider_cost_cents": quote["provider_cost_cents"],
            "fees_cents": quote["fees_cents"],
            "margin_cents": quote["margin_cents"],
            "tax_buffer_cents": quote["tax_buffer_cents"],
            "total_cents": quote["total_cents"],
            "credits_required": quote["credits_required"],
            "credit_cents": quote["credit_cents"],
            "expires_at": _gpu_iso(expires_at),
        },
        "important": "This quote requires paid credits only. Free/local credits cannot be used.",
    }


@app.post("/system/gpu/reserve-quote")
async def system_gpu_reserve_quote(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    quote_token = str(payload.get("quote_token") or "").strip()

    if not quote_token:
        raise HTTPException(status_code=400, detail="quote_token is required.")

    _gpu_quote_init_tables()

    now = _gpu_now()
    now_iso = _gpu_iso(now)
    reservation_token = _credit_secrets.token_urlsafe(32)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        quote = conn.execute(
            """
            SELECT *
            FROM gpu_session_quotes
            WHERE user_id = ?
              AND quote_token = ?
            """,
            (user_id, quote_token),
        ).fetchone()

        if not quote:
            raise HTTPException(status_code=404, detail="Quote not found.")

        if quote["status"] != "quoted":
            raise HTTPException(status_code=409, detail=f"Quote is already {quote['status']}.")

        if _gpu_parse_iso(quote["expires_at"]) < now:
            conn.execute(
                """
                UPDATE gpu_session_quotes
                SET status = 'expired'
                WHERE id = ?
                """,
                (quote["id"],),
            )
            conn.commit()
            raise HTTPException(status_code=409, detail="Quote expired. Create a new quote.")

        amount = int(quote["credits_required"])

        current = conn.execute(
            """
            SELECT paid_credit_balance
            FROM app_users
            WHERE id = ?
            """,
            (user_id,),
        ).fetchone()

        paid_available = int(current["paid_credit_balance"] if current else 0)

        if paid_available < amount:
            raise HTTPException(
                status_code=402,
                detail=f"Insufficient paid credits. Required {amount}, paid available {paid_available}.",
            )

        conn.execute(
            """
            UPDATE app_users
            SET paid_credit_balance = paid_credit_balance - ?,
                updated_at = ?
            WHERE id = ?
            """,
            (amount, _auth_now_iso(), user_id),
        )

        conn.execute(
            """
            INSERT INTO credit_reservations (
                user_id,
                reservation_token,
                amount,
                free_amount,
                paid_amount,
                service_class,
                reason,
                status,
                metadata_json,
                created_at,
                updated_at,
                expires_at
            )
            VALUES (?, ?, ?, 0, ?, 'external_paid', ?, 'reserved', ?, ?, ?, ?)
            """,
            (
                user_id,
                reservation_token,
                amount,
                amount,
                f"gpu_quote:{quote['gpu_id']}",
                _credit_json_dumps({
                    "quote_token": quote_token,
                    "provider": quote["provider"],
                    "gpu_id": quote["gpu_id"],
                    "gpu_name": quote["gpu_name"],
                    "duration_minutes": quote["duration_minutes"],
                    "total_cents": quote["total_cents"],
                }),
                now_iso,
                now_iso,
                quote["expires_at"],
            ),
        )

        reservation_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

        _credit_pool_add_ledger(
            conn,
            user_id,
            0,
            -amount,
            f"reserve_gpu_quote:{quote['gpu_id']}",
            "external_paid",
            {
                "quote_id": quote["id"],
                "quote_token": quote_token,
                "reservation_id": reservation_id,
                "reservation_token": reservation_token,
                "credits_required": amount,
            },
        )

        conn.execute(
            """
            UPDATE gpu_session_quotes
            SET status = 'reserved',
                reservation_token = ?,
                reserved_at = ?
            WHERE id = ?
            """,
            (reservation_token, now_iso, quote["id"]),
        )

        _credit_pool_sync_legacy_total(conn, user_id)
        conn.commit()

    result = _credit_pool_summary(user_id)
    result["gpu_quote"] = {
        "ok": True,
        "mode": "mock",
        "status": "reserved",
        "quote_token": quote_token,
        "reservation_token": reservation_token,
        "reservation_id": reservation_id,
        "paid_credits_reserved": amount,
        "detail": "Mock GPU quote reserved with paid credits only. No real GPU was started.",
    }
    return result


# ============================================================
# Mock external GPU session lifecycle
#
# Flow:
# quote -> reserve paid credits -> start mock session -> stop session
#
# Stop commits only estimated used credits and releases unused paid credits.
# No real cloud GPU is started yet.
# ============================================================

def _gpu_session_init_tables():
    _gpu_quote_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS gpu_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                session_token TEXT NOT NULL UNIQUE,
                quote_token TEXT NOT NULL,
                reservation_token TEXT NOT NULL,
                provider TEXT NOT NULL,
                gpu_id TEXT NOT NULL,
                gpu_name TEXT NOT NULL,
                duration_minutes INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'running',
                service_class TEXT NOT NULL DEFAULT 'external_paid',
                credits_reserved INTEGER NOT NULL,
                final_credits_charged INTEGER,
                billable_minutes INTEGER,
                metadata_json TEXT,
                created_at TEXT NOT NULL,
                started_at TEXT NOT NULL,
                stopped_at TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )
        conn.commit()


def _gpu_session_public(row):
    return {
        "id": row["id"],
        "session_token": row["session_token"],
        "quote_token": row["quote_token"],
        "reservation_token": row["reservation_token"],
        "provider": row["provider"],
        "gpu_id": row["gpu_id"],
        "gpu_name": row["gpu_name"],
        "duration_minutes": row["duration_minutes"],
        "status": row["status"],
        "service_class": row["service_class"],
        "credits_reserved": row["credits_reserved"],
        "final_credits_charged": row["final_credits_charged"],
        "billable_minutes": row["billable_minutes"],
        "created_at": row["created_at"],
        "started_at": row["started_at"],
        "stopped_at": row["stopped_at"],
        "metadata": _credit_json.loads(row["metadata_json"]) if row["metadata_json"] else None,
    }


@app.get("/system/gpu/sessions")
async def system_gpu_sessions(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    _gpu_session_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        sessions = conn.execute(
            """
            SELECT *
            FROM gpu_sessions
            WHERE user_id = ?
            ORDER BY id DESC
            LIMIT 50
            """,
            (user_id,),
        ).fetchall()

    return {
        "ok": True,
        "mode": "mock",
        "detail": "Mock GPU sessions only. No real cloud GPUs are started yet.",
        "sessions": [_gpu_session_public(s) for s in sessions],
    }


@app.post("/system/gpu/start-reserved")
async def system_gpu_start_reserved(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    quote_token = str(payload.get("quote_token") or "").strip()
    reservation_token = str(payload.get("reservation_token") or "").strip()

    if not quote_token and not reservation_token:
        raise HTTPException(status_code=400, detail="quote_token or reservation_token is required.")

    _gpu_session_init_tables()

    now = _gpu_now()
    now_iso = _gpu_iso(now)
    session_token = _gpu_secrets.token_urlsafe(32)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        if quote_token:
            quote = conn.execute(
                """
                SELECT *
                FROM gpu_session_quotes
                WHERE user_id = ?
                  AND quote_token = ?
                """,
                (user_id, quote_token),
            ).fetchone()
        else:
            quote = conn.execute(
                """
                SELECT *
                FROM gpu_session_quotes
                WHERE user_id = ?
                  AND reservation_token = ?
                """,
                (user_id, reservation_token),
            ).fetchone()

        if not quote:
            raise HTTPException(status_code=404, detail="Reserved quote not found.")

        if quote["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Quote must be reserved before starting. Current status: {quote['status']}.")

        reservation_token = quote["reservation_token"]

        reservation = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE user_id = ?
              AND reservation_token = ?
            """,
            (user_id, reservation_token),
        ).fetchone()

        if not reservation:
            raise HTTPException(status_code=404, detail="Credit reservation not found.")

        if reservation["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Reservation is {reservation['status']}, not reserved.")

        existing = conn.execute(
            """
            SELECT *
            FROM gpu_sessions
            WHERE user_id = ?
              AND quote_token = ?
              AND status IN ('starting', 'running')
            """,
            (user_id, quote["quote_token"]),
        ).fetchone()

        if existing:
            raise HTTPException(status_code=409, detail="A running session already exists for this quote.")

        conn.execute(
            """
            INSERT INTO gpu_sessions (
                user_id,
                session_token,
                quote_token,
                reservation_token,
                provider,
                gpu_id,
                gpu_name,
                duration_minutes,
                status,
                service_class,
                credits_reserved,
                metadata_json,
                created_at,
                started_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'running', 'external_paid', ?, ?, ?, ?)
            """,
            (
                user_id,
                session_token,
                quote["quote_token"],
                reservation_token,
                quote["provider"],
                quote["gpu_id"],
                quote["gpu_name"],
                quote["duration_minutes"],
                int(reservation["paid_amount"] or reservation["amount"]),
                _credit_json_dumps({
                    "mock": True,
                    "detail": "No real cloud GPU was started.",
                    "quote_id": quote["id"],
                    "reservation_id": reservation["id"],
                }),
                now_iso,
                now_iso,
            ),
        )

        session_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

        conn.execute(
            """
            UPDATE gpu_session_quotes
            SET status = 'running'
            WHERE id = ?
            """,
            (quote["id"],),
        )

        _credit_pool_add_ledger(
            conn,
            user_id,
            0,
            0,
            f"start_mock_gpu:{quote['gpu_id']}",
            "external_paid",
            {
                "quote_token": quote["quote_token"],
                "reservation_token": reservation_token,
                "session_token": session_token,
                "session_id": session_id,
                "mock": True,
            },
        )

        conn.commit()

    return {
        "ok": True,
        "mode": "mock",
        "session": {
            "id": session_id,
            "session_token": session_token,
            "quote_token": quote_token or quote["quote_token"],
            "reservation_token": reservation_token,
            "provider": quote["provider"],
            "gpu_id": quote["gpu_id"],
            "gpu_name": quote["gpu_name"],
            "duration_minutes": quote["duration_minutes"],
            "status": "running",
            "credits_reserved": int(reservation["paid_amount"] or reservation["amount"]),
            "started_at": now_iso,
        },
        "detail": "Mock GPU session started. No real cloud GPU was started.",
    }


@app.post("/system/gpu/stop-session")
async def system_gpu_stop_session(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    session_token = str(payload.get("session_token") or "").strip()

    if not session_token:
        raise HTTPException(status_code=400, detail="session_token is required.")

    _gpu_session_init_tables()

    now = _gpu_now()
    now_iso = _gpu_iso(now)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        session = conn.execute(
            """
            SELECT *
            FROM gpu_sessions
            WHERE user_id = ?
              AND session_token = ?
            """,
            (user_id, session_token),
        ).fetchone()

        if not session:
            raise HTTPException(status_code=404, detail="GPU session not found.")

        if session["status"] != "running":
            raise HTTPException(status_code=409, detail=f"Session is {session['status']}, not running.")

        reservation = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE user_id = ?
              AND reservation_token = ?
            """,
            (user_id, session["reservation_token"]),
        ).fetchone()

        if not reservation:
            raise HTTPException(status_code=404, detail="Credit reservation not found.")

        if reservation["status"] != "reserved":
            raise HTTPException(status_code=409, detail=f"Reservation is {reservation['status']}, not reserved.")

        started_at = _gpu_parse_iso(session["started_at"])
        elapsed_seconds = max(1, int((now - started_at).total_seconds()))

        # Mock billing: charge by elapsed minute, minimum 1 minute,
        # capped by quoted duration and reserved credits.
        billable_minutes = min(
            int(session["duration_minutes"]),
            max(1, _gpu_math.ceil(elapsed_seconds / 60.0)),
        )

        credits_reserved = int(session["credits_reserved"])
        duration_minutes = max(1, int(session["duration_minutes"]))

        final_credits = min(
            credits_reserved,
            _gpu_math.ceil(credits_reserved * (billable_minutes / duration_minutes)),
        )

        paid_reserved = int(reservation["paid_amount"] or reservation["amount"])
        paid_refund = max(0, paid_reserved - final_credits)

        if paid_refund > 0:
            conn.execute(
                """
                UPDATE app_users
                SET paid_credit_balance = paid_credit_balance + ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (paid_refund, _auth_now_iso(), user_id),
            )

            _credit_pool_add_ledger(
                conn,
                user_id,
                0,
                paid_refund,
                f"release_unused_mock_gpu:{session['gpu_id']}",
                "external_paid",
                {
                    "session_token": session_token,
                    "reservation_token": session["reservation_token"],
                    "credits_reserved": credits_reserved,
                    "final_credits": final_credits,
                    "paid_refund": paid_refund,
                    "billable_minutes": billable_minutes,
                },
            )

        conn.execute(
            """
            UPDATE credit_reservations
            SET status = 'committed',
                updated_at = ?,
                committed_at = ?,
                metadata_json = COALESCE(?, metadata_json)
            WHERE id = ?
            """,
            (
                now_iso,
                now_iso,
                _credit_json_dumps({
                    "session_token": session_token,
                    "mock_gpu_stop": True,
                    "credits_reserved": credits_reserved,
                    "final_credits": final_credits,
                    "paid_refund": paid_refund,
                    "billable_minutes": billable_minutes,
                }),
                reservation["id"],
            ),
        )

        _credit_pool_add_ledger(
            conn,
            user_id,
            0,
            0,
            f"commit_mock_gpu:{session['gpu_id']}",
            "external_paid",
            {
                "session_token": session_token,
                "reservation_token": session["reservation_token"],
                "credits_reserved": credits_reserved,
                "final_credits": final_credits,
                "billable_minutes": billable_minutes,
            },
        )

        conn.execute(
            """
            UPDATE gpu_sessions
            SET status = 'stopped',
                stopped_at = ?,
                final_credits_charged = ?,
                billable_minutes = ?
            WHERE id = ?
            """,
            (
                now_iso,
                final_credits,
                billable_minutes,
                session["id"],
            ),
        )

        conn.execute(
            """
            UPDATE gpu_session_quotes
            SET status = 'completed'
            WHERE user_id = ?
              AND quote_token = ?
            """,
            (user_id, session["quote_token"]),
        )

        _credit_pool_sync_legacy_total(conn, user_id)
        conn.commit()

    result = _credit_pool_summary(user_id)
    result["gpu_session"] = {
        "ok": True,
        "mode": "mock",
        "session_token": session_token,
        "status": "stopped",
        "gpu_id": session["gpu_id"],
        "gpu_name": session["gpu_name"],
        "credits_reserved": credits_reserved,
        "final_credits_charged": final_credits,
        "paid_credits_refunded": paid_refund,
        "billable_minutes": billable_minutes,
        "detail": "Mock GPU session stopped and reservation committed.",
    }

    return result


# ============================================================
# Mock GPU stuck-session cleanup
#
# Development safety endpoint:
# - Cleans up mock GPU sessions that got stuck during UI/backend testing.
# - If the reservation is still reserved, it refunds held credits.
# - If the reservation is already committed/refunded, it only marks session stopped.
# - This should not be used for real provider sessions later.
# ============================================================

@app.post("/system/gpu/cleanup-mock-session")
async def system_gpu_cleanup_mock_session(request: Request):
    row = _credit_pool_user_row(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    session_token = str(payload.get("session_token") or "").strip()

    if not session_token:
        raise HTTPException(status_code=400, detail="session_token is required.")

    _gpu_session_init_tables()

    now = _gpu_now()
    now_iso = _gpu_iso(now)

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        session = conn.execute(
            """
            SELECT *
            FROM gpu_sessions
            WHERE user_id = ?
              AND session_token = ?
            """,
            (user_id, session_token),
        ).fetchone()

        if not session:
            raise HTTPException(status_code=404, detail="GPU session not found.")

        reservation = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE user_id = ?
              AND reservation_token = ?
            """,
            (user_id, session["reservation_token"]),
        ).fetchone()

        refunded_free = 0
        refunded_paid = 0
        reservation_status_before = reservation["status"] if reservation else "missing"

        if reservation and reservation["status"] == "reserved":
            refunded_free = int(reservation["free_amount"] or 0)
            refunded_paid = int(reservation["paid_amount"] or 0)

            conn.execute(
                """
                UPDATE app_users
                SET free_credit_balance = free_credit_balance + ?,
                    paid_credit_balance = paid_credit_balance + ?,
                    updated_at = ?
                WHERE id = ?
                """,
                (refunded_free, refunded_paid, _auth_now_iso(), user_id),
            )

            conn.execute(
                """
                UPDATE credit_reservations
                SET status = 'refunded',
                    updated_at = ?,
                    refunded_at = ?,
                    metadata_json = COALESCE(?, metadata_json)
                WHERE id = ?
                """,
                (
                    now_iso,
                    now_iso,
                    _credit_json_dumps({
                        "cleanup": True,
                        "session_token": session_token,
                        "reason": "mock_gpu_stuck_session_cleanup",
                    }),
                    reservation["id"],
                ),
            )

            _credit_pool_add_ledger(
                conn,
                user_id,
                refunded_free,
                refunded_paid,
                f"cleanup_refund_mock_gpu:{session['gpu_id']}",
                "external_paid",
                {
                    "session_token": session_token,
                    "reservation_token": session["reservation_token"],
                    "refunded_free": refunded_free,
                    "refunded_paid": refunded_paid,
                    "reservation_status_before": reservation_status_before,
                },
            )

        conn.execute(
            """
            UPDATE gpu_sessions
            SET status = 'stopped',
                stopped_at = COALESCE(stopped_at, ?),
                final_credits_charged = COALESCE(final_credits_charged, 0),
                billable_minutes = COALESCE(billable_minutes, 0),
                metadata_json = COALESCE(?, metadata_json)
            WHERE id = ?
            """,
            (
                now_iso,
                _credit_json_dumps({
                    "cleanup": True,
                    "reason": "mock_gpu_stuck_session_cleanup",
                    "reservation_status_before": reservation_status_before,
                }),
                session["id"],
            ),
        )

        conn.execute(
            """
            UPDATE gpu_session_quotes
            SET status = CASE
                WHEN status IN ('running', 'reserved', 'quoted') THEN 'canceled'
                ELSE status
            END
            WHERE user_id = ?
              AND quote_token = ?
            """,
            (user_id, session["quote_token"]),
        )

        _credit_pool_add_ledger(
            conn,
            user_id,
            0,
            0,
            f"cleanup_mock_gpu_session:{session['gpu_id']}",
            "external_paid",
            {
                "session_token": session_token,
                "reservation_token": session["reservation_token"],
                "reservation_status_before": reservation_status_before,
                "refunded_free": refunded_free,
                "refunded_paid": refunded_paid,
            },
        )

        _credit_pool_sync_legacy_total(conn, user_id)
        conn.commit()

    result = _credit_pool_summary(user_id)
    result["gpu_session_cleanup"] = {
        "ok": True,
        "mode": "mock",
        "session_token": session_token,
        "status": "stopped",
        "reservation_status_before": reservation_status_before,
        "refunded_free": refunded_free,
        "refunded_paid": refunded_paid,
        "detail": "Mock GPU session cleaned up.",
    }

    return result


# ============================================================
# Admin panel + support messaging foundation
#
# Features:
# - Admin user list / online users
# - User support tickets
# - Admin support inbox
# - User/admin threaded messages
# ============================================================

def _admin_support_init_tables():
    _account_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS support_tickets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                subject TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'open',
                priority TEXT NOT NULL DEFAULT 'normal',
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                closed_at TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS support_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ticket_id INTEGER NOT NULL,
                sender_user_id INTEGER NOT NULL,
                sender_role TEXT NOT NULL DEFAULT 'user',
                body TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY(ticket_id) REFERENCES support_tickets(id),
                FOREIGN KEY(sender_user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.commit()


def _admin_support_user_from_request(request: Request):
    _admin_support_init_tables()
    row = _credit_pool_user_row(request)
    return row, _account_enriched_public_user(row)


def _admin_support_require_admin(request: Request):
    row, user = _admin_support_user_from_request(request)

    if not user.get("is_admin"):
        raise HTTPException(status_code=403, detail="Admin access required.")

    return row, user


def _admin_support_ticket_public(ticket_row, message_count=None, last_message_at=None):
    return {
        "id": ticket_row["id"],
        "user_id": ticket_row["user_id"],
        "email": ticket_row["email"] if "email" in ticket_row.keys() else None,
        "subject": ticket_row["subject"],
        "status": ticket_row["status"],
        "priority": ticket_row["priority"],
        "created_at": ticket_row["created_at"],
        "updated_at": ticket_row["updated_at"],
        "closed_at": ticket_row["closed_at"],
        "message_count": message_count,
        "last_message_at": last_message_at,
    }


@app.get("/system/admin/users")
async def system_admin_users(request: Request):
    _admin_support_require_admin(request)
    _admin_support_init_tables()

    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        users = conn.execute(
            """
            SELECT
                u.id,
                u.email,
                u.display_name,
                u.status,
                COALESCE(u.role, 'user') AS role,
                COALESCE(u.plan, 'free') AS plan,
                COALESCE(u.billing_status, 'none') AS billing_status,
                COALESCE(u.free_credit_balance, 0) AS free_credit_balance,
                COALESCE(u.paid_credit_balance, 0) AS paid_credit_balance,
                COALESCE(u.storage_quota_mb, 0) AS storage_quota_mb,
                u.created_at,
                u.updated_at,
                u.last_login_at,
                MAX(s.last_seen_at) AS last_seen_at,
                COUNT(CASE WHEN s.revoked_at IS NULL AND s.expires_at > ? THEN 1 END) AS active_session_count
            FROM app_users u
            LEFT JOIN user_sessions s ON s.user_id = u.id
            WHERE COALESCE(u.status, 'active') != 'deleted'
            GROUP BY u.id
            ORDER BY COALESCE(MAX(s.last_seen_at), u.last_login_at, u.created_at) DESC
            LIMIT 250
            """,
            (now,),
        ).fetchall()

    online_window_seconds = int(os.getenv("ADMIN_ONLINE_WINDOW_SECONDS", "300"))
    now_epoch = _ad_iso_to_epoch(now)

    result_users = []
    online_count = 0

    for u in users:
        last_seen = u["last_seen_at"] or u["last_login_at"]
        last_seen_epoch = _ad_iso_to_epoch(last_seen) if last_seen else 0
        is_online = bool(last_seen_epoch and (now_epoch - last_seen_epoch) <= online_window_seconds)

        if is_online:
            online_count += 1

        result_users.append({
            "id": u["id"],
            "email": u["email"],
            "display_name": u["display_name"],
            "status": u["status"],
            "role": u["role"],
            "is_admin": u["role"] == "admin",
            "plan": u["plan"],
            "billing_status": u["billing_status"],
            "free_credit_balance": u["free_credit_balance"],
            "paid_credit_balance": u["paid_credit_balance"],
            "storage_quota_mb": u["storage_quota_mb"],
            "created_at": u["created_at"],
            "updated_at": u["updated_at"],
            "last_login_at": u["last_login_at"],
            "last_seen_at": last_seen,
            "active_session_count": int(u["active_session_count"] or 0),
            "online": is_online,
        })

    return {
        "ok": True,
        "online_window_seconds": online_window_seconds,
        "online_count": online_count,
        "user_count_returned": len(result_users),
        "users": result_users,
    }


@app.post("/system/support/tickets")
async def system_support_create_ticket(request: Request):
    row, user = _admin_support_user_from_request(request)
    user_id = int(row["id"])

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    subject = str(payload.get("subject") or "").strip()
    body = str(payload.get("body") or "").strip()

    if len(subject) < 3:
        raise HTTPException(status_code=400, detail="Subject must be at least 3 characters.")

    if len(body) < 5:
        raise HTTPException(status_code=400, detail="Message must be at least 5 characters.")

    subject = subject[:160]
    body = body[:5000]
    now = _auth_now_iso()

    _admin_support_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        conn.execute(
            """
            INSERT INTO support_tickets (
                user_id,
                subject,
                status,
                priority,
                created_at,
                updated_at
            )
            VALUES (?, ?, 'waiting_admin', 'normal', ?, ?)
            """,
            (user_id, subject, now, now),
        )

        ticket_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]

        conn.execute(
            """
            INSERT INTO support_messages (
                ticket_id,
                sender_user_id,
                sender_role,
                body,
                created_at
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                ticket_id,
                user_id,
                "admin" if user.get("is_admin") else "user",
                body,
                now,
            ),
        )

        conn.commit()

    return {
        "ok": True,
        "ticket": {
            "id": ticket_id,
            "subject": subject,
            "status": "waiting_admin",
            "priority": "normal",
            "created_at": now,
            "updated_at": now,
        },
    }


@app.get("/system/support/tickets")
async def system_support_my_tickets(request: Request):
    row, user = _admin_support_user_from_request(request)
    user_id = int(row["id"])

    _admin_support_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        tickets = conn.execute(
            """
            SELECT
                t.*,
                u.email,
                COUNT(m.id) AS message_count,
                MAX(m.created_at) AS last_message_at
            FROM support_tickets t
            JOIN app_users u ON u.id = t.user_id
            LEFT JOIN support_messages m ON m.ticket_id = t.id
            WHERE t.user_id = ?
            GROUP BY t.id
            ORDER BY COALESCE(MAX(m.created_at), t.updated_at) DESC
            LIMIT 100
            """,
            (user_id,),
        ).fetchall()

    return {
        "ok": True,
        "tickets": [
            _admin_support_ticket_public(t, t["message_count"], t["last_message_at"])
            for t in tickets
        ],
    }


@app.get("/system/admin/support/tickets")
async def system_admin_support_tickets(request: Request):
    _admin_support_require_admin(request)
    _admin_support_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        tickets = conn.execute(
            """
            SELECT
                t.*,
                u.email,
                COUNT(m.id) AS message_count,
                MAX(m.created_at) AS last_message_at
            FROM support_tickets t
            JOIN app_users u ON u.id = t.user_id
            LEFT JOIN support_messages m ON m.ticket_id = t.id
            GROUP BY t.id
            ORDER BY
                CASE t.status
                    WHEN 'waiting_admin' THEN 0
                    WHEN 'open' THEN 1
                    WHEN 'waiting_user' THEN 2
                    WHEN 'solved' THEN 3
                    WHEN 'closed' THEN 4
                    ELSE 5
                END,
                COALESCE(MAX(m.created_at), t.updated_at) DESC
            LIMIT 250
            """
        ).fetchall()

    return {
        "ok": True,
        "tickets": [
            _admin_support_ticket_public(t, t["message_count"], t["last_message_at"])
            for t in tickets
        ],
    }


def _support_get_ticket_for_user_or_admin(conn, ticket_id: int, user_id: int, is_admin: bool):
    if is_admin:
        return conn.execute(
            """
            SELECT t.*, u.email
            FROM support_tickets t
            JOIN app_users u ON u.id = t.user_id
            WHERE t.id = ?
            """,
            (ticket_id,),
        ).fetchone()

    return conn.execute(
        """
        SELECT t.*, u.email
        FROM support_tickets t
        JOIN app_users u ON u.id = t.user_id
        WHERE t.id = ?
          AND t.user_id = ?
        """,
        (ticket_id, user_id),
    ).fetchone()


@app.get("/system/support/tickets/{ticket_id}/messages")
async def system_support_ticket_messages(ticket_id: int, request: Request):
    row, user = _admin_support_user_from_request(request)
    user_id = int(row["id"])
    is_admin = bool(user.get("is_admin"))

    _admin_support_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row

        ticket = _support_get_ticket_for_user_or_admin(conn, ticket_id, user_id, is_admin)

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found.")

        messages = conn.execute(
            """
            SELECT
                m.id,
                m.ticket_id,
                m.sender_user_id,
                m.sender_role,
                m.body,
                m.created_at,
                u.email
            FROM support_messages m
            JOIN app_users u ON u.id = m.sender_user_id
            WHERE m.ticket_id = ?
            ORDER BY m.id ASC
            """,
            (ticket_id,),
        ).fetchall()

    return {
        "ok": True,
        "ticket": _admin_support_ticket_public(ticket),
        "messages": [
            {
                "id": m["id"],
                "ticket_id": m["ticket_id"],
                "sender_user_id": m["sender_user_id"],
                "sender_role": m["sender_role"],
                "sender_email": m["email"],
                "body": m["body"],
                "created_at": m["created_at"],
            }
            for m in messages
        ],
    }


@app.post("/system/support/tickets/{ticket_id}/messages")
async def system_support_ticket_reply(ticket_id: int, request: Request):
    row, user = _admin_support_user_from_request(request)
    user_id = int(row["id"])
    is_admin = bool(user.get("is_admin"))

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="JSON object required.")

    body = str(payload.get("body") or "").strip()
    status = str(payload.get("status") or "").strip().lower()

    if len(body) < 2:
        raise HTTPException(status_code=400, detail="Message must be at least 2 characters.")

    body = body[:5000]
    now = _auth_now_iso()

    _admin_support_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        ticket = _support_get_ticket_for_user_or_admin(conn, ticket_id, user_id, is_admin)

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found.")

        sender_role = "admin" if is_admin else "user"

        conn.execute(
            """
            INSERT INTO support_messages (
                ticket_id,
                sender_user_id,
                sender_role,
                body,
                created_at
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (ticket_id, user_id, sender_role, body, now),
        )

        next_status = ticket["status"]

        if status in ("waiting_admin", "waiting_user", "solved"):
            next_status = status
        elif is_admin:
            next_status = "waiting_user"
        else:
            next_status = "waiting_admin"

        conn.execute(
            """
            UPDATE support_tickets
            SET status = ?,
                updated_at = ?,
                closed_at = CASE WHEN ? = 'solved' THEN ? ELSE closed_at END
            WHERE id = ?
            """,
            (next_status, now, next_status, now, ticket_id),
        )

        conn.commit()

    return {
        "ok": True,
        "ticket_id": ticket_id,
        "status": next_status,
        "message": {
            "sender_role": sender_role,
            "body": body,
            "created_at": now,
        },
    }


# ============================================================

# STAGE_5P11N_RETENTION_POLICY_DRY_RUN_BEGIN
from datetime import timedelta as _stage5p11n_timedelta

def _retention_now():
    return datetime.now(timezone.utc)


def _retention_parse_dt(value):
    if not value:
        return None
    try:
        text = str(value).strip()
        if text.endswith("Z"):
            text = text[:-1] + "+00:00"
        dt = datetime.fromisoformat(text)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None


def _retention_cutoff_iso(days: int):
    days = max(1, int(days))
    return (_retention_now() - _stage5p11n_timedelta(days=days)).isoformat()


def _retention_user_days_for_plan(plan):
    plan_value = str(plan or "free").strip().lower()

    # Current policy:
    # - free/local users: 7 days of detailed history
    # - paid/pro users: future longer retention, defaulting to 30 days for now
    # This is dry-run only in Stage 5P-11N.
    if plan_value in {"pro", "paid", "plus", "enterprise"}:
        return int(os.getenv("AI_PLATFORM_PAID_DETAIL_RETENTION_DAYS", "30") or "30")

    return int(os.getenv("AI_PLATFORM_FREE_DETAIL_RETENTION_DAYS", "7") or "7")


def _retention_count_table(conn, table, where_sql="", params=()):
    try:
        row = conn.execute(
            f"SELECT COUNT(*) AS n FROM {table} {where_sql}",
            tuple(params),
        ).fetchone()
        return int(row["n"] if row and "n" in row.keys() else row[0])
    except Exception:
        return None


def _retention_table_exists(conn, table):
    row = conn.execute(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        (table,),
    ).fetchone()
    return bool(row)


def _retention_plan_rows():
    _auth_init_tables()
    _study_init_session_tables()

    detail_tables = [
        {
            "table": "study_session_events",
            "time_column": "created_at",
            "user_column": "user_id",
            "category": "study_detail",
            "note": "Per-card Study session event history. Safe to delete after rollup exists.",
        },
        {
            "table": "study_sessions",
            "time_column": "updated_at",
            "user_column": "user_id",
            "category": "study_detail",
            "extra_where": "status IN ('completed', 'stopped')",
            "note": "Completed/stopped Study session rows. Keep active sessions.",
        },
        {
            "table": "study_reviews",
            "time_column": "reviewed_at",
            "user_column": "user_id",
            "category": "study_detail",
            "note": "Detailed Study reviews. Delete only after cumulative study totals are proven.",
        },
        {
            "table": "jobs",
            "time_column": "updated_at",
            "user_column": "user_id",
            "category": "chat_queue_detail",
            "extra_where": "status IN ('completed', 'failed', 'cancelled')",
            "note": "Local queue job prompts/status rows.",
        },
        {
            "table": "job_results",
            "time_column": "updated_at",
            "user_column": None,
            "category": "chat_queue_detail",
            "note": "Local queue result text/json rows. Job ownership must be joined before deleting per plan.",
        },
        {
            "table": "web_presence",
            "time_column": "last_seen_at",
            "user_column": "user_id",
            "category": "presence_detail",
            "note": "Presence/activity history. Recent rows power live presence; old rows can be removed.",
        },
        {
            "table": "power_events",
            "time_column": "created_at",
            "user_column": None,
            "category": "system_detail",
            "system_retention_days": 7,
            "note": "System power event log.",
        },
        {
            "table": "web_power_policy_events",
            "time_column": "created_at",
            "user_column": None,
            "category": "system_detail",
            "system_retention_days": 7,
            "note": "Web presence power-policy event log.",
        },
        {
            "table": "worker_events",
            "time_column": "created_at",
            "user_column": None,
            "category": "system_detail",
            "system_retention_days": 7,
            "note": "Worker event log.",
        },
    ]

    with db() as conn:
        conn.row_factory = sqlite3.Row

        users = conn.execute(
            """
            SELECT id, email, plan, billing_status
            FROM app_users
            WHERE COALESCE(status, 'active') != 'deleted'
            ORDER BY id ASC
            """
        ).fetchall()

        user_policy = []
        for user in users:
            detail_days = _retention_user_days_for_plan(user["plan"])
            user_policy.append({
                "user_id": int(user["id"]),
                "email": user["email"],
                "plan": user["plan"] or "free",
                "billing_status": user["billing_status"],
                "detail_retention_days": detail_days,
                "cutoff": _retention_cutoff_iso(detail_days),
            })

        plan_rows = []

        for spec in detail_tables:
            table = spec["table"]
            time_column = spec["time_column"]

            if not _retention_table_exists(conn, table):
                plan_rows.append({
                    **spec,
                    "exists": False,
                    "total_rows": None,
                    "eligible_rows": None,
                    "eligible_by_plan": [],
                })
                continue

            total_rows = _retention_count_table(conn, table)
            eligible_by_plan = []
            eligible_total = 0

            if spec.get("user_column"):
                for policy in user_policy:
                    where_parts = [
                        f"{spec['user_column']} = ?",
                        f"{time_column} < ?",
                    ]
                    params = [policy["user_id"], policy["cutoff"]]

                    if spec.get("extra_where"):
                        where_parts.append(f"({spec['extra_where']})")

                    n = _retention_count_table(
                        conn,
                        table,
                        "WHERE " + " AND ".join(where_parts),
                        params,
                    )

                    n = int(n or 0)
                    eligible_total += n

                    if n:
                        eligible_by_plan.append({
                            "user_id": policy["user_id"],
                            "plan": policy["plan"],
                            "detail_retention_days": policy["detail_retention_days"],
                            "eligible_rows": n,
                            "cutoff": policy["cutoff"],
                        })
            else:
                days = int(spec.get("system_retention_days") or 7)
                cutoff = _retention_cutoff_iso(days)
                where_parts = [f"{time_column} < ?"]
                params = [cutoff]

                if spec.get("extra_where"):
                    where_parts.append(f"({spec['extra_where']})")

                eligible_total = int(_retention_count_table(
                    conn,
                    table,
                    "WHERE " + " AND ".join(where_parts),
                    params,
                ) or 0)

                eligible_by_plan.append({
                    "plan": "system",
                    "detail_retention_days": days,
                    "eligible_rows": eligible_total,
                    "cutoff": cutoff,
                })

            plan_rows.append({
                **spec,
                "exists": True,
                "total_rows": total_rows,
                "eligible_rows": eligible_total,
                "eligible_by_plan": eligible_by_plan,
            })

        return {
            "ok": True,
            "mode": "dry_run",
            "policy": {
                "free_detail_retention_days": int(os.getenv("AI_PLATFORM_FREE_DETAIL_RETENTION_DAYS", "7") or "7"),
                "paid_detail_retention_days": int(os.getenv("AI_PLATFORM_PAID_DETAIL_RETENTION_DAYS", "30") or "30"),
                "delete_enabled": False,
                "cumulative_totals_required_before_study_review_delete": True,
            },
            "users": user_policy,
            "tables": plan_rows,
        }


@app.get("/system/retention/dry-run")
@app.get("/api/system/retention/dry-run")
async def system_retention_dry_run(request: Request):
    await _require_admin(request)
    return _retention_plan_rows()
# STAGE_5P11N_RETENTION_POLICY_DRY_RUN_END



# Session presence heartbeat
# Lets the frontend keep logged-in users marked online.
# ============================================================

@app.post("/system/session/presence")
async def system_session_presence(request: Request):
    row = _auth_current_user_from_request(request)

    return {
        "ok": True,
        "user": _account_enriched_public_user(row) if "_account_enriched_public_user" in globals() else _auth_public_user(row),
        "seen_at": _auth_now_iso(),
    }


# ============================================================
# Support ticket status update
#
# Allows:
# - Ticket owner to mark their own ticket solved
# - Admin to mark any ticket solved
# - Admin/user can optionally reopen/update status where allowed
# ============================================================

@app.post("/system/support/tickets/{ticket_id}/status")
async def system_support_ticket_status(ticket_id: int, request: Request):
    row, user = _admin_support_user_from_request(request)
    user_id = int(row["id"])
    is_admin = bool(user.get("is_admin"))

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        payload = {}

    status = str(payload.get("status") or "").strip().lower()
    note = str(payload.get("note") or "").strip()

    if status not in ("waiting_admin", "waiting_user", "solved"):
        raise HTTPException(
            status_code=400,
            detail="status must be waiting_admin, waiting_user, or solved.",
        )

    # Normal users can solve or reopen their own ticket to waiting_admin.
    # Admins can set all supported statuses.
    if not is_admin and status == "waiting_user":
        raise HTTPException(
            status_code=403,
            detail="Only admins can set a ticket to waiting_user.",
        )

    _admin_support_init_tables()
    now = _auth_now_iso()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        ticket = _support_get_ticket_for_user_or_admin(conn, ticket_id, user_id, is_admin)

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found.")

        old_status = ticket["status"]
        sender_role = "admin" if is_admin else "user"

        if not note:
            if status == "solved":
                note = "Marked ticket as solved."
            elif status == "waiting_admin":
                note = "Reopened ticket. Waiting on admin."
            elif status == "waiting_user":
                note = "Waiting on user."

        conn.execute(
            """
            UPDATE support_tickets
            SET status = ?,
                updated_at = ?,
                closed_at = CASE WHEN ? = 'solved' THEN ? ELSE NULL END
            WHERE id = ?
            """,
            (status, now, status, now, ticket_id),
        )

        conn.execute(
            """
            INSERT INTO support_messages (
                ticket_id,
                sender_user_id,
                sender_role,
                body,
                created_at
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                ticket_id,
                user_id,
                sender_role,
                note[:5000],
                now,
            ),
        )

        conn.commit()

    return {
        "ok": True,
        "ticket_id": ticket_id,
        "old_status": old_status,
        "status": status,
        "message": {
            "sender_role": sender_role,
            "body": note[:5000],
            "created_at": now,
        },
    }


# ============================================================
# Safe idempotent session logout
#
# The older /system/session/logout endpoint is returning 500.
# This endpoint is intentionally forgiving:
# - no token => ok, revoked false
# - already revoked token => ok, revoked false
# - valid active token => ok, revoked true
# ============================================================

@app.post("/system/session/logout-safe")
async def system_session_logout_safe(request: Request):
    token = _auth_get_bearer_token(request)

    if not token:
        return {
            "ok": True,
            "revoked": False,
            "detail": "No token supplied.",
        }

    token_hash = _auth_hash_token(token)
    now = _auth_now_iso()

    _auth_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        cur = conn.execute(
            """
            UPDATE user_sessions
            SET revoked_at = ?,
                last_seen_at = ?
            WHERE token_hash = ?
              AND revoked_at IS NULL
            """,
            (now, now, token_hash),
        )
        conn.commit()

    return {
        "ok": True,
        "revoked": cur.rowcount > 0,
    }


# ============================================================
# Web presence driven power policy
#
# Goal:
# - Cloudflare/wrapper stays available.
# - Anonymous visitor active for 15s can request host wake.
# - Logged-in user active requests host + core containers.
# - No logged-in users + no jobs => containers can stop after grace.
# - No visitors + no jobs => host can shut down after grace.
#
# This first version is DRY RUN ONLY.
# It reports decisions without executing power actions.
# ============================================================

import hashlib as _web_presence_hashlib
import secrets as _web_presence_secrets
from datetime import datetime as _web_presence_datetime, timezone as _web_presence_timezone


def _web_presence_now():
    return _auth_now_iso()


def _web_presence_parse_dt(value):
    if not value:
        return None
    try:
        return _web_presence_datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None


def _web_presence_seconds_ago(value):
    dt = _web_presence_parse_dt(value)
    if not dt:
        return 999999999
    now = _web_presence_datetime.now(_web_presence_timezone.utc)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=_web_presence_timezone.utc)
    return max(0, int((now - dt).total_seconds()))


def _web_presence_init_tables():
    _auth_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS web_presence (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                visitor_id TEXT NOT NULL UNIQUE,
                user_id INTEGER,
                route TEXT,
                is_authenticated INTEGER NOT NULL DEFAULT 0,
                is_admin INTEGER NOT NULL DEFAULT 0,
                active_seconds INTEGER NOT NULL DEFAULT 0,
                visibility TEXT,
                first_seen_at TEXT NOT NULL,
                last_seen_at TEXT NOT NULL,
                user_agent_hash TEXT,
                ip_hash TEXT,
                metadata_json TEXT,
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )

        conn.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_web_presence_last_seen
            ON web_presence(last_seen_at)
            """
        )

        conn.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_web_presence_user
            ON web_presence(user_id)
            """
        )

        conn.commit()


def _web_presence_optional_user(request: Request):
    token = _auth_get_bearer_token(request)
    if not token:
        return None

    token_hash = _auth_hash_token(token)
    now = _auth_now_iso()

    _auth_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        row = conn.execute(
            """
            SELECT u.*
            FROM user_sessions s
            JOIN app_users u ON u.id = s.user_id
            WHERE s.token_hash = ?
              AND s.revoked_at IS NULL
              AND s.expires_at > ?
              AND COALESCE(u.status, 'active') = 'active'
            """,
            (token_hash, now),
        ).fetchone()

        if row:
            conn.execute(
                """
                UPDATE user_sessions
                SET last_seen_at = ?
                WHERE token_hash = ?
                """,
                (now, token_hash),
            )
            conn.commit()

        return row


def _web_presence_hash(value):
    if not value:
        return None

    salt = os.getenv("WEB_PRESENCE_HASH_SALT", "edge-presence-local-dev")
    raw = f"{salt}:{value}".encode("utf-8", errors="ignore")
    return _web_presence_hashlib.sha256(raw).hexdigest()


# STAGE_5P11S_PRESENCE_ROUTE_ALIASES_BEGIN
@app.post("/api/presence/web")
@app.post("/presence/web")
# STAGE_5P11S_PRESENCE_ROUTE_ALIASES_END
@app.post("/system/presence/web")
async def system_web_presence(request: Request):
    _web_presence_init_tables()

    try:
        payload = await request.json()
    except Exception:
        payload = {}

    if not isinstance(payload, dict):
        payload = {}

    visitor_id = str(payload.get("visitor_id") or "").strip()

    if not visitor_id:
        visitor_id = "srv-" + _web_presence_secrets.token_urlsafe(18)

    route = str(payload.get("route") or "/").strip()[:250]
    visibility = str(payload.get("visibility") or "").strip()[:50]
    active_seconds = int(payload.get("active_seconds") or 0)
    active_seconds = max(0, min(active_seconds, 24 * 60 * 60))

    metadata = payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {}

    user_row = _web_presence_optional_user(request)
    user_id = int(user_row["id"]) if user_row else None
    is_authenticated = 1 if user_row else 0

    role = str(user_row["role"] if user_row and "role" in user_row.keys() else "").lower() if user_row else ""
    is_admin = 1 if role == "admin" else 0

    now = _web_presence_now()
    user_agent = request.headers.get("user-agent", "")
    xff = request.headers.get("x-forwarded-for", "")
    client_host = getattr(request.client, "host", "") if request.client else ""

    user_agent_hash = _web_presence_hash(user_agent)
    ip_hash = _web_presence_hash(xff or client_host)

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            INSERT INTO web_presence (
                visitor_id,
                user_id,
                route,
                is_authenticated,
                is_admin,
                active_seconds,
                visibility,
                first_seen_at,
                last_seen_at,
                user_agent_hash,
                ip_hash,
                metadata_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(visitor_id) DO UPDATE SET
                user_id = excluded.user_id,
                route = excluded.route,
                is_authenticated = excluded.is_authenticated,
                is_admin = excluded.is_admin,
                active_seconds = MAX(web_presence.active_seconds, excluded.active_seconds),
                visibility = excluded.visibility,
                last_seen_at = excluded.last_seen_at,
                user_agent_hash = excluded.user_agent_hash,
                ip_hash = excluded.ip_hash,
                metadata_json = excluded.metadata_json
            """,
            (
                visitor_id,
                user_id,
                route,
                is_authenticated,
                is_admin,
                active_seconds,
                visibility,
                now,
                now,
                user_agent_hash,
                ip_hash,
                json.dumps(metadata),
            ),
        )
        conn.commit()

    return {
        "ok": True,
        "visitor_id": visitor_id,
        "user_id": user_id,
        "is_authenticated": bool(is_authenticated),
        "is_admin": bool(is_admin),
        "route": route,
        "active_seconds": active_seconds,
        "seen_at": now,
    }


def _web_presence_summary():
    _web_presence_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT *
            FROM web_presence
            ORDER BY last_seen_at DESC
            LIMIT 1000
            """
        ).fetchall()

    active_window = int(os.getenv("WEB_PRESENCE_ACTIVE_WINDOW_SECONDS", "180"))
    anon_wake_seconds = int(os.getenv("WEB_PRESENCE_ANON_WAKE_SECONDS", "15"))

    active_rows = []
    visible_rows = []
    auth_rows = []
    admin_rows = []
    anon_intent_rows = []

    for row in rows:
        age = _web_presence_seconds_ago(row["last_seen_at"])
        is_active = age <= active_window
        is_visible = str(row["visibility"] or "").lower() != "hidden"

        if is_active:
            active_rows.append(row)

        if is_active and is_visible:
            visible_rows.append(row)

        if is_active and is_visible and int(row["is_authenticated"] or 0) == 1:
            auth_rows.append(row)

        if is_active and is_visible and int(row["is_admin"] or 0) == 1:
            admin_rows.append(row)

        if (
            is_active
            and is_visible
            and int(row["is_authenticated"] or 0) == 0
            and int(row["active_seconds"] or 0) >= anon_wake_seconds
        ):
            anon_intent_rows.append(row)

    last_visitor_seen_at = rows[0]["last_seen_at"] if rows else None

    logged_in_rows = [
        row for row in rows
        if int(row["is_authenticated"] or 0) == 1
    ]
    last_logged_in_seen_at = logged_in_rows[0]["last_seen_at"] if logged_in_rows else None

    return {
        "active_window_seconds": active_window,
        "anonymous_wake_after_seconds": anon_wake_seconds,
        "total_seen": len(rows),
        "active_total": len(active_rows),
        "active_visible": len(visible_rows),
        "active_authenticated": len(auth_rows),
        "active_admin": len(admin_rows),
        "anonymous_wake_intent": len(anon_intent_rows),
        "last_visitor_seen_at": last_visitor_seen_at,
        "last_visitor_seen_seconds_ago": _web_presence_seconds_ago(last_visitor_seen_at) if last_visitor_seen_at else None,
        "last_logged_in_seen_at": last_logged_in_seen_at,
        "last_logged_in_seen_seconds_ago": _web_presence_seconds_ago(last_logged_in_seen_at) if last_logged_in_seen_at else None,
    }


def _web_presence_job_summary():
    # Best-effort placeholder. We will wire this to the real queue tables next.
    # Keep conservative defaults.
    return {
        "queued": 0,
        "running": 0,
        "source": "placeholder",
    }


def _web_presence_power_decision():
    presence = _web_presence_summary()
    jobs = _web_presence_job_summary()

    container_idle_seconds = int(os.getenv("WEB_POWER_CONTAINER_IDLE_SECONDS", "600"))
    host_idle_seconds = int(os.getenv("WEB_POWER_HOST_IDLE_SECONDS", "1500"))
    min_host_on_seconds = int(os.getenv("WEB_POWER_MIN_HOST_ON_SECONDS", "1200"))
    wake_debounce_seconds = int(os.getenv("WEB_POWER_WAKE_DEBOUNCE_SECONDS", "60"))

    queued_or_running = (jobs["queued"] + jobs["running"]) > 0
    active_authenticated = presence["active_authenticated"] > 0
    active_admin = presence["active_admin"] > 0
    anonymous_wake_intent = presence["anonymous_wake_intent"] > 0

    # RECENT_AUTH_CONTAINER_REQUIRED_V1
    # Private app pages live inside CT101. If CT101 stops, the private page can
    # no longer send heartbeats, so use the broader container idle window as a
    # grace period for recently logged-in users.
    last_logged_in_seen_seconds_ago = presence.get("last_logged_in_seen_seconds_ago")
    recent_authenticated = (
        last_logged_in_seen_seconds_ago is not None
        and last_logged_in_seen_seconds_ago <= container_idle_seconds
    )
    active_any = presence["active_visible"] > 0

    actions = []
    reasons = []

    host_required = False
    container_required = False
    desired_host_state = "not_required"
    desired_container_state = "not_required"

    if queued_or_running:
        host_required = True
        container_required = True
        desired_host_state = "online_or_booting"
        desired_container_state = "required_workers_online_or_starting"
        actions.extend(["keep_host_online", "keep_required_containers_online"])
        reasons.append("Jobs are queued or running.")

    elif active_authenticated or recent_authenticated:
        # Strongest user-experience rule:
        # if a logged-in user is recently active, the host should never remain offline.
        # It should be online or actively booting, and core app containers should be online/starting.
        host_required = True
        container_required = True
        desired_host_state = "online_or_booting"
        desired_container_state = "core_online_or_starting"
        actions.extend(["wake_host_if_needed", "start_core_containers_if_needed"])
        reasons.append("Logged-in user is active; host must be online or booting.")

    elif anonymous_wake_intent:
        host_required = True
        container_required = False
        desired_host_state = "online_or_booting"
        desired_container_state = "not_required_until_login_or_job"
        actions.append("wake_host_if_needed")
        reasons.append("Anonymous visitor stayed active long enough to show intent.")

    elif active_any:
        actions.append("keep_public_wrapper_only")
        reasons.append("Visitors are present but have not triggered wake intent.")

    else:
        last_login_age = presence["last_logged_in_seen_seconds_ago"]
        last_visitor_age = presence["last_visitor_seen_seconds_ago"]

        if last_login_age is not None and last_login_age >= container_idle_seconds:
            actions.append("stop_core_containers_if_no_jobs")
            reasons.append(f"No logged-in users for at least {container_idle_seconds} seconds.")

        if last_visitor_age is not None and last_visitor_age >= host_idle_seconds:
            actions.append("shutdown_host_if_min_on_elapsed_and_no_jobs")
            reasons.append(f"No visitors for at least {host_idle_seconds} seconds.")

        if not actions:
            actions.append("no_action")
            reasons.append("Idle grace periods have not elapsed.")

    # Admin is a blocker for shutdown/stop decisions.
    if active_admin and any(a.startswith("stop_") or a.startswith("shutdown_") for a in actions):
        actions = ["shutdown_blocked"]
        reasons.append("Admin is active.")

    return {
        "ok": True,
        "dry_run": not _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_SHUTDOWN"), False),
        "execute": _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_SHUTDOWN"), False),
        "policy": {
            "anonymous_wake_after_seconds": presence["anonymous_wake_after_seconds"],
            "container_idle_seconds": container_idle_seconds,
            "host_idle_seconds": host_idle_seconds,
            "min_host_on_seconds": min_host_on_seconds,
            "wake_debounce_seconds": wake_debounce_seconds,
            "note": "There is no minimum host-off time. New users can trigger wake immediately.",
        },
        "presence": presence,
        "jobs": jobs,
        "desired_state": {
            "host_required": host_required,
            "container_required": container_required,
            "desired_host_state": desired_host_state,
            "desired_container_state": desired_container_state,
            "shutdown_blocked": bool(active_admin or active_authenticated or recent_authenticated or queued_or_running),
            "shutdown_block_reason": (
                "admin_active" if active_admin
                else "logged_in_user_active" if (active_authenticated or recent_authenticated)
                else "job_active" if queued_or_running
                else None
            ),
        },
        "actions": actions,
        "reasons": reasons,
    }


@app.get("/system/presence/power-policy")
async def system_web_presence_power_policy(request: Request):
    return _web_presence_power_decision()


# ============================================================
# Apply web presence power policy
#
# First execution phase:
# - execute wake_host_if_needed only
# - keep container start/stop dry-run
# - keep host shutdown dry-run
#
# Execution is controlled by:
#   WEB_POWER_POLICY_EXECUTE_WAKE=1
# ============================================================


def _web_power_parse_bool(value, default=False):
    if value is None:
        return default

    if isinstance(value, bool):
        return value

    text = str(value).strip().lower()

    if text in ("1", "true", "yes", "y", "on", "enabled"):
        return True

    if text in ("0", "false", "no", "n", "off", "disabled"):
        return False

    return default

def _web_power_policy_init_tables():
    _web_presence_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS web_power_policy_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action TEXT NOT NULL,
                status TEXT NOT NULL,
                reason TEXT,
                result_json TEXT,
                created_at TEXT NOT NULL
            )
            """
        )
        conn.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_web_power_policy_events_action_created
            ON web_power_policy_events(action, created_at)
            """
        )
        conn.commit()


def _web_power_policy_last_event_seconds(action: str, statuses=("executed", "blocked", "dry_run")):
    _web_power_policy_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        placeholders = ",".join(["?"] * len(statuses))
        row = conn.execute(
            f"""
            SELECT created_at
            FROM web_power_policy_events
            WHERE action = ?
              AND status IN ({placeholders})
            ORDER BY created_at DESC
            LIMIT 1
            """,
            (action, *statuses),
        ).fetchone()

    if not row:
        return None

    return _web_presence_seconds_ago(row["created_at"])


def _web_power_policy_log_event(action: str, status: str, reason: str = "", result=None):
    _web_power_policy_init_tables()

    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            INSERT INTO web_power_policy_events (
                action,
                status,
                reason,
                result_json,
                created_at
            )
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                action,
                status,
                reason,
                json.dumps(result or {}),
                _auth_now_iso(),
            ),
        )
        conn.commit()



def _web_power_policy_pveso_state():
    """
    Best-effort pveso state check for web presence power policy.

    Returns:
      online  -> do not send WoL
      booting -> do not send WoL
      offline -> WoL may be useful
      unknown -> WoL may be useful, but include detail
    """
    try:
        booting_marker = _system_read_booting_marker()
    except Exception as e:
        booting_marker = {
            "active": False,
            "error": str(e),
        }

    try:
        host = _SYSTEM_PVESO_HOST
    except Exception:
        host = "pveso"

    try:
        raw_tcp_ssh = _system_tcp_check(host, 22, timeout=2)
    except Exception as e:
        raw_tcp_ssh = {
            "ok": False,
            "error": str(e),
        }

    if isinstance(raw_tcp_ssh, dict):
        tcp_ssh = raw_tcp_ssh
        tcp_ssh_ok = bool(raw_tcp_ssh.get("ok"))
    else:
        tcp_ssh_ok = bool(raw_tcp_ssh)
        tcp_ssh = {
            "ok": tcp_ssh_ok,
            "raw": raw_tcp_ssh,
        }

    if tcp_ssh_ok:
        try:
            ssh = _system_ssh_check()
        except Exception as e:
            ssh = {
                "ok": False,
                "stderr": str(e),
            }

        if isinstance(ssh, dict) and ssh.get("ok"):
            return {
                "state": "online",
                "detail": "pveso SSH is reachable.",
                "tcp_ssh": tcp_ssh,
                "ssh": ssh,
            }

    if booting_marker.get("active"):
        return {
            "state": "booting",
            "detail": f"Boot marker active. About {booting_marker.get('remaining_seconds')} seconds remaining.",
            "booting_marker": booting_marker,
        }

    return {
        "state": "offline",
        "detail": "pveso is not reachable and no boot marker is active.",
        "tcp_ssh": tcp_ssh,
        "booting_marker": booting_marker,
    }


@app.post("/system/presence/apply-power-policy")
async def system_apply_web_presence_power_policy(request: Request):
    try:
        return await _system_apply_web_presence_power_policy_impl(request)
    except Exception as e:
        error_payload = {
            "ok": False,
            "phase": "wake_only",
            "execute_flags": {
                "wake": _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_WAKE"), False),
                "containers": _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_CONTAINERS"), False),
                "shutdown": _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_SHUTDOWN"), False),
            },
            "executed": [],
            "skipped": [],
            "blocked": [
                {
                    "action": "apply_power_policy",
                    "reason": "Unhandled exception while applying web power policy.",
                    "error": str(e),
                }
            ],
            "results": {},
        }

        try:
            _web_power_policy_log_event(
                "apply_power_policy",
                "blocked",
                "Unhandled exception while applying web power policy.",
                error_payload,
            )
        except Exception:
            pass

        return error_payload


async def _system_apply_web_presence_power_policy_impl(request: Request):
    decision = _web_presence_power_decision()

    execute_wake = _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_WAKE"), False)
    execute_containers = _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_CONTAINERS"), False)
    execute_shutdown = _web_power_parse_bool(os.getenv("WEB_POWER_POLICY_EXECUTE_SHUTDOWN"), False)

    wake_debounce_seconds = int(os.getenv("WEB_POWER_WAKE_DEBOUNCE_SECONDS", "60"))

    actions = decision.get("actions") or []
    executed = []
    skipped = []
    blocked = []
    results = {}

    # Phase 1: only wake_host_if_needed may execute.
    if "wake_host_if_needed" in actions:
        last_wake_age = _web_power_policy_last_event_seconds(
            "wake_host_if_needed",
            statuses=("executed",),
        )

        if not execute_wake:
            skipped.append({
                "action": "wake_host_if_needed",
                "reason": "WEB_POWER_POLICY_EXECUTE_WAKE=0",
            })
            _web_power_policy_log_event(
                "wake_host_if_needed",
                "dry_run",
                "WEB_POWER_POLICY_EXECUTE_WAKE=0",
                {"decision": decision},
            )

        elif last_wake_age is not None and last_wake_age < wake_debounce_seconds:
            blocked.append({
                "action": "wake_host_if_needed",
                "reason": f"Wake debounce active. Last wake was {last_wake_age}s ago.",
                "remaining_seconds": wake_debounce_seconds - last_wake_age,
            })
            _web_power_policy_log_event(
                "wake_host_if_needed",
                "blocked",
                "Wake debounce active.",
                {
                    "last_wake_age": last_wake_age,
                    "wake_debounce_seconds": wake_debounce_seconds,
                },
            )

        else:
            pveso_state = _web_power_policy_pveso_state()
            results["pveso_state_before_wake"] = pveso_state

            if pveso_state.get("state") in ("online", "booting"):
                skipped.append({
                    "action": "wake_host_if_needed",
                    "reason": f"pveso is already {pveso_state.get('state')}.",
                    "pveso_state": pveso_state,
                })
                _web_power_policy_log_event(
                    "wake_host_if_needed",
                    "skipped",
                    f"pveso is already {pveso_state.get('state')}.",
                    pveso_state,
                )
            else:
                # Reuse existing pveso boot path because it sends WoL and marks booting.
                wake_result = system_boot_pveso({
                    "confirm": "BOOT_PVESO",
                    "source": "web_presence_power_policy",
                    "decision": {
                        "actions": actions,
                        "reasons": decision.get("reasons") or [],
                        "desired_state": decision.get("desired_state") or {},
                    },
                })

                results["wake_host_if_needed"] = wake_result

                if wake_result.get("boot_sent"):
                    executed.append("wake_host_if_needed")
                    _web_power_policy_log_event(
                        "wake_host_if_needed",
                        "executed",
                        "Wake sent by web presence power policy.",
                        wake_result,
                    )
                else:
                    blocked.append({
                        "action": "wake_host_if_needed",
                        "reason": wake_result.get("error") or wake_result.get("detail") or "Wake was not sent.",
                        "result": wake_result,
                    })
                    _web_power_policy_log_event(
                        "wake_host_if_needed",
                        "blocked",
                        "Wake was not sent.",
                        wake_result,
                    )

    dry_run_only_actions = [
        "start_core_containers_if_needed",
        "keep_required_containers_online",
        "stop_core_containers_if_no_jobs",
        "shutdown_host_if_min_on_elapsed_and_no_jobs",
        "keep_host_online",
    ]

    for action in dry_run_only_actions:
        if action in actions:
            skipped.append({
                "action": action,
                "reason": "This action remains dry-run in phase 1.",
            })

    return {
        "ok": True,
        "phase": "wake_only",
        "execute_flags": {
            "wake": execute_wake,
            "containers": execute_containers,
            "shutdown": execute_shutdown,
        },
        "decision": decision,
        "executed": executed,
        "skipped": skipped,
        "blocked": blocked,
        "results": results,
    }


# === Stage 5E-4: internal laptop-owned queue facade endpoints ===
#
# These endpoints are additive and internal-token protected.
# They are for synthetic testing only at this stage.
# They do not connect CT101 workers and do not change production queue behavior.

from typing import Any as _S5E4_Any
import hmac as _s5e4_hmac
import os as _s5e4_os
import time as _s5e4_time

from fastapi import Header as _S5E4_Header
from fastapi import HTTPException as _S5E4_HTTPException
from pydantic import BaseModel as _S5E4_BaseModel

from edge_modules.laptop_queue import LaptopQueueClient as _S5E4_LaptopQueueClient
from edge_modules.laptop_queue import LaptopQueueError as _S5E4_LaptopQueueError


_S5E4_TOKEN_ENV_FILE = _s5e4_os.path.expanduser(
    _s5e4_os.environ.get(
        "AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV",
        "~/.config/ai-platform-controller/internal-queue.env",
    )
)


def _s5e4_load_internal_queue_token() -> str | None:
    token = _s5e4_os.environ.get("LAPTOP_QUEUE_INTERNAL_TOKEN")
    if token:
        return token.strip()

    if not _s5e4_os.path.exists(_S5E4_TOKEN_ENV_FILE):
        return None

    try:
        with open(_S5E4_TOKEN_ENV_FILE, "r", encoding="utf-8") as fh:
            for raw_line in fh:
                line = raw_line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue

                key, value = line.split("=", 1)
                if key.strip() == "LAPTOP_QUEUE_INTERNAL_TOKEN":
                    return value.strip().strip('"').strip("'")
    except Exception:
        return None

    return None


def _s5e4_require_internal_queue_token(
    x_laptop_queue_token: str | None = _S5E4_Header(default=None),
) -> None:
    expected = _s5e4_load_internal_queue_token()

    if not expected:
        raise _S5E4_HTTPException(
            status_code=503,
            detail="Laptop queue internal token is not configured.",
        )

    if not x_laptop_queue_token:
        raise _S5E4_HTTPException(
            status_code=401,
            detail="Missing X-Laptop-Queue-Token header.",
        )

    if not _s5e4_hmac.compare_digest(str(x_laptop_queue_token), str(expected)):
        raise _S5E4_HTTPException(
            status_code=403,
            detail="Invalid laptop queue token.",
        )


def _s5e4_queue_client() -> _S5E4_LaptopQueueClient:
    try:
        return _S5E4_LaptopQueueClient()
    except _S5E4_LaptopQueueError as exc:
        raise _S5E4_HTTPException(status_code=503, detail=str(exc)) from exc


class _S5E4SyntheticSetupRequest(_S5E4_BaseModel):
    suffix: str | None = None
    job_type: str = "ollama_chat"
    requested_model: str = "stage-5e4-synthetic-model"


class _S5E4ClaimRequest(_S5E4_BaseModel):
    worker_id: str
    job_type: str | None = None


class _S5E4CompleteRequest(_S5E4_BaseModel):
    worker_id: str
    ok: bool = True
    result: dict[str, _S5E4_Any] | None = None
    error_text: str | None = None


class _S5E4CleanupRequest(_S5E4_BaseModel):
    user_id: str
    node_id: str
    worker_id: str
    job_ids: list[str]


@app.get("/internal/laptop-queue/summary")
async def s5e4_laptop_queue_summary(
    x_laptop_queue_token: str | None = _S5E4_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    try:
        grouped = client.psql_at(
            """
            SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
            FROM (
              SELECT job_type, status, COUNT(*)::int AS count
              FROM app_jobs
              GROUP BY job_type, status
              ORDER BY job_type, status
            ) t;
            """
        )
        workers = client.psql_at(
            """
            SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
            FROM (
              SELECT status, COUNT(*)::int AS count
              FROM app_workers
              GROUP BY status
              ORDER BY status
            ) t;
            """
        )
    except Exception as exc:
        raise _S5E4_HTTPException(status_code=500, detail=str(exc)) from exc

    import json as _s5e4_json

    return {
        "ok": True,
        "job_counts": _s5e4_json.loads(grouped or "[]"),
        "worker_counts": _s5e4_json.loads(workers or "[]"),
    }


@app.post("/internal/laptop-queue/synthetic/setup")
async def s5e4_laptop_queue_synthetic_setup(
    request: _S5E4SyntheticSetupRequest,
    x_laptop_queue_token: str | None = _S5E4_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)

    suffix = request.suffix or f"{int(_s5e4_time.time())}"
    user_id = f"s5e4-user-{suffix}"
    node_id = f"s5e4-node-{suffix}"
    worker_id = f"s5e4-worker-{suffix}"
    job_ok_id = f"s5e4-job-ok-{suffix}"
    job_fail_id = f"s5e4-job-fail-{suffix}"
    job_ids = [job_ok_id, job_fail_id]

    client = _s5e4_queue_client()

    try:
        client.cleanup_synthetic(
            user_id=user_id,
            node_id=node_id,
            worker_id=worker_id,
            job_ids=job_ids,
        )

        client.create_synthetic_user(
            user_id=user_id,
            email=f"{user_id}@example.local",
            display_name="Stage 5E-4 Synthetic User",
        )
        client.create_synthetic_worker_node(
            node_id=node_id,
            name="Stage 5E-4 Synthetic Node",
            capabilities={"job_types": [request.job_type]},
        )
        client.create_synthetic_worker(
            worker_id=worker_id,
            node_id=node_id,
            name="Stage 5E-4 Synthetic Worker",
            capabilities={"job_types": [request.job_type]},
        )

        client.create_job(
            job_id=job_ok_id,
            user_id=user_id,
            job_type=request.job_type,
            requested_model=request.requested_model,
            payload={"prompt": "stage 5e4 synthetic success job"},
        )
        client.create_job(
            job_id=job_fail_id,
            user_id=user_id,
            job_type=request.job_type,
            requested_model=request.requested_model,
            payload={"prompt": "stage 5e4 synthetic failed job"},
        )
    except Exception as exc:
        raise _S5E4_HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "ok": True,
        "ids": {
            "user_id": user_id,
            "node_id": node_id,
            "worker_id": worker_id,
            "job_ok_id": job_ok_id,
            "job_fail_id": job_fail_id,
            "job_ids": job_ids,
        },
    }


@app.post("/internal/laptop-queue/jobs/claim")
async def s5e4_laptop_queue_claim_job(
    request: _S5E4ClaimRequest,
    x_laptop_queue_token: str | None = _S5E4_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    try:
        job = client.claim_next_job(worker_id=request.worker_id, job_type=request.job_type)
    except Exception as exc:
        raise _S5E4_HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "ok": True,
        "job": job,
    }


@app.post("/internal/laptop-queue/jobs/{job_id}/complete")
async def s5e4_laptop_queue_complete_job(
    job_id: str,
    request: _S5E4CompleteRequest,
    x_laptop_queue_token: str | None = _S5E4_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    try:
        job = client.complete_job(
            job_id=job_id,
            worker_id=request.worker_id,
            ok=request.ok,
            result=request.result,
            error_text=request.error_text,
        )
    except Exception as exc:
        raise _S5E4_HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "ok": True,
        "job": job,
    }


@app.post("/internal/laptop-queue/synthetic/cleanup")
async def s5e4_laptop_queue_synthetic_cleanup(
    request: _S5E4CleanupRequest,
    x_laptop_queue_token: str | None = _S5E4_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    try:
        client.cleanup_synthetic(
            user_id=request.user_id,
            node_id=request.node_id,
            worker_id=request.worker_id,
            job_ids=request.job_ids,
        )
        leftovers = client.synthetic_leftover_count(
            user_id=request.user_id,
            node_id=request.node_id,
            worker_id=request.worker_id,
            job_ids=request.job_ids,
        )
    except Exception as exc:
        raise _S5E4_HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "ok": leftovers == 0,
        "leftover_count": leftovers,
    }


# === Stage 5E-15: internal laptop-owned queue worker register/heartbeat endpoints ===
#
# Additive internal-token protected endpoints.
# No recovery behavior yet.
# No schema changes.
# No persistent worker behavior.

import json as _s5e15_json
from typing import Any as _S5E15_Any

from fastapi import Header as _S5E15_Header
from fastapi import HTTPException as _S5E15_HTTPException
from pydantic import BaseModel as _S5E15_BaseModel


def _s5e15_sql_literal(value):
    if value is None:
        return "NULL"
    text = str(value)
    return "'" + text.replace("'", "''") + "'"


def _s5e15_jsonb_literal(value):
    return _s5e15_sql_literal(
        _s5e15_json.dumps(value, separators=(",", ":"), sort_keys=True)
    ) + "::jsonb"


class _S5E15WorkerRegisterRequest(_S5E15_BaseModel):
    worker_id: str
    name: str | None = None
    worker_node_id: str
    node_name: str | None = None
    node_type: str = "synthetic"
    host_machine: str = "ct101"
    tailscale_ip: str | None = None
    lan_ip: str | None = None
    capabilities: dict[str, _S5E15_Any] | None = None
    idle_shutdown_seconds: int | None = 300
    status: str = "idle"


class _S5E15WorkerHeartbeatRequest(_S5E15_BaseModel):
    worker_id: str
    worker_node_id: str | None = None
    status: str = "idle"
    current_job_id: str | None = None


def _s5e15_validate_worker_status(status: str) -> str:
    cleaned = (status or "").strip().lower()
    allowed = {"idle", "busy", "offline", "error"}
    if cleaned not in allowed:
        raise _S5E15_HTTPException(
            status_code=400,
            detail=f"Invalid worker status: {status}",
        )
    return cleaned


@app.post("/internal/laptop-queue/workers/register")
async def s5e15_laptop_queue_worker_register(
    request: _S5E15WorkerRegisterRequest,
    x_laptop_queue_token: str | None = _S5E15_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    status = _s5e15_validate_worker_status(request.status)
    worker_name = request.name or request.worker_id
    node_name = request.node_name or request.worker_node_id
    capabilities = request.capabilities or {"job_types": ["ollama_chat"]}
    idle_shutdown_seconds = request.idle_shutdown_seconds or 300

    try:
        raw = client.psql_at(
            f"""
            WITH node_upsert AS (
                INSERT INTO app_worker_nodes (
                    id,
                    name,
                    node_type,
                    host_machine,
                    tailscale_ip,
                    lan_ip,
                    enabled,
                    status,
                    capabilities,
                    notes,
                    last_seen_at,
                    created_at,
                    updated_at
                )
                VALUES (
                    {_s5e15_sql_literal(request.worker_node_id)},
                    {_s5e15_sql_literal(node_name)},
                    {_s5e15_sql_literal(request.node_type)},
                    {_s5e15_sql_literal(request.host_machine)},
                    {_s5e15_sql_literal(request.tailscale_ip)},
                    {_s5e15_sql_literal(request.lan_ip)},
                    TRUE,
                    'online',
                    {_s5e15_jsonb_literal(capabilities)},
                    'Registered through Stage 5E-15 laptop queue worker endpoint.',
                    now(),
                    now(),
                    now()
                )
                ON CONFLICT (id) DO UPDATE
                SET name = EXCLUDED.name,
                    node_type = EXCLUDED.node_type,
                    host_machine = EXCLUDED.host_machine,
                    tailscale_ip = EXCLUDED.tailscale_ip,
                    lan_ip = EXCLUDED.lan_ip,
                    enabled = TRUE,
                    status = 'online',
                    capabilities = EXCLUDED.capabilities,
                    last_seen_at = now(),
                    updated_at = now()
                RETURNING id
            ),
            worker_upsert AS (
                INSERT INTO app_workers (
                    id,
                    name,
                    status,
                    capabilities_json,
                    current_job_id,
                    worker_node_id,
                    last_heartbeat_at,
                    idle_shutdown_seconds,
                    created_at,
                    updated_at
                )
                VALUES (
                    {_s5e15_sql_literal(request.worker_id)},
                    {_s5e15_sql_literal(worker_name)},
                    {_s5e15_sql_literal(status)},
                    {_s5e15_jsonb_literal(capabilities)},
                    NULL,
                    {_s5e15_sql_literal(request.worker_node_id)},
                    now(),
                    {int(idle_shutdown_seconds)},
                    now(),
                    now()
                )
                ON CONFLICT (id) DO UPDATE
                SET name = EXCLUDED.name,
                    status = EXCLUDED.status,
                    capabilities_json = EXCLUDED.capabilities_json,
                    worker_node_id = EXCLUDED.worker_node_id,
                    last_heartbeat_at = now(),
                    idle_shutdown_seconds = EXCLUDED.idle_shutdown_seconds,
                    updated_at = now()
                RETURNING
                    id,
                    name,
                    status,
                    capabilities_json,
                    current_job_id,
                    worker_node_id,
                    last_heartbeat_at,
                    idle_shutdown_seconds,
                    created_at,
                    updated_at
            )
            SELECT COALESCE((SELECT row_to_json(w)::text FROM worker_upsert w), '');
            """
        )
    except Exception as exc:
        raise _S5E15_HTTPException(status_code=500, detail=str(exc)) from exc

    if not raw:
        raise _S5E15_HTTPException(status_code=500, detail="Worker registration returned no row.")

    return {
        "ok": True,
        "worker": _s5e15_json.loads(raw),
    }


@app.post("/internal/laptop-queue/workers/heartbeat")
async def s5e15_laptop_queue_worker_heartbeat(
    request: _S5E15WorkerHeartbeatRequest,
    x_laptop_queue_token: str | None = _S5E15_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    status = _s5e15_validate_worker_status(request.status)

    try:
        node_update = ""
        if request.worker_node_id:
            node_update = f"""
            UPDATE app_worker_nodes
            SET last_seen_at = now(),
                status = CASE WHEN enabled THEN 'online' ELSE status END,
                updated_at = now()
            WHERE id = {_s5e15_sql_literal(request.worker_node_id)};
            """

        raw = client.psql_at(
            f"""
            {node_update}

            WITH updated_worker AS (
                UPDATE app_workers
                SET status = {_s5e15_sql_literal(status)},
                    current_job_id = {_s5e15_sql_literal(request.current_job_id)},
                    last_heartbeat_at = now(),
                    updated_at = now()
                WHERE id = {_s5e15_sql_literal(request.worker_id)}
                RETURNING
                    id,
                    name,
                    status,
                    capabilities_json,
                    current_job_id,
                    worker_node_id,
                    last_heartbeat_at,
                    idle_shutdown_seconds,
                    created_at,
                    updated_at
            )
            SELECT COALESCE((SELECT row_to_json(w)::text FROM updated_worker w), '');
            """
        )
    except Exception as exc:
        raise _S5E15_HTTPException(status_code=500, detail=str(exc)) from exc

    if not raw:
        raise _S5E15_HTTPException(
            status_code=404,
            detail=f"Worker not found: {request.worker_id}",
        )

    return {
        "ok": True,
        "worker": _s5e15_json.loads(raw),
    }


# === Stage 5E-16: internal laptop-owned queue synthetic recovery endpoint ===
#
# Additive internal-token protected endpoint.
# Synthetic-safe recovery behavior.
# No schema changes.
# No persistent worker behavior.
# No requeue behavior yet.

import json as _s5e16_json

from fastapi import Header as _S5E16_Header
from fastapi import HTTPException as _S5E16_HTTPException
from pydantic import BaseModel as _S5E16_BaseModel


class _S5E16QueueRecoverRequest(_S5E16_BaseModel):
    stale_seconds: int = 120
    fail_stuck_jobs: bool = True
    synthetic_prefixes: list[str] | None = None


def _s5e16_safe_stale_seconds(value: int) -> int:
    try:
        seconds = int(value)
    except Exception:
        raise _S5E16_HTTPException(status_code=400, detail="stale_seconds must be an integer")

    if seconds < 1:
        raise _S5E16_HTTPException(status_code=400, detail="stale_seconds must be >= 1")

    if seconds > 86400:
        raise _S5E16_HTTPException(status_code=400, detail="stale_seconds must be <= 86400")

    return seconds


def _s5e16_safe_prefixes(prefixes: list[str] | None) -> list[str]:
    active = prefixes or ["s5e", "synthetic"]

    cleaned = []
    for item in active:
        text = str(item or "").strip()
        if not text:
            continue
        if len(text) > 64:
            raise _S5E16_HTTPException(status_code=400, detail="synthetic prefix too long")
        cleaned.append(text)

    if not cleaned:
        raise _S5E16_HTTPException(status_code=400, detail="at least one synthetic prefix is required")

    return cleaned


def _s5e16_prefix_sql(prefixes: list[str], column_name: str) -> str:
    clauses = []
    for prefix in prefixes:
        safe = prefix.replace("'", "''")
        clauses.append(f"{column_name} LIKE '{safe}%'")
    return "(" + " OR ".join(clauses) + ")"


@app.post("/internal/laptop-queue/recover")
async def s5e16_laptop_queue_recover(
    request: _S5E16QueueRecoverRequest,
    x_laptop_queue_token: str | None = _S5E16_Header(default=None, alias="X-Laptop-Queue-Token"),
):
    _s5e4_require_internal_queue_token(x_laptop_queue_token)
    client = _s5e4_queue_client()

    stale_seconds = _s5e16_safe_stale_seconds(request.stale_seconds)
    prefixes = _s5e16_safe_prefixes(request.synthetic_prefixes)
    job_prefix_sql = _s5e16_prefix_sql(prefixes, "j.id")
    worker_prefix_sql = _s5e16_prefix_sql(prefixes, "w.id")

    if not request.fail_stuck_jobs:
        raise _S5E16_HTTPException(
            status_code=400,
            detail="Stage 5E-16 only supports fail_stuck_jobs=true; requeue is postponed.",
        )

    try:
        raw = client.psql_at(
            f"""
            WITH stale_workers AS (
                SELECT
                    w.id,
                    w.current_job_id
                FROM app_workers w
                WHERE w.last_heartbeat_at IS NOT NULL
                  AND w.last_heartbeat_at < now() - make_interval(secs => {stale_seconds})
                  AND w.status <> 'offline'
                  AND {worker_prefix_sql}
            ),
            failed_jobs AS (
                UPDATE app_jobs j
                SET status = 'failed',
                    error_text = 'Recovered by Stage 5E-16: assigned worker heartbeat stale',
                    finished_at = COALESCE(j.finished_at, now()),
                    updated_at = now()
                FROM stale_workers sw
                WHERE j.status = 'running'
                  AND j.assigned_worker_id = sw.id
                  AND {job_prefix_sql}
                RETURNING j.id
            ),
            offline_workers AS (
                UPDATE app_workers w
                SET status = 'offline',
                    current_job_id = NULL,
                    updated_at = now()
                FROM stale_workers sw
                WHERE w.id = sw.id
                RETURNING w.id
            )
            SELECT json_build_object(
                'stale_worker_count', COALESCE((SELECT COUNT(*) FROM stale_workers), 0),
                'offline_worker_count', COALESCE((SELECT COUNT(*) FROM offline_workers), 0),
                'failed_job_count', COALESCE((SELECT COUNT(*) FROM failed_jobs), 0),
                'offline_worker_ids', COALESCE((SELECT json_agg(id) FROM offline_workers), '[]'::json),
                'failed_job_ids', COALESCE((SELECT json_agg(id) FROM failed_jobs), '[]'::json)
            )::text;
            """
        )
    except Exception as exc:
        raise _S5E16_HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "ok": True,
        "recovery": _s5e16_json.loads(raw or "{}"),
        "mode": "fail_stuck_jobs",
        "stale_seconds": stale_seconds,
        "synthetic_prefixes": prefixes,
    }


# === Stage 5F-9: synthetic-only queued chat route wiring ===
#
# Additive synthetic/test route wiring only.
# No default production chat behavior changes.
# No real production jobs are created.
# No assistant messages are persisted by these routes.

import json as _s5f9_json
import os as _s5f9_os

from fastapi import Header as _S5F9_Header
from fastapi import HTTPException as _S5F9_HTTPException
from pydantic import BaseModel as _S5F9_BaseModel

from edge_modules.chat_queue_creation import (
    ChatQueueCreationError as _S5F9_ChatQueueCreationError,
    create_synthetic_queued_chat_job as _s5f9_create_synthetic_queued_chat_job,
)
from edge_modules.chat_queue_persistence import (
    _psql_at as _s5f9_psql_at,
    _sql_literal as _s5f9_sql_literal,
)
from edge_modules.chat_queue_session_auth import (
    QueuedChatSessionAuthError as _S5F17_QueuedChatSessionAuthError,
    reject_client_provided_user_id as _s5f17_reject_client_provided_user_id,
    resolve_authenticated_user_from_session_token as _s5f17_resolve_authenticated_user_from_session_token,
)
from edge_modules.chat_queue_real_user_creation import (
    RealUserQueuedChatCreationError as _S5F19_RealUserQueuedChatCreationError,
    create_real_user_queued_chat_job as _s5f19_create_real_user_queued_chat_job,
    real_user_creation_helper_enabled as _s5f19_real_user_creation_helper_enabled,
)
from edge_modules.chat_queue_real_user_guard import (
    RealUserQueuedChatGuardError as _S5F20_RealUserQueuedChatGuardError,
    validate_real_user_queued_chat_status_request as _s5f20_validate_real_user_queued_chat_status_request,
)


class _S5F9QueuedChatRequest(_S5F9_BaseModel):
    message: str | None = None
    chat_id: str | None = None
    requested_model: str | None = None
    # STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1
    # Non-identity chat mode hint. Validated server-side before queued job creation.
    mode: str | None = None
    # Stage 5F-17: explicitly capture forbidden client user fields
    # so real-user queued chat can reject them instead of silently ignoring them.
    user_id: str | None = None
    authenticated_user_id: str | None = None


def _s5f9_laptop_chat_queue_enabled() -> bool:
    return _s5f9_os.environ.get("LAPTOP_CHAT_QUEUE_ENABLED", "").strip() == "1"


def _s5f9_laptop_chat_queue_synthetic_only() -> bool:
    return _s5f9_os.environ.get("LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY", "").strip() == "1"


def _s5f14_laptop_chat_queue_real_users_enabled() -> bool:
    return _s5f9_os.environ.get("LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED", "").strip() == "1"


def _s5f9_raise_feature_disabled() -> None:
    raise _S5F9_HTTPException(
        status_code=404,
        detail={
            "ok": False,
            "error": "feature_disabled",
            "feature": "laptop_queued_chat",
            "stage": "5f9",
            "message": "Laptop queued chat route is disabled.",
        },
    )


def _s5f9_require_synthetic_mode() -> None:
    if _s5f9_laptop_chat_queue_synthetic_only():
        return

    if _s5f14_laptop_chat_queue_real_users_enabled():
        raise _S5F9_HTTPException(
            status_code=501,
            detail={
                "ok": False,
                "error": "session_auth_not_wired_stage_5f14",
                "feature": "laptop_queued_chat",
                "stage": "5f14",
                "message": "Real-user queued chat guard exists, but session-derived auth is not wired yet.",
            },
        )

    raise _S5F9_HTTPException(
        status_code=501,
        detail={
            "ok": False,
            "error": "synthetic_only_required_stage_5f9",
            "feature": "laptop_queued_chat",
            "stage": "5f9",
            "message": "Queued chat is not implemented for production jobs yet.",
        },
    )



# STAGE_5G14_TRUSTED_CT101_IDENTITY_BRIDGE_V1
# Trusted-wrapper bridge for CT101-owned chat UI -> laptop-owned queued jobs.
# This does not trust client-provided identity. It only works when the wrapper
# supplies the shared EDGE_TRUSTED_PROXY_SECRET and X-Edge-* identity headers.
def _s5g14_truthy(value):
    return str(value or "").strip().lower() in {"1", "true", "yes", "on"}


def _s5g14_validate_trusted_edge_identity(
    *,
    x_edge_auth_secret,
    x_edge_user_id,
    x_edge_user_email,
    x_edge_user_is_admin,
):
    expected = os.getenv("EDGE_TRUSTED_PROXY_SECRET", "").strip()
    supplied = str(x_edge_auth_secret or "").strip()

    if not expected or not supplied or supplied != expected:
        return None

    ct101_user_id = str(x_edge_user_id or "").strip()
    email = str(x_edge_user_email or "").strip().lower()

    if not ct101_user_id or not email:
        return None

    # Namespace mirrored CT101 identities inside the laptop DB so this bridge
    # does not overwrite native laptop users that may share the same email.
    laptop_user_id = "ct101:" + ct101_user_id
    display_name = email.split("@", 1)[0] if "@" in email else email

    return {
        "id": laptop_user_id,
        "ct101_user_id": ct101_user_id,
        "email": email,
        "display_name": display_name,
        "is_admin": _s5g14_truthy(x_edge_user_is_admin),
    }



# STAGE_5H3_TRUSTED_CT101_QUEUED_AUTH_USER_V1
# Trusted CT101 wrapper requests must create/status-check queued jobs as the
# mirrored CT101 laptop user after EDGE_TRUSTED_PROXY_SECRET is validated.
# This keeps server-side ownership aligned with the mirrored CT101 chat row.
class _S5G14TrustedQueuedAuthUser:
    def __init__(self, *, user_id, session_id, email=None):
        self.user_id = user_id
        self.session_id = session_id
        self.email = email


def _s5g14_trusted_queued_auth_user(trusted_user):
    return _S5G14TrustedQueuedAuthUser(
        user_id=trusted_user["id"],
        session_id="ct101-edge-session-" + trusted_user["ct101_user_id"],
        email=trusted_user.get("email"),
    )

def _s5g14_mirror_trusted_edge_user_session(
    *,
    trusted_user,
    session_token,
):
    if not trusted_user:
        return False

    session_token = str(session_token or "").strip()
    if not session_token:
        return False

    from edge_modules.chat_queue_persistence import _psql_run, _psql_at, _sql_literal
    from edge_modules.chat_queue_session_auth import hash_session_token

    session_id = "ct101-edge-session-" + trusted_user["ct101_user_id"]
    token_hash = hash_session_token(session_token)

    # STAGE_5H3_CT101_MIRROR_EMAIL_NORMALIZE_V1
    email = str(trusted_user.get("email") or "").strip()
    if not email:
        email = str(trusted_user.get("ct101_user_id") or "ct101-user") + "@ct101.local"


    # STAGE_5H3_CT101_MIRROR_EMAIL_COLLISION_GUARD_V1
    # The laptop may already have the source browser user with the same email.
    # The mirrored CT101 user is a separate server-derived namespace identity,
    # so give it a deterministic non-colliding synthetic email if needed.
    ct101_source_id = str(trusted_user.get("ct101_user_id") or "ct101-user").strip() or "ct101-user"
    synthetic_email = "ct101+" + ct101_source_id.replace("@", "_at_").replace(" ", "_") + "@ct101.local"
    email_exists_for_other_user = _psql_at(
        f"""
        SELECT CASE WHEN EXISTS (
          SELECT 1
          FROM app_users
          WHERE email = {_sql_literal(email)}
            AND id <> {_sql_literal(trusted_user["id"])}
        )
        THEN '1' ELSE '' END;
        """
    )
    if email_exists_for_other_user:
        email = synthetic_email

    _psql_run(
        f"""
        BEGIN;

        INSERT INTO app_users (
          id,
          email,
          display_name,
          password_hash,
          is_active,
          is_admin,
          created_at,
          updated_at
        )
        VALUES (
          {_sql_literal(trusted_user["id"])},
          {_sql_literal(email)},
          {_sql_literal(trusted_user.get("display_name") or "")},
          NULL,
          TRUE,
          {'TRUE' if trusted_user.get("is_admin") else 'FALSE'},
          now(),
          now()
        )
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            display_name = EXCLUDED.display_name,
            is_active = TRUE,
            is_admin = EXCLUDED.is_admin,
            updated_at = now();

        -- STAGE_5G16_TRUSTED_REFRESH_RECLAIM_TOKEN_HASH_V1
        -- Reclaim this CT101 browser token from any stale mirrored session
        -- before inserting/updating the trusted refreshed session.
        DELETE FROM app_sessions
        WHERE token_hash = {_sql_literal(token_hash)}
          AND id <> {_sql_literal(session_id)};

        INSERT INTO app_sessions (
          id,
          user_id,
          token_hash,
          created_at,
          expires_at,
          revoked_at
        )
        VALUES (
          {_sql_literal(session_id)},
          {_sql_literal(trusted_user["id"])},
          {_sql_literal(token_hash)},
          now(),
          now() + interval '12 hours',
          NULL
        )
        ON CONFLICT (id) DO UPDATE
        SET user_id = EXCLUDED.user_id,
            token_hash = EXCLUDED.token_hash,
            expires_at = EXCLUDED.expires_at,
            revoked_at = NULL;

        COMMIT;
        """
    )

    return True


def _s5g14_mirror_trusted_edge_chat(
    *,
    trusted_user,
    chat_id,
    requested_model=None,
    mode=None,
):
    if not trusted_user:
        return False

    chat_id = str(chat_id or "").strip()
    if not chat_id:
        return False

    from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

    model = str(requested_model or "").strip() or "gemma4:e4b"

    # STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1
    # Preserve only allowed chat modes. This value is not identity and does not
    # replace server-side user/session ownership checks.
    clean_mode = str(mode or "chat").strip().lower()
    if clean_mode not in {"chat", "companion"}:
        clean_mode = "chat"

    title = "CT101 Companion" if clean_mode == "companion" else "CT101 Chat"

    _psql_run(
        f"""
        INSERT INTO app_chats (
          id,
          user_id,
          mode,
          title,
          model,
          created_at,
          updated_at,
          deleted_at
        )
        VALUES (
          {_sql_literal(chat_id)},
          {_sql_literal(trusted_user["id"])},
          {_sql_literal(clean_mode)},
          {_sql_literal(title)},
          {_sql_literal(model)},
          now(),
          now(),
          NULL
        )
        ON CONFLICT (id) DO UPDATE
        SET user_id = EXCLUDED.user_id,
            mode = EXCLUDED.mode,
            title = EXCLUDED.title,
            model = COALESCE(EXCLUDED.model, app_chats.model),
            updated_at = now(),
            deleted_at = NULL;
        """
    )

    return True


# STAGE_5P10B_COMPANION_QUEUE_STATUS_BEGIN
def _stage5p10b_table_columns(conn, table_name: str):
    try:
        return [str(row["name"]) for row in conn.execute(f"PRAGMA table_info({table_name})").fetchall()]
    except Exception:
        return []


def _stage5p10b_pick_column(columns, candidates):
    column_set = set(columns or [])
    for candidate in candidates:
        if candidate in column_set:
            return candidate
    return None


def _stage5p10b_safe_count(conn, sql, params=()):
    try:
        row = conn.execute(sql, params).fetchone()
        if row is None:
            return 0
        if isinstance(row, dict):
            return int(row.get("n") or 0)
        return int(row[0] or 0)
    except Exception:
        return 0


@app.get("/api/chat/queue/status")
@app.get("/public/chat/queue/status")
async def public_chat_queue_status(request: Request):
    user_row = _auth_current_user_from_request(request)
    requested_job_id = str(request.query_params.get("job_id") or "").strip()

    with db() as conn:
        columns = _stage5p10b_table_columns(conn, "jobs")

        if not columns:
            return {
                "ok": True,
                "queue": {
                    "waiting_count": 0,
                    "running_count": 0,
                    "total_active": 0,
                },
                "job": None,
                "note": "jobs table is not available",
            }

        status_col = _stage5p10b_pick_column(columns, ("status", "state", "job_status"))
        id_col = _stage5p10b_pick_column(columns, ("id", "job_id"))
        created_col = _stage5p10b_pick_column(columns, ("created_at", "created_ts", "created", "submitted_at", "updated_at", "id"))
        user_col = _stage5p10b_pick_column(columns, ("user_id", "owner_user_id", "account_id"))
        job_type_col = _stage5p10b_pick_column(columns, ("job_type", "type", "kind"))

        if not status_col or not id_col:
            return {
                "ok": True,
                "queue": {
                    "waiting_count": 0,
                    "running_count": 0,
                    "total_active": 0,
                },
                "job": None,
                "note": "jobs table does not expose status/id columns",
            }

        waiting_count = _stage5p10b_safe_count(
            conn,
            f"SELECT COUNT(*) AS n FROM jobs WHERE {status_col} IN ('queued', 'pending')",
        )
        running_count = _stage5p10b_safe_count(
            conn,
            f"SELECT COUNT(*) AS n FROM jobs WHERE {status_col} IN ('running', 'claimed', 'processing', 'in_progress')",
        )
        total_active = _stage5p10b_safe_count(
            conn,
            f"SELECT COUNT(*) AS n FROM jobs WHERE {status_col} IN ('queued', 'pending', 'running', 'claimed', 'processing', 'in_progress')",
        )

        order_col = created_col or id_col
        queued_rows = conn.execute(
            f"SELECT * FROM jobs WHERE {status_col} IN ('queued', 'pending') ORDER BY {order_col} ASC, {id_col} ASC"
        ).fetchall()

        job_payload = None
        if requested_job_id:
            id_candidates = [id_col]
            for extra in ("job_id", "public_id", "external_id", "request_id"):
                if extra in columns and extra not in id_candidates:
                    id_candidates.append(extra)

            job_row = None
            for col in id_candidates:
                try:
                    job_row = conn.execute(
                        f"SELECT * FROM jobs WHERE CAST({col} AS TEXT) = ? LIMIT 1",
                        (requested_job_id,),
                    ).fetchone()
                except Exception:
                    job_row = None
                if job_row:
                    break

            if job_row:
                job_dict = row_to_dict(job_row)
                job_status = str(job_dict.get(status_col) or "").lower()
                position = None
                ahead_count = None

                if job_status in ("queued", "pending"):
                    ahead_count = 0
                    for idx, row in enumerate(queued_rows, start=1):
                        row_dict = row_to_dict(row)
                        if str(row_dict.get(id_col)) == str(job_dict.get(id_col)):
                            position = idx
                            ahead_count = idx - 1
                            break

                    if position is None:
                        position = waiting_count
                        ahead_count = max(0, waiting_count - 1)

                job_payload = {
                    "job_id": str(job_dict.get(id_col) or requested_job_id),
                    "requested_job_id": requested_job_id,
                    "status": job_status or "unknown",
                    "position": position,
                    "ahead_count": ahead_count,
                    "user_id": job_dict.get(user_col) if user_col else None,
                    "job_type": job_dict.get(job_type_col) if job_type_col else None,
                }
            else:
                job_payload = {
                    "job_id": requested_job_id,
                    "requested_job_id": requested_job_id,
                    "status": "not_found",
                    "position": None,
                    "ahead_count": None,
                }

    # STAGE_5P10F_REAL_USER_QUEUE_STATUS_BRIDGE_BEGIN
    # Stage 5P-10B originally counted/looked up the older SQLite jobs table.
    # Real-user Companion jobs are created through the Stage 5F-18/5F-19 app_jobs path
    # and use ids like s5f18-job-....
    try:
        raw_counts = _s5f9_psql_at(
            """
            SELECT COALESCE(
              (
                SELECT row_to_json(x)::text
                FROM (
                  SELECT
                    (
                      SELECT COUNT(*)
                      FROM app_jobs
                      WHERE status IN ('queued', 'pending')
                    ) AS waiting_count,
                    (
                      SELECT COUNT(*)
                      FROM app_jobs
                      WHERE status IN ('running', 'claimed', 'processing', 'in_progress')
                    ) AS running_count,
                    (
                      SELECT COUNT(*)
                      FROM app_jobs
                      WHERE status IN ('queued', 'pending', 'running', 'claimed', 'processing', 'in_progress')
                    ) AS total_active
                ) x
              ),
              ''
            );
            """
        )

        if raw_counts:
            parsed_counts = _s5f9_json.loads(raw_counts)
            waiting_count += int(parsed_counts.get("waiting_count") or 0)
            running_count += int(parsed_counts.get("running_count") or 0)
            total_active += int(parsed_counts.get("total_active") or 0)
    except Exception:
        pass

    if requested_job_id and (
        not job_payload
        or str((job_payload or {}).get("status") or "").lower() == "not_found"
    ):
        try:
            raw_job = _s5f9_psql_at(
                f"""
                WITH queued AS (
                  SELECT
                    id,
                    row_number() OVER (ORDER BY created_at ASC, id ASC) AS position
                  FROM app_jobs
                  WHERE status IN ('queued', 'pending')
                )
                SELECT COALESCE(
                  (
                    SELECT row_to_json(x)::text
                    FROM (
                      SELECT
                        j.id AS job_id,
                        j.id AS requested_job_id,
                        j.status AS status,
                        q.position AS position,
                        CASE
                          WHEN q.position IS NULL THEN NULL
                          ELSE q.position - 1
                        END AS ahead_count,
                        j.user_id AS user_id,
                        j.job_type AS job_type,
                        j.requested_model AS requested_model
                      FROM app_jobs j
                      LEFT JOIN queued q
                        ON q.id = j.id
                      WHERE j.id = {_s5f9_sql_literal(requested_job_id)}
                      LIMIT 1
                    ) x
                  ),
                  ''
                );
                """
            )

            if raw_job:
                parsed_job = _s5f9_json.loads(raw_job)
                job_payload = {
                    "job_id": str(parsed_job.get("job_id") or requested_job_id),
                    "requested_job_id": requested_job_id,
                    "status": str(parsed_job.get("status") or "unknown").lower(),
                    "position": parsed_job.get("position"),
                    "ahead_count": parsed_job.get("ahead_count"),
                    "user_id": parsed_job.get("user_id"),
                    "job_type": parsed_job.get("job_type"),
                    "requested_model": parsed_job.get("requested_model"),
                    "source": "app_jobs",
                }
        except Exception:
            pass
    # STAGE_5P10F_REAL_USER_QUEUE_STATUS_BRIDGE_END

    return {
        "ok": True,
        "queue": {
            "waiting_count": int(waiting_count),
            "running_count": int(running_count),
            "total_active": int(total_active),
        },
        "job": job_payload,
        "user": {
            "id": int(user_row["id"]),
        },
    }
# STAGE_5P10B_COMPANION_QUEUE_STATUS_END




# STAGE_5P10E_NATIVE_QUEUE_SESSION_BRIDGE_BEGIN
def _s5p10e_native_queue_auth_user_from_session_token(session_token: str | None):
    clean_token = str(session_token or "").strip()
    if not clean_token:
        return None

    try:
        token_hash = _auth_hash_token(clean_token)
        with sqlite3.connect(DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT
                    s.id AS native_session_id,
                    s.user_id AS native_user_id,
                    u.email AS email,
                    COALESCE(u.display_name, '') AS display_name,
                    COALESCE(u.role, '') AS role,
                    COALESCE(u.status, '') AS status
                FROM user_sessions s
                JOIN app_users u
                  ON u.id = s.user_id
                WHERE s.token_hash = ?
                  AND s.revoked_at IS NULL
                  AND s.expires_at > ?
                  AND u.status = 'active'
                LIMIT 1
                """,
                (token_hash, _auth_now_iso()),
            ).fetchone()
    except Exception:
        row = None

    if not row:
        return None

    from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
    from edge_modules.chat_queue_session_auth import hash_session_token

    native_user_id = str(row["native_user_id"])
    queue_user_id = "native:" + native_user_id
    queue_session_id = "native-edge-session-" + str(row["native_session_id"])
    email = str(row["email"] or f"native+{native_user_id}@local").strip()
    display_name = str(row["display_name"] or email.split("@", 1)[0]).strip()
    is_admin = str(row["role"] or "").strip().lower() == "admin"
    queue_token_hash = hash_session_token(clean_token)

    _psql_run(
        f"""
        BEGIN;

        INSERT INTO app_users (
          id,
          email,
          display_name,
          password_hash,
          is_active,
          is_admin,
          created_at,
          updated_at
        )
        VALUES (
          {_sql_literal(queue_user_id)},
          {_sql_literal(email)},
          {_sql_literal(display_name)},
          NULL,
          TRUE,
          {'TRUE' if is_admin else 'FALSE'},
          now(),
          now()
        )
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            display_name = EXCLUDED.display_name,
            is_active = TRUE,
            is_admin = EXCLUDED.is_admin,
            updated_at = now();

        DELETE FROM app_sessions
        WHERE token_hash = {_sql_literal(queue_token_hash)}
          AND id <> {_sql_literal(queue_session_id)};

        INSERT INTO app_sessions (
          id,
          user_id,
          token_hash,
          created_at,
          expires_at,
          revoked_at
        )
        VALUES (
          {_sql_literal(queue_session_id)},
          {_sql_literal(queue_user_id)},
          {_sql_literal(queue_token_hash)},
          now(),
          now() + interval '12 hours',
          NULL
        )
        ON CONFLICT (id) DO UPDATE
        SET user_id = EXCLUDED.user_id,
            token_hash = EXCLUDED.token_hash,
            expires_at = EXCLUDED.expires_at,
            revoked_at = NULL;

        COMMIT;
        """
    )

    return _S5G14TrustedQueuedAuthUser(
        user_id=queue_user_id,
        session_id=queue_session_id,
        email=email,
    )


def _s5p10e_resolve_queue_auth_user(session_token: str | None):
    try:
        return _s5f17_resolve_authenticated_user_from_session_token(
            session_token=session_token
        )
    except _S5F17_QueuedChatSessionAuthError:
        native_user = _s5p10e_native_queue_auth_user_from_session_token(session_token)
        if native_user:
            return native_user

        raise
# STAGE_5P10E_NATIVE_QUEUE_SESSION_BRIDGE_END



@app.post("/api/chat/queued")
async def s5f9_create_queued_chat(
    request: _S5F9QueuedChatRequest,
    x_synthetic_user_id: str | None = _S5F9_Header(default=None, alias="X-Synthetic-User-Id"),
    x_queued_chat_session_token: str | None = _S5F9_Header(default=None, alias="X-Queued-Chat-Session-Token"),
    x_edge_auth_secret: str | None = _S5F9_Header(default=None, alias="X-Edge-Auth-Secret"),
    x_edge_user_id: str | None = _S5F9_Header(default=None, alias="X-Edge-User-Id"),
    x_edge_user_email: str | None = _S5F9_Header(default=None, alias="X-Edge-User-Email"),
    x_edge_user_is_admin: str | None = _S5F9_Header(default=None, alias="X-Edge-User-Is-Admin"),
):
    if not _s5f9_laptop_chat_queue_enabled():
        _s5f9_raise_feature_disabled()

    if not _s5f9_laptop_chat_queue_synthetic_only() and _s5f14_laptop_chat_queue_real_users_enabled():
        try:
            guard_payload = request.model_dump(exclude_none=True)

            # Stage 5F-17: Pydantic includes optional fields as None by default.
            # Only reject forbidden user fields when the client actually sent them.
            request_fields = getattr(request, "model_fields_set", set())
            if "user_id" in request_fields:
                guard_payload["user_id"] = request.user_id
            if "authenticated_user_id" in request_fields:
                guard_payload["authenticated_user_id"] = request.authenticated_user_id

            _s5f17_reject_client_provided_user_id(guard_payload)
            # STAGE_5G16_PREAUTH_TRUSTED_CT101_REFRESH_V1
            # If the request arrived through the trusted wrapper, refresh the
            # mirrored CT101 user/session/chat before resolving ownership.
            # This avoids stale token->user or chat->user rows from older
            # bridge attempts while still requiring the shared trusted secret.
            trusted_user_for_refresh = _s5g14_validate_trusted_edge_identity(
                x_edge_auth_secret=x_edge_auth_secret,
                x_edge_user_id=x_edge_user_id,
                x_edge_user_email=x_edge_user_email,
                x_edge_user_is_admin=x_edge_user_is_admin,
            )
            if trusted_user_for_refresh:
                _s5g14_mirror_trusted_edge_user_session(
                    trusted_user=trusted_user_for_refresh,
                    session_token=x_queued_chat_session_token,
                )
                _s5g14_mirror_trusted_edge_chat(
                    trusted_user=trusted_user_for_refresh,
                    chat_id=guard_payload.get("chat_id"),
                    requested_model=guard_payload.get("requested_model") or guard_payload.get("model"),
                    mode=guard_payload.get("mode"),
                )

            # STAGE_5H3_TRUSTED_CT101_AUTH_OWNER_PREFERENCE_V1
            # Prefer trusted CT101 mirrored ownership over local session ownership
            # when the wrapper supplied valid trusted CT101 identity headers.
            if trusted_user_for_refresh:
                auth_user = _s5g14_trusted_queued_auth_user(trusted_user_for_refresh)
            else:
                auth_user = _s5p10e_resolve_queue_auth_user(
                    session_token=x_queued_chat_session_token
                )
        except _S5F17_QueuedChatSessionAuthError as exc:
            trusted_user = _s5g14_validate_trusted_edge_identity(
                x_edge_auth_secret=x_edge_auth_secret,
                x_edge_user_id=x_edge_user_id,
                x_edge_user_email=x_edge_user_email,
                x_edge_user_is_admin=x_edge_user_is_admin,
            )

            if trusted_user:
                _s5g14_mirror_trusted_edge_user_session(
                    trusted_user=trusted_user,
                    session_token=x_queued_chat_session_token,
                )
                _s5g14_mirror_trusted_edge_chat(
                    trusted_user=trusted_user,
                    chat_id=guard_payload.get("chat_id"),
                    requested_model=guard_payload.get("requested_model") or guard_payload.get("model"),
                    mode=guard_payload.get("mode"),
                )

                auth_user = _s5g14_trusted_queued_auth_user(trusted_user)
            else:
                raise _S5F9_HTTPException(
                    status_code=401,
                    detail={
                        "ok": False,
                        "error": "queued_chat_session_auth_failed_stage_5f17",
                        "feature": "laptop_queued_chat",
                        "stage": "5f17",
                        "message": str(exc),
                    },
                ) from exc

        if _s5f19_real_user_creation_helper_enabled():
            try:
                queued = _s5f19_create_real_user_queued_chat_job(
                    authenticated_user_id=auth_user.user_id,
                    payload=guard_payload,
                )
            except _S5F19_RealUserQueuedChatCreationError as exc:
                raise _S5F9_HTTPException(
                    status_code=400,
                    detail={
                        "ok": False,
                        "error": "real_user_queued_chat_creation_failed_stage_5f19",
                        "feature": "laptop_queued_chat",
                        "stage": "5f19",
                        "message": str(exc),
                    },
                ) from exc

            return {
                "ok": True,
                "stage": "5f19",
                "route_source": "stage_5f19_real_user_route",
                "real_user": True,
                "job_id": queued.job_id,
                "status": queued.status,
                "chat_id": queued.chat_id,
                "user_message_id": queued.user_message_id,
                "payload_json": queued.payload_json,
            }

        raise _S5F9_HTTPException(
            status_code=501,
            detail={
                "ok": False,
                "error": "real_user_job_creation_not_wired_stage_5f17",
                "feature": "laptop_queued_chat",
                "stage": "5f17",
                "authenticated_user_id": auth_user.user_id,
                "message": "Session auth resolved, but real-user queued job creation is not wired yet.",
            },
        )

    _s5f9_require_synthetic_mode()

    if not x_synthetic_user_id:
        raise _S5F9_HTTPException(
            status_code=400,
            detail={
                "ok": False,
                "error": "missing_synthetic_user_id",
                "stage": "5f9",
            },
        )

    try:
        queued = _s5f9_create_synthetic_queued_chat_job(
            authenticated_user_id=x_synthetic_user_id,
            message=request.message or "",
            chat_id=request.chat_id,
            requested_model=request.requested_model or "synthetic",
        )
    except _S5F9_ChatQueueCreationError as exc:
        raise _S5F9_HTTPException(
            status_code=400,
            detail={
                "ok": False,
                "error": "queued_chat_creation_failed",
                "stage": "5f9",
                "message": str(exc),
            },
        ) from exc

    return {
        "ok": True,
        "stage": "5f9",
        "synthetic_only": True,
        "job_id": queued.job_id,
        "status": queued.status,
        "chat_id": queued.chat_id,
        "user_message_id": queued.user_message_id,
        "payload_json": queued.payload_json,
    }


@app.get("/api/chat/queued/{job_id}")
async def s5f9_get_queued_chat_status(
    job_id: str,
    x_queued_chat_session_token: str | None = _S5F9_Header(default=None, alias="X-Queued-Chat-Session-Token"),
    x_edge_auth_secret: str | None = _S5F9_Header(default=None, alias="X-Edge-Auth-Secret"),
    x_edge_user_id: str | None = _S5F9_Header(default=None, alias="X-Edge-User-Id"),
    x_edge_user_email: str | None = _S5F9_Header(default=None, alias="X-Edge-User-Email"),
    x_edge_user_is_admin: str | None = _S5F9_Header(default=None, alias="X-Edge-User-Is-Admin"),
):
    if not _s5f9_laptop_chat_queue_enabled():
        _s5f9_raise_feature_disabled()

    if not _s5f9_laptop_chat_queue_synthetic_only() and _s5f14_laptop_chat_queue_real_users_enabled():
        try:
            # STAGE_5G16_PREAUTH_TRUSTED_CT101_STATUS_REFRESH_V1
            # Status polling has no chat body, but a trusted wrapper request can
            # still refresh the mirrored session before ownership validation.
            trusted_user_for_refresh = _s5g14_validate_trusted_edge_identity(
                x_edge_auth_secret=x_edge_auth_secret,
                x_edge_user_id=x_edge_user_id,
                x_edge_user_email=x_edge_user_email,
                x_edge_user_is_admin=x_edge_user_is_admin,
            )
            if trusted_user_for_refresh:
                _s5g14_mirror_trusted_edge_user_session(
                    trusted_user=trusted_user_for_refresh,
                    session_token=x_queued_chat_session_token,
                )

            if trusted_user_for_refresh:
                auth_user = _s5g14_trusted_queued_auth_user(trusted_user_for_refresh)
            else:
                auth_user = _s5p10e_resolve_queue_auth_user(
                    session_token=x_queued_chat_session_token
                )
        except _S5F17_QueuedChatSessionAuthError as exc:
            trusted_user = _s5g14_validate_trusted_edge_identity(
                x_edge_auth_secret=x_edge_auth_secret,
                x_edge_user_id=x_edge_user_id,
                x_edge_user_email=x_edge_user_email,
                x_edge_user_is_admin=x_edge_user_is_admin,
            )

            if trusted_user:
                _s5g14_mirror_trusted_edge_user_session(
                    trusted_user=trusted_user,
                    session_token=x_queued_chat_session_token,
                )

                auth_user = _s5g14_trusted_queued_auth_user(trusted_user)
            else:
                raise _S5F9_HTTPException(
                    status_code=401,
                    detail={
                        "ok": False,
                        "error": "queued_chat_status_session_auth_failed_stage_5f20",
                        "feature": "laptop_queued_chat",
                        "stage": "5f20",
                        "message": str(exc),
                    },
                ) from exc

        try:
            _s5f20_validate_real_user_queued_chat_status_request(
                authenticated_user_id=auth_user.user_id,
                job_id=job_id,
            )
        except _S5F20_RealUserQueuedChatGuardError as exc:
            raise _S5F9_HTTPException(
                status_code=403,
                detail={
                    "ok": False,
                    "error": "queued_chat_status_ownership_failed_stage_5f20",
                    "feature": "laptop_queued_chat",
                    "stage": "5f20",
                    "message": str(exc),
                },
            ) from exc

        raw = _s5f9_psql_at(
            f"""
            SELECT COALESCE(
              (
                SELECT row_to_json(j)::text
                FROM (
                  SELECT
                    id AS job_id,
                    user_id,
                    job_type,
                    status,
                    requested_model,
                    payload_json,
                    result_json,
                    error_text,
                    created_at,
                    updated_at,
                    started_at,
                    finished_at
                  FROM app_jobs
                  WHERE id = {_s5f9_sql_literal(job_id)}
                    AND user_id = {_s5f9_sql_literal(auth_user.user_id)}
                ) j
              ),
              ''
            );
            """
        )

        if not raw:
            raise _S5F9_HTTPException(
                status_code=404,
                detail={
                    "ok": False,
                    "error": "queued_chat_job_not_found_stage_5f20",
                    "feature": "laptop_queued_chat",
                    "stage": "5f20",
                    "job_id": job_id,
                },
            )

        job = _s5f9_json.loads(raw)

        return {
            "ok": True,
            "stage": "5f20",
            "route_source": "stage_5f20_real_user_status_route",
            "real_user": True,
            "job": job,
        }

    _s5f9_require_synthetic_mode()

    if not job_id.startswith("s5f8-job-"):
        raise _S5F9_HTTPException(
            status_code=400,
            detail={
                "ok": False,
                "error": "non_synthetic_job_refused",
                "stage": "5f9",
            },
        )

    raw = _s5f9_psql_at(
        f"""
        SELECT COALESCE(
          (
            SELECT row_to_json(j)::text
            FROM (
              SELECT
                id AS job_id,
                user_id,
                job_type,
                status,
                requested_model,
                payload_json,
                result_json,
                error_text,
                created_at,
                updated_at,
                started_at,
                finished_at
              FROM app_jobs
              WHERE id = {_s5f9_sql_literal(job_id)}
            ) j
          ),
          ''
        );
        """
    )

    if not raw:
        raise _S5F9_HTTPException(
            status_code=404,
            detail={
                "ok": False,
                "error": "job_not_found",
                "stage": "5f9",
                "job_id": job_id,
            },
        )

    job = _s5f9_json.loads(raw)

    return {
        "ok": True,
        "stage": "5f9",
        "synthetic_only": True,
        "job": job,
    }

# STAGE_6F_MINIMAL_ROUTER_DRY_RUN_ENDPOINT_V1
# Stage 6J extracted deterministic router helper logic into edge_intent_router.py.
from edge_intent_router import (
    _stage6f_router_enabled,
    _stage6f_router_response,
)


@app.post("/api/router/dry-run")
@app.post("/system/router/dry-run")
async def stage6f_universal_intent_router_dry_run(request: Request):
    if not _stage6f_router_enabled():
        raise HTTPException(status_code=404, detail="Universal Intent Router dry-run endpoint is disabled.")

    try:
        body = await request.json()
    except Exception:
        body = {}

    return _stage6f_router_response(body)
