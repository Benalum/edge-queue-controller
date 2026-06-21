#!/usr/bin/env bash
set -u
set -o pipefail
set +H

REQUIRED_APPROVAL="APPROVE_STAGE_16_E3M_B_RUN_MANUAL_COMPLETION_HELPER_FOR_ONE_QUEUED_JOB_ONE_MODEL_CALL_ONE_JOB_UPDATE_ONE_JOB_RESULT_INSERT_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED"
ADAPTER_APPROVAL="APPROVE_STAGE_16_E3I_RUN_ONE_SHOT_MODEL_ADAPTER_NO_DB_WRITE_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED"

PVEW_SSH="${PVEW_SSH:-pvew}"
ADAPTER="${ADAPTER:-ops/model/pveso-one-shot-generate.sh}"
JOB_ID="${JOB_ID:-}"
CURL_TIMEOUT="${CURL_TIMEOUT:-240}"
NUM_PREDICT="${NUM_PREDICT:-64}"
NUM_CTX="${NUM_CTX:-512}"
TEMPERATURE="${TEMPERATURE:-0}"
SEED="${SEED:-16}"
RESULT_MARKER="${RESULT_MARKER:-APC_MANUAL_COMPLETION_HELPER_RESULT}"
DB_PATH="/var/lib/edge-queue-controller/edge_queue.sqlite3"

usage() {
  cat <<USAGE
Manual queued-job completion helper via PVESO one-shot adapter.

This helper is intentionally gated. It refuses to run unless:
  APC_MANUAL_COMPLETION_APPROVAL=$REQUIRED_APPROVAL
  JOB_ID=<one queued CT203 jobs.id>

Safety posture:
  - Completes exactly one queued job.
  - Runs the existing PVESO one-shot adapter exactly once.
  - Updates exactly one jobs row.
  - Inserts exactly one job_results row.
  - Refuses if job already has a result.
  - Does not activate scheduler or workers.
  - Does not start CT101.
  - Does not expose a public model endpoint.
  - Does not pull/download models.
  - Does not start/restart/reload services.

Environment:
  PVEW_SSH       default: pvew
  ADAPTER        default: ops/model/pveso-one-shot-generate.sh
  JOB_ID         required
  NUM_PREDICT    default: 64
  NUM_CTX        default: 512
  TEMPERATURE    default: 0
  SEED           default: 16
  CURL_TIMEOUT   default: 240
USAGE
}

sanitize_stream() {
  sed -E \
    -e 's#https://login\.tailscale\.com/a/[A-Za-z0-9]+#<redacted-auth-url>#g' \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<redacted-mac>/g'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

{
echo "=== manual queued-job completion helper via PVESO adapter ==="

if [ "${APC_MANUAL_COMPLETION_APPROVAL:-}" != "$REQUIRED_APPROVAL" ]; then
  echo "approval_gate=FAIL"
  echo "required=$REQUIRED_APPROVAL"
  echo "Set APC_MANUAL_COMPLETION_APPROVAL to the required approval string to run."
  exit 64
fi
echo "approval_gate=PASS"

if [ -z "$JOB_ID" ]; then
  echo "job_id_guard=FAIL missing JOB_ID"
  exit 65
fi

case "$JOB_ID" in
  *[!0-9]*|"")
    echo "job_id_guard=FAIL JOB_ID must be an integer"
    exit 66
    ;;
esac
echo "job_id=$JOB_ID"

if [ ! -x "$ADAPTER" ]; then
  echo "adapter_guard=FAIL adapter missing or not executable: $ADAPTER"
  exit 67
fi
bash -n "$ADAPTER"

echo "--- read target job from CT203 DB before adapter run ---"
JOB_JSON_B64="$(
ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" "JOB_ID='$JOB_ID' bash -s" 2>&1 <<'PVEW_REMOTE'
set -u
set -o pipefail
pct exec 203 -- env JOB_ID="$JOB_ID" python3 - <<'PY'
import base64
import json
import os
import sqlite3
import sys

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
job_id = int(os.environ["JOB_ID"])

conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    integrity = conn.execute("pragma integrity_check").fetchone()[0]
    if integrity != "ok":
        print("db_integrity_guard=FAIL " + str(integrity), file=sys.stderr)
        raise SystemExit(20)

    job = conn.execute(
        "select id, status, job_type, prompt, requested_model, attempts from jobs where id = ?",
        (job_id,),
    ).fetchone()
    if job is None:
        print("target_job_lookup=FAIL", file=sys.stderr)
        raise SystemExit(21)

    result_count = conn.execute(
        "select count(*) from job_results where job_id = ?",
        (job_id,),
    ).fetchone()[0]

    payload = {
        "id": job["id"],
        "status": job["status"],
        "job_type": job["job_type"],
        "prompt": job["prompt"],
        "requested_model": job["requested_model"],
        "attempts": job["attempts"],
        "job_results_for_job": result_count,
    }

    if job["status"] != "queued":
        print("target_job_status_guard=FAIL status=" + str(job["status"]), file=sys.stderr)
        raise SystemExit(22)
    if result_count != 0:
        print("target_job_result_guard=FAIL result already exists", file=sys.stderr)
        raise SystemExit(23)
    if not job["requested_model"]:
        print("target_job_model_guard=FAIL requested_model missing", file=sys.stderr)
        raise SystemExit(24)
    if not job["prompt"]:
        print("target_job_prompt_guard=FAIL prompt missing", file=sys.stderr)
        raise SystemExit(25)

    print(base64.b64encode(json.dumps(payload, sort_keys=True).encode("utf-8")).decode("ascii"))
finally:
    conn.close()
PY
PVEW_REMOTE
)"

echo "job_json_b64_len=${#JOB_JSON_B64}"
MODEL_NAME="$(printf '%s' "$JOB_JSON_B64" | base64 -d | python3 -c 'import json,sys; print(json.load(sys.stdin)["requested_model"])')"
PROMPT_TEXT="$(printf '%s' "$JOB_JSON_B64" | base64 -d | python3 -c 'import json,sys; print(json.load(sys.stdin)["prompt"])')"
JOB_TYPE="$(printf '%s' "$JOB_JSON_B64" | base64 -d | python3 -c 'import json,sys; print(json.load(sys.stdin)["job_type"])')"

echo "target_job_lookup=PASS"
echo "target_job_status=queued"
echo "target_job_type=$JOB_TYPE"
echo "target_model=$MODEL_NAME"
echo "target_prompt_len=${#PROMPT_TEXT}"

echo "--- run PVESO one-shot adapter exactly once ---"
ADAPTER_LOG="$(mktemp /tmp/apc-manual-complete-adapter.XXXXXX.log)"

APC_ONE_SHOT_MODEL_APPROVAL="$ADAPTER_APPROVAL" \
MODEL_NAME="$MODEL_NAME" \
PROMPT_TEXT="$PROMPT_TEXT" \
NUM_PREDICT="$NUM_PREDICT" \
NUM_CTX="$NUM_CTX" \
TEMPERATURE="$TEMPERATURE" \
SEED="$SEED" \
CURL_TIMEOUT="$CURL_TIMEOUT" \
"$ADAPTER" 2>&1 | tee "$ADAPTER_LOG"

adapter_rc="${PIPESTATUS[0]}"
adapter_out="$(cat "$ADAPTER_LOG" 2>/dev/null || true)"
rm -f "$ADAPTER_LOG"

echo "adapter_rc=$adapter_rc"
if [ "$adapter_rc" != "0" ]; then
  echo "adapter_result=FAIL"
  exit "$adapter_rc"
fi

printf '%s\n' "$adapter_out" | grep -q '^ONE_SHOT_MODEL_ADAPTER_RESULT=PASS$' || { echo "adapter_result=FAIL missing PASS"; exit 68; }
printf '%s\n' "$adapter_out" | grep -q '^generate_nonempty_response=yes$' || { echo "adapter_result=FAIL empty response"; exit 69; }

generate_model="$(printf '%s\n' "$adapter_out" | awk -F= '/^generate_model=/{print $2; exit}')"
generate_response_text="$(printf '%s\n' "$adapter_out" | sed -n 's/^generate_response_text=//p' | head -1)"
generate_response_len="$(printf '%s\n' "$adapter_out" | awk -F= '/^generate_response_len=/{print $2; exit}')"
generate_elapsed="$(printf '%s\n' "$adapter_out" | awk -F= '/^generate_elapsed_seconds=/{print $2; exit}')"
generate_eval_count="$(printf '%s\n' "$adapter_out" | awk -F= '/^generate_eval_count=/{print $2; exit}')"
remote_run_dir="$(printf '%s\n' "$adapter_out" | awk -F= '/^run_dir=/{print $2; exit}')"

RESULT_JSON_B64="$(
  RESULT_MARKER="$RESULT_MARKER" \
  JOB_ID="$JOB_ID" \
  MODEL_NAME="$MODEL_NAME" \
  GENERATE_MODEL="$generate_model" \
  RESPONSE_TEXT="$generate_response_text" \
  RESPONSE_LEN="$generate_response_len" \
  ELAPSED="$generate_elapsed" \
  EVAL_COUNT="$generate_eval_count" \
  REMOTE_RUN_DIR="$remote_run_dir" \
  python3 - <<'PY' | base64 -w0
import json
import os

payload = {
    "stage": "manual-complete-queued-job-via-pveso-adapter",
    "marker": os.environ["RESULT_MARKER"],
    "job_id": int(os.environ["JOB_ID"]),
    "model_name": os.environ["MODEL_NAME"],
    "generate_model": os.environ.get("GENERATE_MODEL", ""),
    "response_text": os.environ.get("RESPONSE_TEXT", ""),
    "response_len": os.environ.get("RESPONSE_LEN", ""),
    "elapsed_seconds": os.environ.get("ELAPSED", ""),
    "eval_count": os.environ.get("EVAL_COUNT", ""),
    "remote_run_dir": os.environ.get("REMOTE_RUN_DIR", ""),
    "adapter_path": "ops/model/pveso-one-shot-generate.sh",
    "db_write_scope": "update one jobs row and insert one job_results row",
    "scheduler_activation": False,
    "worker_activation": False,
    "model_pull": False,
    "ct101_started": False,
}
print(json.dumps(payload, sort_keys=True))
PY
)"

echo "result_json_b64_len=${#RESULT_JSON_B64}"

echo "--- complete DB job exactly once ---"
ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" \
  "JOB_ID='$JOB_ID' RESULT_JSON_B64='$RESULT_JSON_B64' bash -s" 2>&1 <<'PVEW_REMOTE'
set -u
set -o pipefail
pct exec 203 -- env JOB_ID="$JOB_ID" RESULT_JSON_B64="$RESULT_JSON_B64" python3 - <<'PY'
import base64
import json
import os
import sqlite3
from datetime import datetime, timezone

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
job_id = int(os.environ["JOB_ID"])
result_json = base64.b64decode(os.environ["RESULT_JSON_B64"]).decode("utf-8")
result_payload = json.loads(result_json)
response_text = str(result_payload.get("response_text", ""))
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

conn = sqlite3.connect(DB, timeout=10)
conn.row_factory = sqlite3.Row
try:
    conn.execute("pragma foreign_keys=ON")
    integrity = conn.execute("pragma integrity_check").fetchone()[0]
    print("db_integrity_before=" + str(integrity))
    if integrity != "ok":
        raise SystemExit(20)

    jobs_before = conn.execute("select count(*) from jobs").fetchone()[0]
    results_before = conn.execute("select count(*) from job_results").fetchone()[0]
    result_before_for_job = conn.execute("select count(*) from job_results where job_id = ?", (job_id,)).fetchone()[0]

    print("jobs_before=" + str(jobs_before))
    print("job_results_before=" + str(results_before))
    print("job_results_for_job_before=" + str(result_before_for_job))

    job = conn.execute("select id, status, requested_model from jobs where id = ? and status = 'queued'", (job_id,)).fetchone()
    if job is None:
        print("target_job_lookup=FAIL")
        raise SystemExit(21)
    if result_before_for_job != 0:
        print("idempotency_guard=FAIL result already exists")
        raise SystemExit(22)

    conn.execute("begin immediate")
    cur_update = conn.execute(
        """
        update jobs
           set status = ?,
               attempts = attempts + 1,
               updated_at = ?,
               forwarded_at = ?,
               last_error = ?
         where id = ?
           and status = ?
        """,
        ("completed", now, now, None, job_id, "queued"),
    )
    conn.execute(
        """
        insert into job_results
            (job_id, model, response_text, response_json, error, created_at, updated_at)
        values
            (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            job_id,
            result_payload.get("generate_model") or result_payload.get("model_name"),
            response_text,
            result_json,
            None,
            now,
            now,
        ),
    )
    conn.commit()

    jobs_after = conn.execute("select count(*) from jobs").fetchone()[0]
    results_after = conn.execute("select count(*) from job_results").fetchone()[0]
    result_after_for_job = conn.execute("select count(*) from job_results where job_id = ?", (job_id,)).fetchone()[0]
    job_after = conn.execute("select id, status, attempts from jobs where id = ?", (job_id,)).fetchone()

    print("jobs_after=" + str(jobs_after))
    print("job_results_after=" + str(results_after))
    print("jobs_rows_updated=" + str(cur_update.rowcount))
    print("job_status_after=" + str(job_after["status"]))
    print("job_attempts_after=" + str(job_after["attempts"]))
    print("job_results_for_job_after=" + str(result_after_for_job))

    if cur_update.rowcount != 1:
        raise SystemExit(23)
    if jobs_after != jobs_before:
        raise SystemExit(24)
    if results_after != results_before + 1:
        raise SystemExit(25)
    if result_after_for_job != 1:
        raise SystemExit(26)

    print("MANUAL_COMPLETION_HELPER_DB_RESULT=PASS")
finally:
    conn.close()
PY
PVEW_REMOTE

echo "MANUAL_COMPLETION_HELPER_RESULT=PASS"
} 2>&1 | sanitize_stream
