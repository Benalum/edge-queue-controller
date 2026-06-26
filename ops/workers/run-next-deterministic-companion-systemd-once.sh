#!/usr/bin/env bash
set -euo pipefail
set +H

usage() {
  cat >&2 <<'USAGE'
Usage:
  run-next-deterministic-companion-systemd-once.sh --expected-marker MARKER [--db PATH] [--wrapper PATH]

Purpose:
  Find exactly one queued companion.chat job whose prompt contains the exact marker,
  then delegate to run-deterministic-companion-systemd-once.sh for the bounded systemd one-shot run.

Safety:
  - requires explicit --expected-marker
  - requires exactly one matching queued job
  - requires attempts=0 and result_rows=0
  - does not insert jobs
  - does not poll the queue
  - does not enable services or timers
  - does not call PVESO, Ollama, or any model endpoint
USAGE
}

EXPECTED_MARKER=""
DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"
WRAPPER="/opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-marker)
      EXPECTED_MARKER="${2:-}"
      shift 2
      ;;
    --db)
      DB="${2:-}"
      shift 2
      ;;
    --wrapper)
      WRAPPER="${2:-}"
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

if [ -z "$EXPECTED_MARKER" ]; then
  echo "REFUSE_EXPECTED_MARKER_REQUIRED" >&2
  usage
  exit 2
fi

if [ ! -x "$WRAPPER" ]; then
  echo "REFUSE_DELEGATE_WRAPPER_NOT_EXECUTABLE: $WRAPPER" >&2
  exit 2
fi

echo "marker_selected_wrapper_expected_marker=$EXPECTED_MARKER"
echo "marker_selected_wrapper_delegate=$WRAPPER"

JOB_ID="$(
python3 - "$DB" "$EXPECTED_MARKER" <<'PY'
import sqlite3
import sys

db, marker = sys.argv[1:3]

conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    rows = conn.execute(
        """
        SELECT
            j.id,
            j.job_type,
            j.status,
            j.attempts,
            j.requested_model,
            j.prompt,
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
          AND j.prompt LIKE ?
          AND COALESCE(r.result_rows, 0) = 0
        ORDER BY j.id ASC
        """,
        (f"%{marker}%",),
    ).fetchall()

    print(f"candidate_count={len(rows)}", file=sys.stderr)

    if len(rows) == 0:
        raise SystemExit("REFUSE_NO_ELIGIBLE_QUEUED_COMPANION_JOB_FOR_MARKER")
    if len(rows) > 1:
        ids = ",".join(str(r["id"]) for r in rows[:20])
        raise SystemExit(f"REFUSE_MULTIPLE_ELIGIBLE_JOBS_FOR_MARKER ids={ids}")

    row = rows[0]
    prompt = str(row["prompt"] or "")

    if marker not in prompt:
        raise SystemExit("REFUSE_MARKER_NOT_IN_PROMPT_AFTER_SELECTION")

    print(
        f"selected_job id={row['id']} status={row['status']} attempts={row['attempts']} "
        f"job_type={row['job_type']} requested_model={row['requested_model']} result_rows={row['result_rows']}",
        file=sys.stderr,
    )
    print(row["id"])
finally:
    conn.close()
PY
)"
echo "marker_selected_wrapper_job_id=$JOB_ID"

if ! [[ "$JOB_ID" =~ ^[0-9]+$ ]]; then
  echo "REFUSE_SELECTED_JOB_ID_NOT_NUMERIC: $JOB_ID" >&2
  exit 2
fi

exec "$WRAPPER" --job-id "$JOB_ID" --expected-marker "$EXPECTED_MARKER"
