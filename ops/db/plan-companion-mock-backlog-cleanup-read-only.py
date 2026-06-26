#!/usr/bin/env python3
"""
Read-only cleanup planner for old mock/no-model queued companion.chat backlog.

This tool never mutates the DB. It opens SQLite with mode=ro and reports the
candidate set that would be considered for a later guarded cleanup phase.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


DEFAULT_DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"


def prompt_bucket(prompt: str) -> str:
    normalized = " ".join((prompt or "").split())
    lower = normalized.lower()

    if "say hello in 1 sentence" in lower:
        return "say_hello_one_sentence"
    if "stage15e-authenticated-mock-queued-chat-validation" in lower:
        return "stage15e_mock_validation"
    if normalized == "":
        return "empty_prompt"
    return "other_prompt"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Read-only dry-run planner for old mock/no-model queued companion.chat backlog."
    )
    parser.add_argument(
        "--db",
        default=DEFAULT_DB,
        help=f"SQLite DB path. Default: {DEFAULT_DB}",
    )
    parser.add_argument(
        "--expected-count",
        type=int,
        default=None,
        help="Optional expected candidate count. The tool exits non-zero if the count differs.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=20,
        help="Number of oldest/newest sample rows to include. Default: 20.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of text.",
    )
    return parser.parse_args()


def fetch_candidates(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    sql = """
        SELECT
            j.id,
            j.job_type,
            j.status,
            COALESCE(j.attempts, 0) AS attempts,
            COALESCE(j.requested_model, '') AS requested_model,
            COALESCE(j.created_at, '') AS created_at,
            COALESCE(j.updated_at, '') AS updated_at,
            COALESCE(j.prompt, '') AS prompt,
            COALESCE(r.result_rows, 0) AS result_rows
        FROM jobs j
        LEFT JOIN (
            SELECT job_id, COUNT(*) AS result_rows
            FROM job_results
            GROUP BY job_id
        ) r ON r.job_id = j.id
        WHERE j.job_type = 'companion.chat'
          AND j.status = 'queued'
          AND COALESCE(j.attempts, 0) = 0
          AND COALESCE(r.result_rows, 0) = 0
          AND COALESCE(j.requested_model, '') = 'mock/no-model'
        ORDER BY j.id ASC
    """
    return conn.execute(sql).fetchall()


def make_payload(db: str, limit: int) -> dict[str, Any]:
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row

    try:
        integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise RuntimeError(f"REFUSE_DB_INTEGRITY={integrity}")

        jobs_total = conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]
        results_total = conn.execute("SELECT COUNT(*) FROM job_results").fetchone()[0]
        candidates = fetch_candidates(conn)
    finally:
        conn.close()

    ids = [int(row["id"]) for row in candidates]
    id_text = ",".join(str(i) for i in ids)
    id_sha256 = hashlib.sha256(id_text.encode("utf-8")).hexdigest()

    by_day: dict[str, int] = defaultdict(int)
    by_bucket: Counter[str] = Counter()

    for row in candidates:
        day = (row["created_at"] or "")[:10] or "<blank>"
        by_day[day] += 1
        by_bucket[prompt_bucket(row["prompt"])] += 1

    def row_to_sample(row: sqlite3.Row) -> dict[str, Any]:
        prompt = " ".join((row["prompt"] or "").split())
        return {
            "id": int(row["id"]),
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
            "requested_model": row["requested_model"],
            "prompt_bucket": prompt_bucket(row["prompt"]),
            "prompt_preview": prompt[:160],
        }

    return {
        "ok": True,
        "mode": "read_only",
        "db": db,
        "integrity": integrity,
        "jobs_total": jobs_total,
        "job_results_total": results_total,
        "candidate_criteria": {
            "job_type": "companion.chat",
            "status": "queued",
            "attempts": 0,
            "result_rows": 0,
            "requested_model": "mock/no-model",
        },
        "candidate_count": len(candidates),
        "candidate_min_id": min(ids) if ids else None,
        "candidate_max_id": max(ids) if ids else None,
        "candidate_id_sha256": id_sha256,
        "by_created_day": dict(sorted(by_day.items())),
        "by_prompt_bucket": dict(sorted(by_bucket.items())),
        "oldest_sample": [row_to_sample(r) for r in candidates[:limit]],
        "newest_sample": [row_to_sample(r) for r in candidates[-limit:]],
        "future_cleanup_status": "not_selected_by_this_tool",
        "requires_future_approval": True,
        "mutated": False,
    }


def emit_text(payload: dict[str, Any]) -> None:
    print("mock_companion_cleanup_plan_read_only=yes")
    print(f"db={payload['db']}")
    print(f"integrity={payload['integrity']}")
    print(f"jobs_total={payload['jobs_total']}")
    print(f"job_results_total={payload['job_results_total']}")
    print(f"candidate_count={payload['candidate_count']}")
    print(f"candidate_min_id={payload['candidate_min_id']}")
    print(f"candidate_max_id={payload['candidate_max_id']}")
    print(f"candidate_id_sha256={payload['candidate_id_sha256']}")
    print("candidate_criteria=job_type:companion.chat,status:queued,attempts:0,result_rows:0,requested_model:mock/no-model")

    for day, count in payload["by_created_day"].items():
        print(f"candidate_day_count day={day} count={count}")

    for bucket, count in payload["by_prompt_bucket"].items():
        print(f"candidate_prompt_bucket bucket={bucket} count={count}")

    print("--- oldest candidates ---")
    for row in payload["oldest_sample"]:
        print(
            "oldest_candidate "
            f"id={row['id']} "
            f"created_at={row['created_at']} "
            f"bucket={row['prompt_bucket']} "
            f"prompt_preview={row['prompt_preview']!r}"
        )

    print("--- newest candidates ---")
    for row in payload["newest_sample"]:
        print(
            "newest_candidate "
            f"id={row['id']} "
            f"created_at={row['created_at']} "
            f"bucket={row['prompt_bucket']} "
            f"prompt_preview={row['prompt_preview']!r}"
        )

    print("future_cleanup_status=not_selected_by_this_tool")
    print("requires_future_approval=yes")
    print("mutated=no")
    print("mock_companion_cleanup_plan_done=yes")


def main() -> int:
    args = parse_args()

    if args.limit < 0 or args.limit > 100:
        print(f"REFUSE_LIMIT_OUT_OF_RANGE={args.limit}", file=sys.stderr)
        return 2

    if not Path(args.db).is_file():
        print(f"REFUSE_DB_NOT_FOUND={args.db}", file=sys.stderr)
        return 2

    payload = make_payload(args.db, args.limit)

    if args.expected_count is not None and payload["candidate_count"] != args.expected_count:
        print(
            f"REFUSE_EXPECTED_COUNT_MISMATCH expected={args.expected_count} actual={payload['candidate_count']}",
            file=sys.stderr,
        )
        if args.json:
            print(json.dumps(payload, indent=2, sort_keys=True))
        else:
            emit_text(payload)
        return 3

    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        emit_text(payload)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
