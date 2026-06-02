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
    online, detail = await host_is_online()

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
        return {
            "ok": True,
            "edge_dry_run": EDGE_DRY_RUN,
            "host_online": online,
            "host_detail": detail,
            "actions": [
                {
                    "action": "nothing_to_do",
                    "reason": "No queued edge jobs.",
                }
            ],
        }

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


def worker_row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
    data = dict(row)

    try:
        data["capabilities"] = json.loads(data.pop("capabilities_json") or "[]")
    except Exception:
        data["capabilities"] = []

    last_heartbeat = parse_iso_time(data.get("last_heartbeat_at"))
    if last_heartbeat:
        age = datetime.now(timezone.utc) - last_heartbeat
        data["heartbeat_age_seconds"] = int(age.total_seconds())
    else:
        data["heartbeat_age_seconds"] = None

    heartbeat_age = data.get("heartbeat_age_seconds")
    if heartbeat_age is not None and heartbeat_age > 45:
        data["computed_health"] = "stale"
    elif data.get("status") in ("unhealthy", "disabled", "offline"):
        data["computed_health"] = data.get("status")
    elif data.get("current_jobs", 0) >= data.get("max_concurrent_jobs", 1):
        data["computed_health"] = "busy"
    else:
        data["computed_health"] = "available"

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
