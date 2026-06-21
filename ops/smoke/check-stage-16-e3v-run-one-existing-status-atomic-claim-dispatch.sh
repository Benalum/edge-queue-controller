#!/usr/bin/env bash
set -euo pipefail

WRAPPER="ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh"

echo "=== Stage 16 E3V-O smoke: runtime atomic-claim implementation static check, no run ==="

test -s "$WRAPPER"
test -x "$WRAPPER"
bash -n "$WRAPPER"

grep -F "APPROVE_STAGE_16_E3V_Q_RUN_JOB_29_OPTION_B_ATOMIC_CLAIM_DISPATCH_ONLY" "$WRAPPER"
grep -F "MODE=dry-run" "$WRAPPER"
grep -F "MODE=execute-approved" "$WRAPPER"
grep -F "REFUSE_APPROVAL_MISSING" "$WRAPPER"
grep -F "REFUSE_SELECTED_JOB_ID_NOT_29" "$WRAPPER"
grep -F "RUNTIME_SCOPE=job_id_29_only" "$WRAPPER"
grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$WRAPPER"
grep -F "PRAGMA query_only=ON" "$WRAPPER"
grep -F "E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1" "$WRAPPER"
grep -F "WOULD_ATOMIC_CLAIM job_id=29" "$WRAPPER"
grep -F "E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME" "$WRAPPER"
grep -F "PVESO_PREFLIGHT_OK" "$WRAPPER"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$WRAPPER"
grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0" "$WRAPPER"
grep -F "TARGET_MODEL_PRESENT=true" "$WRAPPER"
grep -F "CT101_STATUS=stopped" "$WRAPPER"
grep -F "CT101_ONBOOT=0" "$WRAPPER"
grep -F "BEGIN IMMEDIATE" "$WRAPPER"
grep -F "UPDATE jobs" "$WRAPPER"
grep -F "SET status='running'" "$WRAPPER"
grep -F "attempts=attempts+1" "$WRAPPER"
grep -F "E3V_Q_ATOMIC_CLAIM_CHANGES=1" "$WRAPPER"
grep -F "E3V_Q_JOB_STATUS_AFTER_CLAIM=running" "$WRAPPER"
grep -F "E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1" "$WRAPPER"
grep -F "REFUSE_ATOMIC_CLAIM_NOT_ONE" "$WRAPPER"
grep -F "http://127.0.0.1:11434/api/generate" "$WRAPPER"
grep -F "ONE_SHOT_MODEL_ADAPTER_RESULT=ok" "$WRAPPER"
grep -F "NO model pull" "$WRAPPER" || true
grep -F "SET status='completed'" "$WRAPPER"
grep -F "INSERT INTO job_results" "$WRAPPER"
grep -F "E3V_Q_COMPLETION_CHANGES=1" "$WRAPPER"
grep -F "E3V_Q_JOB_STATUS_AFTER_COMPLETION=completed" "$WRAPPER"
grep -F "E3V_Q_JOB_RESULT_ROWS_AFTER_COMPLETION=1" "$WRAPPER"
grep -F "REFUSE_COMPLETION_NOT_ONE" "$WRAPPER"
grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT_AFTER=0" "$WRAPPER"
grep -F "CT101_STATUS_AFTER=stopped" "$WRAPPER"
grep -F "CT101_ONBOOT_AFTER=0" "$WRAPPER"
grep -F "E3V_Q_OPTION_B_ATOMIC_CLAIM_DISPATCH_JOB_29_OK" "$WRAPPER"
grep -F "DO_NOT_RERUN" "$WRAPPER"
grep -F "RUN_READ_ONLY_RECOVERY_FIRST" "$WRAPPER"
grep -F "completed_with_one_result_do_not_rerun" "$WRAPPER"

if grep -F "REFUSE_E3V_EXECUTE_NOT_ENABLED" "$WRAPPER"; then
  echo "REFUSE_STATIC_SMOKE_EXECUTE_PATH_STILL_DISABLED"
  exit 1
fi

# Allow the wrapper to *check/refuse* EDGE_PERSISTENT_LANE_WORKERS_ENABLED=true.
# Forbid only activation/pull/run patterns in this static no-run smoke.
if grep -E "ollama pull|ollama run|systemctl (start|enable) |EDGE_PERSISTENT_LANE_WORKERS_ENABLED=true[[:space:]]*$" "$WRAPPER" | grep -v "grep -q '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=true\$'"; then
  echo "REFUSE_STATIC_SMOKE_FORBIDDEN_RUNTIME_ACTIVATION_PATTERN"
  exit 1
fi

echo "E3V_O_RUNTIME_ATOMIC_CLAIM_IMPLEMENTATION_STATIC_SMOKE_OK"
