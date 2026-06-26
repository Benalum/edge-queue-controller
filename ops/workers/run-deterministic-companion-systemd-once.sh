#!/usr/bin/env bash
set -euo pipefail
set +H

usage() {
  cat >&2 <<'USAGE'
Usage:
  run-deterministic-companion-systemd-once.sh --job-id JOB_ID --expected-marker MARKER [--result-model backend-deterministic/no-model]

Purpose:
  Start exactly one disabled-by-default systemd one-shot deterministic Companion worker instance.

Safety:
  - requires explicit --job-id
  - requires explicit --expected-marker
  - creates one per-job env file under /run
  - starts one edge-deterministic-companion-worker-once@JOB_ID.service instance
  - removes the env file after completion
  - does not enable services or timers
  - does not call PVESO, Ollama, or any model endpoint
USAGE
}

JOB_ID=""
EXPECTED_MARKER=""
RESULT_MODEL="backend-deterministic/no-model"
ENV_DIR="/run/edge-queue-controller/deterministic-companion-worker"
SERVICE_PREFIX="edge-deterministic-companion-worker-once"
DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --job-id)
      JOB_ID="${2:-}"
      shift 2
      ;;
    --expected-marker)
      EXPECTED_MARKER="${2:-}"
      shift 2
      ;;
    --result-model)
      RESULT_MODEL="${2:-}"
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

if ! [[ "$JOB_ID" =~ ^[0-9]+$ ]]; then
  echo "REFUSE_JOB_ID_REQUIRED_NUMERIC" >&2
  usage
  exit 2
fi

if [ -z "$EXPECTED_MARKER" ]; then
  echo "REFUSE_EXPECTED_MARKER_REQUIRED" >&2
  usage
  exit 2
fi

if [ "$RESULT_MODEL" != "backend-deterministic/no-model" ]; then
  echo "REFUSE_UNSUPPORTED_RESULT_MODEL: $RESULT_MODEL" >&2
  exit 2
fi

SERVICE_INSTANCE="${SERVICE_PREFIX}@${JOB_ID}.service"
ENV_FILE="${ENV_DIR}/${JOB_ID}.env"

cleanup_env() {
  rm -f "$ENV_FILE" >/dev/null 2>&1 || true
}
trap cleanup_env EXIT

echo "deterministic_companion_systemd_once_job_id=$JOB_ID"
echo "deterministic_companion_systemd_once_service=$SERVICE_INSTANCE"

echo "--- preflight: installed helper/unit and controller state ---"
systemctl is-active edge-queue-controller.service >/dev/null

if ! systemctl cat edge-deterministic-companion-worker-once@.service >/dev/null 2>&1; then
  echo "REFUSE_SYSTEMD_TEMPLATE_NOT_INSTALLED" >&2
  exit 2
fi

template_enabled_state="$(systemctl is-enabled edge-deterministic-companion-worker-once@.service 2>/dev/null || true)"
echo "template_enabled_state=$template_enabled_state"
case "$template_enabled_state" in
  static|disabled|indirect|"") ;;
  *)
    echo "REFUSE_TEMPLATE_ENABLED_STATE_UNEXPECTED: $template_enabled_state" >&2
    exit 2
    ;;
esac

if [ ! -x /opt/edge-queue-controller/ops/workers/run-deterministic-companion-exact-once.py ]; then
  echo "REFUSE_RUNTIME_HELPER_NOT_EXECUTABLE" >&2
  exit 2
fi

echo "--- preflight: job state ---"
python3 - "$DB" "$JOB_ID" "$EXPECTED_MARKER" <<'PY'
import sqlite3
import sys

db, job_id_text, marker = sys.argv[1:4]
job_id = int(job_id_text)

conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    job = conn.execute("SELECT * FROM jobs WHERE id=?", (job_id,)).fetchone()
    if job is None:
        raise SystemExit("REFUSE_JOB_NOT_FOUND")
    rr = conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (job_id,)).fetchone()[0]
    prompt = str(job["prompt"] or "")

    print(f"preflight_job id={job['id']} status={job['status']} attempts={job['attempts']} job_type={job['job_type']} requested_model={job['requested_model']} result_rows={rr}")

    if job["status"] != "queued":
        raise SystemExit(f"REFUSE_JOB_NOT_QUEUED status={job['status']}")
    if int(job["attempts"] or 0) != 0:
        raise SystemExit(f"REFUSE_ATTEMPTS_NOT_ZERO attempts={job['attempts']}")
    if job["job_type"] != "companion.chat":
        raise SystemExit(f"REFUSE_JOB_TYPE_NOT_COMPANION_CHAT type={job['job_type']}")
    if marker not in prompt:
        raise SystemExit("REFUSE_EXPECTED_MARKER_NOT_IN_PROMPT")
    if rr != 0:
        raise SystemExit(f"REFUSE_RESULT_ROWS_NOT_ZERO rows={rr}")
finally:
    conn.close()
PY

echo "--- create per-job env file ---"
install -d -m 0755 "$ENV_DIR"
umask 077
cat > "$ENV_FILE" <<EOF
EDGE_EXPECTED_MARKER='$EXPECTED_MARKER'
EDGE_RESULT_MODEL='$RESULT_MODEL'
EOF
chmod 0600 "$ENV_FILE"

if [ "$(stat -c '%a' "$ENV_FILE")" != "600" ]; then
  echo "REFUSE_ENV_FILE_MODE_NOT_600" >&2
  exit 2
fi

echo "env_file_created=yes"

echo "--- start one systemd instance ---"
systemctl start "$SERVICE_INSTANCE"

service_active_state="$(systemctl is-active "$SERVICE_INSTANCE" 2>/dev/null || true)"
service_result="$(systemctl show -p Result --value "$SERVICE_INSTANCE" 2>/dev/null || true)"
service_exec_main_status="$(systemctl show -p ExecMainStatus --value "$SERVICE_INSTANCE" 2>/dev/null || true)"

echo "service_active_state=$service_active_state"
echo "service_result=$service_result"
echo "service_exec_main_status=$service_exec_main_status"

case "$service_active_state" in
  inactive|deactivating|"") ;;
  *)
    echo "REFUSE_SERVICE_STILL_ACTIVE: $service_active_state" >&2
    exit 2
    ;;
esac

case "$service_result" in
  success|"") ;;
  *)
    echo "REFUSE_SERVICE_RESULT_NOT_SUCCESS: $service_result" >&2
    exit 2
    ;;
esac

case "$service_exec_main_status" in
  0|"") ;;
  *)
    echo "REFUSE_SERVICE_EXEC_STATUS_NOT_ZERO: $service_exec_main_status" >&2
    exit 2
    ;;
esac

echo "--- final job verification ---"
python3 - "$DB" "$JOB_ID" "$EXPECTED_MARKER" "$RESULT_MODEL" <<'PY'
import sqlite3
import sys

db, job_id_text, marker, result_model = sys.argv[1:5]
job_id = int(job_id_text)

conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    job = conn.execute("SELECT * FROM jobs WHERE id=?", (job_id,)).fetchone()
    rr = conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (job_id,)).fetchone()[0]
    res = conn.execute("SELECT * FROM job_results WHERE job_id=?", (job_id,)).fetchone()

    print(f"final_job id={job['id']} status={job['status']} attempts={job['attempts']} job_type={job['job_type']} result_rows={rr}")
    print(f"final_result_model={res['model'] if res else ''}")
    print(f"final_response={res['response_text'] if res else ''}")
    print(f"final_error={res['error'] if res else ''}")

    if job["status"] != "completed":
        raise SystemExit(f"REFUSE_FINAL_JOB_NOT_COMPLETED status={job['status']}")
    if int(job["attempts"] or 0) != 1:
        raise SystemExit(f"REFUSE_FINAL_ATTEMPTS_NOT_ONE attempts={job['attempts']}")
    if rr != 1:
        raise SystemExit(f"REFUSE_FINAL_RESULT_ROWS_NOT_ONE rows={rr}")
    if res["model"] != result_model:
        raise SystemExit(f"REFUSE_FINAL_RESULT_MODEL_MISMATCH model={res['model']}")
    if res["response_text"] != marker:
        raise SystemExit("REFUSE_FINAL_RESPONSE_MISMATCH")
    if res["error"] is not None:
        raise SystemExit(f"REFUSE_FINAL_ERROR_NOT_NONE error={res['error']}")
finally:
    conn.close()
PY

rm -f "$ENV_FILE"
echo "env_file_removed=yes"
echo "deterministic_companion_systemd_once_done=yes"
