#!/usr/bin/env bash
set -euo pipefail

PHASE="stage-16-e3p-b-controlled-dispatch-implementation-no-run"
REQUIRED_EXEC_APPROVAL="APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
HELPER_REQUIRED_APPROVAL="APPROVE_STAGE_16_E3M_B_RUN_MANUAL_COMPLETION_HELPER_FOR_ONE_QUEUED_JOB_ONE_MODEL_CALL_ONE_JOB_UPDATE_ONE_JOB_RESULT_INSERT_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED"
DEFAULT_RUN_ROOT="${APC_OPERATOR_DISPATCH_RUN_ROOT:-/tmp/apc-operator-dispatch-runs}"

PVEW_SSH_DEFAULT="${PVEW_SSH:-root@pvew}"
PVESO_TS_SSH_DEFAULT="${PVESO_TS_SSH:-root@pveso}"
CTID_DEFAULT="${APC_CT203_ID:-203}"
CT203_DB_PATH_DEFAULT="${APC_CT203_DB_PATH:-/var/lib/edge-queue-controller/edge_queue.sqlite3}"
HELPER_DEFAULT="${APC_MANUAL_HELPER_PATH:-ops/model/manual-complete-queued-job-via-pveso-adapter.sh}"
ADAPTER_DEFAULT="${APC_PVESO_ADAPTER_PATH:-ops/model/pveso-one-shot-generate.sh}"

usage() {
  cat <<'EOF_USAGE'
operator-dispatch-one-queued-job-via-pveso.sh

Stage 16 E3P-B execution-capable artifact.

Safe local modes:
  --help
      Print this help text.

  --contract
      Print the controlled dispatch safety contract.

  --plan-only --job-id N [--expected-model MODEL] [--run-root PATH] [--max-runtime-seconds SECONDS]
      Print a future execution plan only. This does not contact CT203, PVESO, Ollama, helper, adapter, or DB.

Execution mode for later approved E3P-D:
  --execute-approved --job-id N [--expected-model MODEL] [--run-root PATH] [--max-runtime-seconds SECONDS]

  Execution requires environment:
    APC_OPERATOR_DISPATCH_APPROVAL=APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION

  E3P-B adds the implementation branch, but E3P-B smoke does not invoke it.

Runtime boundaries:
  - Exactly one job ID per invocation.
  - Refuse completed jobs and any job that already has job_results.
  - Confirm scheduler and persistent workers are default-off.
  - Confirm PVESO Ollama is active and localhost-only.
  - Confirm no PVESO runner is active before execution.
  - Confirm CT101 is stopped/onboot=0.
  - Print run_dir before long execution starts.
  - Save preflight/postflight/recovery artifacts.
  - No automatic retry after timeout.
EOF_USAGE
}

print_contract() {
  cat <<EOF_CONTRACT
phase=$PHASE
artifact=ops/model/operator-dispatch-one-queued-job-via-pveso.sh
mode=E3P_B_EXECUTION_CAPABLE_NO_RUN
required_execution_approval=$REQUIRED_EXEC_APPROVAL
helper_required_approval=$HELPER_REQUIRED_APPROVAL
ct203_db_path=$CT203_DB_PATH_DEFAULT
ctid=$CTID_DEFAULT
helper_path=$HELPER_DEFAULT
adapter_path=$ADAPTER_DEFAULT

controlled_dispatch_contract:
  single_job_only: true
  scheduler_activation_allowed: false
  persistent_worker_activation_allowed: false
  public_ollama_exposure_allowed: false
  model_endpoint_call_allowed_without_approval: false
  db_mutation_allowed_without_approval: false

preflight_must_verify:
  - CT203 DB integrity ok
  - target job exists
  - target job status is queued
  - target job has zero job_results rows
  - target job requested_model is allowlisted
  - scheduler is not active
  - persistent workers are not active
  - EDGE_PERSISTENT_LANE_WORKERS_ENABLED is absent or false
  - PVESO Ollama is active
  - PVESO Ollama is localhost-only on 127.0.0.1:11434
  - PVESO non-localhost 11434 listener count is zero
  - PVESO runner process count is zero before execution
  - CT101 is stopped and onboot=0

durable_artifacts:
  - run_dir
  - preflight.json
  - pveso_preflight.txt
  - dispatch.stdout.txt
  - dispatch.stderr.txt
  - db_postflight.json
  - recovery_hint.txt
  - final_status.txt

timeout_recovery:
  - completed_with_one_result: do not rerun
  - queued_zero_results_no_runner: rerun only with explicit approval
  - queued_zero_results_runner_active: do not rerun; classify later
  - completed_multiple_results: duplicate-result failure
  - error_state: preserve artifacts and require recovery plan

duplicate_result_guard:
  - refuse if job_results count before execution is not zero
  - verify exactly one job_results row after completion

public_boundary:
  - browser never calls PVESO or Ollama directly
  - CT203 does not expose raw public Ollama endpoints
  - frontend receives model output only through CT203 DB/API
EOF_CONTRACT
}

die() {
  echo "ERROR: $*" >&2
  exit 2
}

json_escape_python() {
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps(sys.argv[1]))
PY
}

write_recovery_hint() {
  local run_dir="$1"
  cat > "$run_dir/recovery_hint.txt" <<'EOF_RECOVERY'
If this dispatch times out, do not rerun immediately.

Recovery sequence:
1. Run CT203 DB read-only classification for the target job.
2. Run PVESO runner/process read-only classification.
3. If completed with exactly one result row: do not rerun; document recovery.
4. If queued with zero result rows and no runner: rerun only with explicit approval.
5. If queued with zero result rows and runner active: do not rerun; classify later.
6. If completed with multiple result rows: duplicate-result failure.
7. If error state: preserve artifacts and write a recovery plan.
EOF_RECOVERY
}

validate_numeric_inputs() {
  case "$JOB_ID" in
    ""|*[!0-9]*)
      die "--job-id must be a positive integer"
      ;;
  esac

  if [ "$JOB_ID" -le 0 ]; then
    die "--job-id must be greater than zero"
  fi

  case "$MAX_RUNTIME_SECONDS" in
    ""|*[!0-9]*)
      die "--max-runtime-seconds must be a positive integer"
      ;;
  esac

  if [ "$MAX_RUNTIME_SECONDS" -lt 60 ]; then
    die "--max-runtime-seconds must be at least 60"
  fi
}

print_plan() {
  cat <<EOF_PLAN
phase=$PHASE
mode=plan-only
dispatch_would_target_job_id=$JOB_ID
expected_model=${EXPECTED_MODEL:-<not-asserted>}
run_root=$RUN_ROOT
run_dir=$RUN_DIR
max_runtime_seconds=$MAX_RUNTIME_SECONDS
pvew_ssh=$PVEW_SSH
pveso_ts_ssh=$PVESO_TS_SSH
ctid=$CTID
ct203_db_path=$CT203_DB_PATH
helper_path=$HELPER_PATH
adapter_path=$ADAPTER_PATH

NO-RUN PLAN:
  1. Read-only CT203 DB preflight through PVEW/pct.
  2. Refuse unless target job is queued and has zero job_results rows.
  3. Refuse unless requested_model is allowlisted.
  4. Read-only scheduler and persistent worker default-off checks.
  5. Read-only PVESO Ollama localhost-only and runner checks.
  6. Create durable run_dir before long execution.
  7. Invoke existing manual helper only in --execute-approved mode with exact approval marker.
  8. Complete DB lifecycle exactly once through the helper path.
  9. Run read-only postflight and classify timeout/recovery state.

E3P_B_NO_RUN_PLAN: no CT203, PVESO, Ollama, model, helper, adapter, or DB action was performed.
EOF_PLAN
}

ct203_preflight_python() {
  cat <<'PY'
import json
import os
import sqlite3
import sys

db_path = os.environ["APC_CT203_DB_PATH"]
job_id = int(os.environ["APC_TARGET_JOB_ID"])
expected_model = os.environ.get("APC_EXPECTED_MODEL", "")

allowlisted_models = {
    "qwen2.5:32b-instruct-q4_K_M",
    "qwen2.5-coder:32b-instruct-q4_K_M",
}

uri = f"file:{db_path}?mode=ro"
con = sqlite3.connect(uri, uri=True)
con.row_factory = sqlite3.Row
cur = con.cursor()

failures = []

integrity = cur.execute("pragma integrity_check").fetchone()[0]
if integrity != "ok":
    failures.append(f"db_integrity expected ok got {integrity!r}")

job = cur.execute(
    "select id, job_type, requested_model, status, attempts, created_at, updated_at from jobs where id=?",
    (job_id,),
).fetchone()

if job is None:
    failures.append(f"target job {job_id} not found")
    result_count = None
else:
    result_count = cur.execute("select count(*) from job_results where job_id=?", (job_id,)).fetchone()[0]
    if job["status"] != "queued":
        failures.append(f"target job status expected queued got {job['status']!r}")
    if result_count != 0:
        failures.append(f"target job result rows expected 0 got {result_count}")
    if job["requested_model"] not in allowlisted_models:
        failures.append(f"requested_model not allowlisted: {job['requested_model']!r}")
    if expected_model and job["requested_model"] != expected_model:
        failures.append(f"expected_model mismatch: expected {expected_model!r} got {job['requested_model']!r}")

workers = []
for row in cur.execute(
    "select worker_id, name, worker_role, worker_lane, accepts_lane_jobs, disabled, status, state, computed_health from workers order by rowid"
):
    workers.append(dict(row))

lane_accepting_enabled = [
    w for w in workers
    if int(w.get("accepts_lane_jobs") or 0) == 1
    and int(w.get("disabled") or 0) == 0
    and str(w.get("computed_health") or "").lower() not in ("offline", "disabled", "")
]

if lane_accepting_enabled:
    failures.append("one or more lane workers appear accepting and non-offline")

payload = {
    "db_path": db_path,
    "db_integrity": integrity,
    "target_job_id": job_id,
    "job": dict(job) if job else None,
    "target_job_result_rows": result_count,
    "worker_rows": workers,
    "allowlisted_models": sorted(allowlisted_models),
    "expected_model": expected_model or None,
    "failures": failures,
    "preflight_pass": not failures,
}

print(json.dumps(payload, indent=2, sort_keys=True))

if failures:
    sys.exit(41)
PY
}

ct203_postflight_python() {
  cat <<'PY'
import json
import os
import sqlite3
import sys

db_path = os.environ["APC_CT203_DB_PATH"]
job_id = int(os.environ["APC_TARGET_JOB_ID"])
expected_response = os.environ.get("APC_EXPECTED_RESPONSE_TEXT", "APC_E3P_OK")
expected_marker = os.environ.get("APC_EXPECTED_RESULT_MARKER", "APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT")

uri = f"file:{db_path}?mode=ro"
con = sqlite3.connect(uri, uri=True)
con.row_factory = sqlite3.Row
cur = con.cursor()

failures = []

integrity = cur.execute("pragma integrity_check").fetchone()[0]
if integrity != "ok":
    failures.append(f"db_integrity expected ok got {integrity!r}")

job = cur.execute(
    "select id, job_type, requested_model, status, attempts, created_at, updated_at from jobs where id=?",
    (job_id,),
).fetchone()
rows = cur.execute(
    "select job_id, model, response_text, response_json, error, created_at, updated_at from job_results where job_id=? order by rowid",
    (job_id,),
).fetchall()

if job is None:
    failures.append(f"target job {job_id} not found")
else:
    if job["status"] != "completed":
        failures.append(f"target job status expected completed got {job['status']!r}")

if len(rows) != 1:
    failures.append(f"target job result rows expected 1 got {len(rows)}")

row_payloads = []
for row in rows:
    d = dict(row)
    row_payloads.append({
        "job_id": d.get("job_id"),
        "model": d.get("model"),
        "response_text": d.get("response_text"),
        "error": d.get("error"),
        "created_at": d.get("created_at"),
        "updated_at": d.get("updated_at"),
        "response_json_len": len(d.get("response_json") or ""),
    })
    blob = " ".join(str(v) for v in d.values() if v is not None)
    if expected_response not in blob:
        failures.append(f"missing expected response text {expected_response!r}")
    if expected_marker not in blob:
        failures.append(f"missing expected result marker {expected_marker!r}")
    if d.get("error") not in (None, "", "None"):
        failures.append(f"result error is not null/empty: {d.get('error')!r}")

payload = {
    "db_path": db_path,
    "db_integrity": integrity,
    "target_job_id": job_id,
    "job": dict(job) if job else None,
    "target_job_result_rows": len(rows),
    "result_rows_safe": row_payloads,
    "expected_response_text": expected_response,
    "expected_result_marker": expected_marker,
    "failures": failures,
    "postflight_pass": not failures,
}

print(json.dumps(payload, indent=2, sort_keys=True))

if failures:
    sys.exit(42)
PY
}

pveso_preflight_script() {
  cat <<'PVESO'
set -euo pipefail

echo "pveso_hostname=$(hostname)"

ollama_active="$(systemctl is-active ollama.service)"
ollama_version="$(ollama --version 2>/dev/null || true)"

echo "ollama_service_active=$ollama_active expected=active"
echo "ollama_version=$ollama_version expected_contains=0.15.4"

test "$ollama_active" = "active"
printf '%s\n' "$ollama_version" | grep -F '0.15.4' >/dev/null

ss -ltnp | grep -E ':11434[[:space:]]' || true

local_11434_count="$(ss -ltnp | awk '$4 ~ /^127[.]0[.]0[.]1:11434$/ {n++} END {print n+0}')"
nonlocal_11434_count="$(ss -ltnp | awk '$4 ~ /:11434$/ && $4 !~ /^127[.]0[.]0[.]1:11434$/ && $4 !~ /^\[::1\]:11434$/ {n++} END {print n+0}')"
serve_count="$(ps -eo args | awk '/[o]llama serve/ {n++} END {print n+0}')"
runner_count="$(ps -eo args | awk '/[o]llama_llama_server|[o]llama runner|[r]unners\// {n++} END {print n+0}')"

echo "ollama_localhost_11434_listener_count=$local_11434_count expected_ge=1"
echo "ollama_nonlocal_11434_listener_count=$nonlocal_11434_count expected=0"
echo "ollama_serve_process_count=$serve_count expected_ge=1"
echo "ollama_runner_process_count=$runner_count expected=0"

test "$local_11434_count" -ge 1
test "$nonlocal_11434_count" = "0"
test "$serve_count" -ge 1
test "$runner_count" = "0"

ct101_status_line="$(pct status 101)"
ct101_status="$(printf '%s\n' "$ct101_status_line" | awk '{print $2}')"
ct101_onboot="$(pct config 101 | awk -F': ' '$1=="onboot"{print $2}')"

echo "ct101_status_line=$ct101_status_line"
echo "ct101_status=$ct101_status expected=stopped"
echo "ct101_onboot=$ct101_onboot expected=0"

test "$ct101_status" = "stopped"
test "$ct101_onboot" = "0"

echo "pveso_preflight=PASS"
PVESO
}

run_execute_approved() {
  local approval="${APC_OPERATOR_DISPATCH_APPROVAL:-}"
  if [ "$approval" != "$REQUIRED_EXEC_APPROVAL" ]; then
    echo "E3P_EXECUTION_REFUSED"
    echo "missing_or_wrong_approval_marker=true"
    echo "required=$REQUIRED_EXEC_APPROVAL"
    exit 64
  fi

  if [ ! -f "$HELPER_PATH" ]; then
    die "missing helper path: $HELPER_PATH"
  fi

  if [ ! -f "$ADAPTER_PATH" ]; then
    die "missing adapter path: $ADAPTER_PATH"
  fi

  mkdir -p "$RUN_DIR"
  write_recovery_hint "$RUN_DIR"

  echo "phase=$PHASE"
  echo "mode=execute-approved"
  echo "target_job_id=$JOB_ID"
  echo "run_dir=$RUN_DIR"
  echo "max_runtime_seconds=$MAX_RUNTIME_SECONDS"
  echo "approval_marker_valid=true"
  echo "execution_warning=real DB/model phase; do not rerun after timeout without read-only recovery"

  {
    echo "phase=$PHASE"
    echo "target_job_id=$JOB_ID"
    echo "expected_model=${EXPECTED_MODEL:-}"
    echo "max_runtime_seconds=$MAX_RUNTIME_SECONDS"
    echo "ctid=$CTID"
    echo "ct203_db_path=$CT203_DB_PATH"
    echo "helper_path=$HELPER_PATH"
    echo "adapter_path=$ADAPTER_PATH"
    echo "helper_required_approval=$HELPER_REQUIRED_APPROVAL"
  } > "$RUN_DIR/command.env.allowlist.txt"

  echo "=== ct203 preflight ==="
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" \
    "pct exec $CTID -- env APC_CT203_DB_PATH=$(printf '%q' "$CT203_DB_PATH") APC_TARGET_JOB_ID=$(printf '%q' "$JOB_ID") APC_EXPECTED_MODEL=$(printf '%q' "${EXPECTED_MODEL:-}") python3 -" \
    > "$RUN_DIR/preflight.json" \
    < <(ct203_preflight_python)

  cat "$RUN_DIR/preflight.json"

  echo "=== ct203 scheduler/persistent-worker env check ==="
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" \
    "pct exec $CTID -- bash -lc 'systemctl show edge-queue-controller.service -p Environment --value 2>/dev/null | tr \" \" \"\\n\" | grep -E \"^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=true\" && exit 50 || exit 0'"

  echo "=== pveso preflight ==="
  timeout 60 tailscale ssh "$PVESO_TS_SSH" 'bash -s' \
    > "$RUN_DIR/pveso_preflight.txt" \
    < <(pveso_preflight_script)
  cat "$RUN_DIR/pveso_preflight.txt"

  echo "=== dispatch execution ==="
  echo "dispatch_stdout=$RUN_DIR/dispatch.stdout.txt"
  echo "dispatch_stderr=$RUN_DIR/dispatch.stderr.txt"

  set +e
  APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL" \
  timeout "$MAX_RUNTIME_SECONDS" bash "$HELPER_PATH" \
    --job-id "$JOB_ID" \
    > "$RUN_DIR/dispatch.stdout.txt" \
    2> "$RUN_DIR/dispatch.stderr.txt"
  dispatch_rc="$?"
  set -e

  echo "dispatch_rc=$dispatch_rc"
  if [ "$dispatch_rc" -ne 0 ]; then
    echo "dispatch_failed_or_timed_out=true"
    echo "recovery_hint=$RUN_DIR/recovery_hint.txt"
    exit "$dispatch_rc"
  fi

  echo "=== ct203 postflight ==="
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" \
    "pct exec $CTID -- env APC_CT203_DB_PATH=$(printf '%q' "$CT203_DB_PATH") APC_TARGET_JOB_ID=$(printf '%q' "$JOB_ID") APC_EXPECTED_RESPONSE_TEXT=APC_E3P_OK APC_EXPECTED_RESULT_MARKER=APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT python3 -" \
    > "$RUN_DIR/db_postflight.json" \
    < <(ct203_postflight_python)

  cat "$RUN_DIR/db_postflight.json"

  echo "=== pveso runner postflight ==="
  timeout 60 tailscale ssh "$PVESO_TS_SSH" 'bash -lc '"'"'runner_count="$(ps -eo args | awk "/[o]llama_llama_server|[o]llama runner|[r]unners\\// {n++} END {print n+0}")"; echo "ollama_runner_process_count_after=$runner_count expected=0"; test "$runner_count" = "0"'"'"'' \
    | tee "$RUN_DIR/pveso_postflight.txt"

  {
    echo "RESULT=PASS_STAGE_16_E3P_D_OPERATOR_DISPATCH_ONE_JOB"
    echo "target_job_id=$JOB_ID"
    echo "run_dir=$RUN_DIR"
  } | tee "$RUN_DIR/final_status.txt"
}

MODE=""
JOB_ID=""
EXPECTED_MODEL=""
RUN_ROOT="$DEFAULT_RUN_ROOT"
MAX_RUNTIME_SECONDS="7200"
PVEW_SSH="$PVEW_SSH_DEFAULT"
PVESO_TS_SSH="$PVESO_TS_SSH_DEFAULT"
CTID="$CTID_DEFAULT"
CT203_DB_PATH="$CT203_DB_PATH_DEFAULT"
HELPER_PATH="$HELPER_DEFAULT"
ADAPTER_PATH="$ADAPTER_DEFAULT"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --contract)
      print_contract
      exit 0
      ;;
    --plan-only|--dry-run)
      MODE="plan-only"
      shift
      ;;
    --execute-approved)
      MODE="execute-approved"
      shift
      ;;
    --job-id)
      [ "$#" -ge 2 ] || die "--job-id requires a value"
      JOB_ID="$2"
      shift 2
      ;;
    --expected-model)
      [ "$#" -ge 2 ] || die "--expected-model requires a value"
      EXPECTED_MODEL="$2"
      shift 2
      ;;
    --run-root)
      [ "$#" -ge 2 ] || die "--run-root requires a value"
      RUN_ROOT="$2"
      shift 2
      ;;
    --max-runtime-seconds)
      [ "$#" -ge 2 ] || die "--max-runtime-seconds requires a value"
      MAX_RUNTIME_SECONDS="$2"
      shift 2
      ;;
    --pvew-ssh)
      [ "$#" -ge 2 ] || die "--pvew-ssh requires a value"
      PVEW_SSH="$2"
      shift 2
      ;;
    --pveso-ts-ssh)
      [ "$#" -ge 2 ] || die "--pveso-ts-ssh requires a value"
      PVESO_TS_SSH="$2"
      shift 2
      ;;
    --ctid)
      [ "$#" -ge 2 ] || die "--ctid requires a value"
      CTID="$2"
      shift 2
      ;;
    --ct203-db-path)
      [ "$#" -ge 2 ] || die "--ct203-db-path requires a value"
      CT203_DB_PATH="$2"
      shift 2
      ;;
    --helper-path)
      [ "$#" -ge 2 ] || die "--helper-path requires a value"
      HELPER_PATH="$2"
      shift 2
      ;;
    --adapter-path)
      [ "$#" -ge 2 ] || die "--adapter-path requires a value"
      ADAPTER_PATH="$2"
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

if [ -z "$MODE" ]; then
  usage
  exit 0
fi

validate_numeric_inputs

RUN_DIR="${RUN_ROOT%/}/job-${JOB_ID}-$(date -u +%Y%m%dT%H%M%SZ)"

case "$MODE" in
  plan-only)
    print_plan
    ;;
  execute-approved)
    run_execute_approved
    ;;
  *)
    die "unhandled mode: $MODE"
    ;;
esac
