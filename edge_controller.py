import os
import sqlite3
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI
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
