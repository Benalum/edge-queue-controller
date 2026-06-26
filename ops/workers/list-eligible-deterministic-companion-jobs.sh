#!/usr/bin/env bash
set -euo pipefail
set +H

usage() {
  cat >&2 <<'USAGE'
Usage:
  list-eligible-deterministic-companion-jobs.sh [--expected-marker MARKER] [--limit N] [--json] [--db PATH]

Purpose:
  Read-only report of queued companion.chat jobs that are eligible for the deterministic
  Companion selector/manual-wrapper path.

Eligibility:
  - job_type=companion.chat
  - status=queued
  - attempts=0
  - result_rows=0
  - if --expected-marker is provided, prompt must contain that marker

Safety:
  - opens SQLite in read-only mode
  - does not insert jobs
  - does not mutate jobs/results
  - does not start services or timers
  - does not call wrapper/helper/PVESO/Ollama/model endpoints
USAGE
}

DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"
EXPECTED_MARKER=""
LIMIT="25"
JSON_OUTPUT="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-marker)
      EXPECTED_MARKER="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --json)
      JSON_OUTPUT="1"
      shift 1
      ;;
    --db)
      DB="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "REFUSE_UNKNOWN_ARGUMENT: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
  echo "REFUSE_LIMIT_NOT_NUMERIC: $LIMIT" >&2
  exit 2
fi

if [ "$LIMIT" -lt 1 ] || [ "$LIMIT" -gt 200 ]; then
  echo "REFUSE_LIMIT_OUT_OF_RANGE: $LIMIT" >&2
  exit 2
fi

if [ ! -f "$DB" ]; then
  echo "REFUSE_DB_NOT_FOUND: $DB" >&2
  exit 2
fi

python3 - "$DB" "$EXPECTED_MARKER" "$LIMIT" "$JSON_OUTPUT" <<'PY'
import json
import sqlite3
import sys

db, marker, limit_text, json_output_text = sys.argv[1:5]
limit = int(limit_text)
json_output = json_output_text == "1"

conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row

try:
    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    if integrity != "ok":
        raise SystemExit(f"REFUSE_DB_INTEGRITY={integrity}")

    where = [
        "j.job_type = 'companion.chat'",
        "j.status = 'queued'",
        "COALESCE(j.attempts, 0) = 0",
        "COALESCE(r.result_rows, 0) = 0",
    ]
    params = []

    if marker:
        where.append("j.prompt LIKE ?")
        params.append(f"%{marker}%")

    sql = f"""
        SELECT
            j.id,
            j.job_type,
            j.status,
            COALESCE(j.attempts, 0) AS attempts,
            j.requested_model,
            j.created_at,
            j.updated_at,
            COALESCE(r.result_rows, 0) AS result_rows,
            substr(COALESCE(j.prompt, ''), 1, 180) AS prompt_preview
        FROM jobs j
        LEFT JOIN (
            SELECT job_id, COUNT(*) AS result_rows
            FROM job_results
            GROUP BY job_id
        ) r ON r.job_id = j.id
        WHERE {' AND '.join(where)}
        ORDER BY j.id ASC
        LIMIT ?
    """
    params.append(limit)

    rows = [dict(r) for r in conn.execute(sql, params).fetchall()]

    count_sql = f"""
        SELECT COUNT(*)
        FROM jobs j
        LEFT JOIN (
            SELECT job_id, COUNT(*) AS result_rows
            FROM job_results
            GROUP BY job_id
        ) r ON r.job_id = j.id
        WHERE {' AND '.join(where)}
    """
    total = conn.execute(count_sql, params[:-1]).fetchone()[0]

    payload = {
        "ok": True,
        "db_mode": "read_only",
        "job_type": "companion.chat",
        "status": "queued",
        "attempts": 0,
        "result_rows": 0,
        "expected_marker": marker or None,
        "total_eligible": total,
        "returned": len(rows),
        "limit": limit,
        "jobs": rows,
    }

    if json_output:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print("eligible_companion_jobs_read_only=yes")
        print(f"eligible_companion_jobs_marker={marker if marker else '<none>'}")
        print(f"eligible_companion_jobs_total={total}")
        print(f"eligible_companion_jobs_returned={len(rows)}")
        for row in rows:
            preview = " ".join(str(row.get("prompt_preview") or "").split())
            print(
                "eligible_job "
                f"id={row['id']} "
                f"status={row['status']} "
                f"attempts={row['attempts']} "
                f"job_type={row['job_type']} "
                f"requested_model={row['requested_model']} "
                f"result_rows={row['result_rows']} "
                f"created_at={row.get('created_at')} "
                f"prompt_preview={preview!r}"
            )
        print("eligible_companion_jobs_report_done=yes")
finally:
    conn.close()
PY
