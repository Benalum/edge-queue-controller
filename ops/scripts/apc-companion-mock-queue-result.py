#!/usr/bin/env python3
"""Create and complete exactly one mock Companion queue job.

This is a controlled no-model proof for UI/result-reader wiring.
It mutates SQLite only when APPROVE_FC_O45_I_MOCK_QUEUE_RESULT=1.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from datetime import datetime, timezone

APPROVAL = "APPROVE_FC_O45_I_MOCK_QUEUE_RESULT"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def connect(path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)).fetchone()
    return row is not None


def main() -> int:
    parser = argparse.ArgumentParser(description="Create and complete one mock companion.chat job.")
    parser.add_argument("--db", default=os.getenv("APC_DB_PATH", "/var/lib/edge-queue-controller/edge_queue.sqlite3"))
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--model", default="backend-deterministic/no-model")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if not args.prompt.strip():
        print("REFUSE_EMPTY_PROMPT", file=sys.stderr)
        return 2
    if args.user_id < 1:
        print("REFUSE_USER_ID_INVALID", file=sys.stderr)
        return 2
    if not os.path.exists(args.db):
        print(f"REFUSE_DB_NOT_FOUND: {args.db}", file=sys.stderr)
        return 2

    approved = os.getenv(APPROVAL, "") == "1"
    if not approved and not args.dry_run:
        print(f"REFUSE_APPROVAL_REQUIRED: set {APPROVAL}=1 or use --dry-run", file=sys.stderr)
        return 2

    conn = connect(args.db)
    try:
        integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            print(f"REFUSE_DB_INTEGRITY_NOT_OK: {integrity}", file=sys.stderr)
            return 2
        if not table_exists(conn, "jobs") or not table_exists(conn, "job_results"):
            print("REFUSE_REQUIRED_TABLES_MISSING", file=sys.stderr)
            return 2

        before = {
            "jobs_total": conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0],
            "results_total": conn.execute("SELECT COUNT(*) FROM job_results").fetchone()[0],
            "queued_companion": conn.execute("SELECT COUNT(*) FROM jobs WHERE job_type='companion.chat' AND status='queued'").fetchone()[0],
        }
        print("before=" + json.dumps(before, sort_keys=True))

        if args.dry_run:
            print("dry_run_would_insert_one_companion_chat_and_one_result=1")
            return 0

        ts = now()
        conn.isolation_level = None
        conn.execute("BEGIN IMMEDIATE")
        try:
            cur = conn.execute(
                """
                INSERT INTO jobs (user_id, job_type, prompt, requested_model, status, attempts, last_error, created_at, updated_at, forwarded_at)
                VALUES (?, 'companion.chat', ?, ?, 'running', 1, NULL, ?, ?, NULL)
                """,
                (args.user_id, args.prompt.strip(), args.model, ts, ts),
            )
            job_id = int(cur.lastrowid)
            response_text = "Prototype response: Companion queue/result path is working safely without a model call."
            response_json = {
                "ok": True,
                "stage": "stage16-fc-o45-i",
                "mode": "mock_queue_result_no_model",
                "reply": response_text,
                "model_endpoint_called": False,
                "ollama_called": False,
                "pveso_called": False,
                "job_id": job_id,
            }
            conn.execute(
                """
                INSERT INTO job_results (job_id, model, response_text, response_json, error, created_at, updated_at)
                VALUES (?, ?, ?, ?, NULL, ?, ?)
                """,
                (job_id, args.model, response_text, json.dumps(response_json, sort_keys=True), ts, ts),
            )
            conn.execute("UPDATE jobs SET status='completed', updated_at=? WHERE id=? AND status='running'", (now(), job_id))
            conn.execute("COMMIT")
        except Exception:
            conn.execute("ROLLBACK")
            raise

        row = conn.execute("SELECT id, user_id, job_type, requested_model, status, attempts FROM jobs WHERE id=?", (job_id,)).fetchone()
        result_rows = conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (job_id,)).fetchone()[0]
        after = {
            "jobs_total": conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0],
            "results_total": conn.execute("SELECT COUNT(*) FROM job_results").fetchone()[0],
            "queued_companion": conn.execute("SELECT COUNT(*) FROM jobs WHERE job_type='companion.chat' AND status='queued'").fetchone()[0],
        }
        print("created=" + json.dumps(dict(row), sort_keys=True))
        print(f"result_rows_for_job={result_rows}")
        print("after=" + json.dumps(after, sort_keys=True))
        print(f"mock_companion_job_id={job_id}")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
