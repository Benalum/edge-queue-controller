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

        executions.append(
            {
                "worker_id": stop_plan.get("worker_id"),
                "target_name": stop_plan.get("target_name"),
                "kind": kind,
                "vmid": vmid,
                "executed": result.returncode == 0,
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

