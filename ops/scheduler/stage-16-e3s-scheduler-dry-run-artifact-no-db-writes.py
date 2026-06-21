#!/usr/bin/env python3
"""
Stage 16 E3S scheduler dry-run artifact.

Reads the CT203 SQLite queue DB in read-only mode and prints which queued job
the scheduler would claim later.

Safety contract:
- NO_DB_WRITE
- no claim/lease write
- no job status update
- no job_result insert
- no helper call
- no adapter call
- no operator dispatch call
- no model endpoint call
- no scheduler activation
- no persistent worker activation
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from pathlib import Path
from typing import Any


DEFAULT_DB_PATH = "/var/lib/edge-queue-controller/edge_queue.sqlite3"

ALLOWED_MODELS = {
    "qwen2.5:32b-instruct-q4_K_M",
    "qwen2.5-coder:32b-instruct-q4_K_M",
}

LANE_MAP = {
    "stage16_e3p_operator_dispatch_synthetic_model_smoke": "model",
    "stage16_e3s_scheduler_dry_run": "model",
    "model": "model",
    "chat": "model",
    "study": "study",
    "flashcards": "study",
    "companion": "companion",
    "default": "model",
    "primary": "model",
}


def eprint(message: str) -> None:
    print(message, file=sys.stderr)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Stage 16 E3S scheduler dry-run artifact; read-only DB inspection only."
    )
    parser.add_argument(
        "--db",
        default=os.environ.get("APC_E3S_DB_PATH", DEFAULT_DB_PATH),
        help="SQLite DB path. Default: APC_E3S_DB_PATH or CT203 default path.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=20,
        help="Maximum queued jobs to inspect. Default: 20.",
    )
    return parser.parse_args()


def qident(name: str) -> str:
    if not name.replace("_", "").isalnum():
        raise ValueError(f"unsafe identifier: {name!r}")
    return '"' + name.replace('"', '""') + '"'


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (table,),
    ).fetchone()
    return row is not None


def table_columns(conn: sqlite3.Connection, table: str) -> list[str]:
    rows = conn.execute(f"PRAGMA table_info({qident(table)})").fetchall()
    return [str(row[1]) for row in rows]


def first_present(columns: list[str], candidates: list[str]) -> str | None:
    column_set = set(columns)
    for candidate in candidates:
        if candidate in column_set:
            return candidate
    return None


def maybe_json(value: Any) -> dict[str, Any]:
    if value is None:
        return {}
    if isinstance(value, bytes):
        value = value.decode("utf-8", errors="replace")
    if not isinstance(value, str):
        return {}

    text = value.strip()
    if not text or not text.startswith(("{", "[")):
        return {}

    try:
        parsed = json.loads(text)
    except Exception:
        return {}

    if isinstance(parsed, dict):
        return parsed
    return {"_json": parsed}


def extract_from_payload(row: dict[str, Any], payload_cols: list[str], keys: list[str]) -> Any:
    for col in payload_cols:
        payload = maybe_json(row.get(col))
        for key in keys:
            if key in payload and payload[key] not in (None, ""):
                return payload[key]
    return None


def infer_lane(job_type: str | None, explicit_lane: str | None) -> tuple[str | None, str]:
    if explicit_lane:
        lane = str(explicit_lane)
        mapped = LANE_MAP.get(lane, lane if lane in {"model", "study", "companion"} else None)
        return mapped, "explicit_lane"

    if job_type:
        jt = str(job_type)
        if jt in LANE_MAP:
            return LANE_MAP[jt], "job_type_exact"
        for key, lane in LANE_MAP.items():
            if key != "default" and key in jt:
                return lane, f"job_type_contains:{key}"

    return None, "no_lane_mapping"


def result_count_for_job(conn: sqlite3.Connection, result_job_id_col: str, job_id: Any) -> int:
    row = conn.execute(
        f"SELECT COUNT(*) FROM {qident('job_results')} WHERE {qident(result_job_id_col)}=?",
        (job_id,),
    ).fetchone()
    return int(row[0])


def main() -> int:
    args = parse_args()
    db_path = Path(args.db)

    print("STAGE=stage-16-e3s-scheduler-dry-run-artifact-no-db-writes")
    print("NO_DB_WRITE")
    print("DB_OPEN_MODE=sqlite_uri_mode_ro_immutable")
    print("RUNTIME_CALLS=disabled")
    print("SCHEDULER_ACTIVATION=not_performed")
    print("PERSISTENT_WORKER_ACTIVATION=not_performed")
    print("HELPER_CALL=not_performed")
    print("ADAPTER_CALL=not_performed")
    print("OPERATOR_DISPATCH_CALL=not_performed")
    print("MODEL_CALL=not_performed")

    if not db_path.exists():
        eprint(f"ERROR=db_path_missing path={db_path}")
        return 2

    uri = f"file:{db_path}?mode=ro&immutable=1"

    try:
        conn = sqlite3.connect(uri, uri=True)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA query_only=ON")
    except Exception as exc:
        eprint(f"ERROR=db_open_failed detail={exc}")
        return 2

    with conn:
        integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
        print(f"DB_INTEGRITY={integrity}")

        if not table_exists(conn, "jobs"):
            eprint("ERROR=missing_jobs_table")
            return 2
        if not table_exists(conn, "job_results"):
            eprint("ERROR=missing_job_results_table")
            return 2

        job_cols = table_columns(conn, "jobs")
        result_cols = table_columns(conn, "job_results")

        job_id_col = first_present(job_cols, ["id", "job_id"])
        status_col = first_present(job_cols, ["status", "state"])
        created_col = first_present(job_cols, ["created_at", "created", "created_ts", "inserted_at"])
        updated_col = first_present(job_cols, ["updated_at", "updated", "updated_ts"])
        type_col = first_present(job_cols, ["job_type", "type", "task_type", "kind"])
        model_col = first_present(job_cols, ["requested_model", "model", "model_name"])
        lane_col = first_present(job_cols, ["worker_lane", "job_lane", "lane", "queue", "lane_name"])
        result_job_id_col = first_present(result_cols, ["job_id", "id_job"])

        payload_cols = [
            col
            for col in ["payload", "request", "request_json", "input", "input_json", "metadata", "params"]
            if col in job_cols
        ]

        missing = [
            name
            for name, value in {
                "job_id_col": job_id_col,
                "status_col": status_col,
                "result_job_id_col": result_job_id_col,
            }.items()
            if not value
        ]
        if missing:
            eprint("ERROR=missing_required_columns " + ",".join(missing))
            return 2

        order_parts = []
        if created_col:
            order_parts.append(qident(created_col))
        order_parts.append(qident(job_id_col))
        order_sql = ", ".join(order_parts)

        rows = conn.execute(
            f"""
            SELECT *
            FROM {qident('jobs')}
            WHERE {qident(status_col)} = ?
            ORDER BY {order_sql}
            LIMIT ?
            """,
            ("queued", args.limit),
        ).fetchall()

        print(f"QUEUED_INSPECTED={len(rows)}")

        eligible: list[dict[str, Any]] = []
        rejected: list[str] = []

        for sqlite_row in rows:
            row = dict(sqlite_row)
            job_id = row.get(job_id_col)
            result_rows = result_count_for_job(conn, result_job_id_col, job_id)

            job_type = row.get(type_col) if type_col else None
            if not job_type:
                job_type = extract_from_payload(row, payload_cols, ["job_type", "type", "task_type", "kind"])

            requested_model = row.get(model_col) if model_col else None
            if not requested_model:
                requested_model = extract_from_payload(
                    row,
                    payload_cols,
                    ["requested_model", "model", "model_name"],
                )

            explicit_lane = row.get(lane_col) if lane_col else None
            if not explicit_lane:
                explicit_lane = extract_from_payload(
                    row,
                    payload_cols,
                    ["worker_lane", "job_lane", "lane", "queue", "lane_name"],
                )

            lane, lane_reason = infer_lane(
                str(job_type) if job_type is not None else None,
                str(explicit_lane) if explicit_lane is not None else None,
            )

            model_allowed = requested_model in ALLOWED_MODELS
            lane_allowed = lane in {"model", "study", "companion"}

            summary = (
                f"job_id={job_id} "
                f"status=queued "
                f"result_rows={result_rows} "
                f"job_type={job_type!r} "
                f"requested_model={requested_model!r} "
                f"lane={lane!r} "
                f"lane_reason={lane_reason}"
            )

            if result_rows != 0:
                rejected.append("REJECT existing_result_rows " + summary)
                continue
            if requested_model and not model_allowed:
                rejected.append("REJECT model_not_allowlisted " + summary)
                continue
            if not lane_allowed:
                rejected.append("REJECT lane_not_mapped " + summary)
                continue

            eligible.append(
                {
                    "job_id": job_id,
                    "job_type": job_type,
                    "requested_model": requested_model,
                    "lane": lane,
                    "result_rows": result_rows,
                    "created": row.get(created_col) if created_col else None,
                    "updated": row.get(updated_col) if updated_col else None,
                }
            )

        for item in rejected:
            print(item)

        print(f"ELIGIBLE_WOULD_CLAIM_COUNT={len(eligible)}")

        if eligible:
            chosen = eligible[0]
            print(
                "WOULD_CLAIM "
                f"job_id={chosen['job_id']} "
                f"lane={chosen['lane']} "
                f"model={chosen['requested_model']} "
                f"result_rows={chosen['result_rows']} "
                f"created={chosen['created']} "
                f"updated={chosen['updated']}"
            )
        else:
            print("WOULD_CLAIM none")

        print("NO_DB_WRITE")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
