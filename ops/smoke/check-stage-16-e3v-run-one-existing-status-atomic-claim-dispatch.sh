#!/usr/bin/env bash
set -euo pipefail

WRAPPER="ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh"

echo "=== Stage 16 E3V-I smoke: dry-run-only wrapper guard implementation static check ==="

test -s "$WRAPPER"
test -x "$WRAPPER"

grep -F "MODE=dry-run" "$WRAPPER"
grep -F "REFUSE_E3V_EXECUTE_NOT_ENABLED" "$WRAPPER"
grep -F "NO_DB_WRITE" "$WRAPPER"
grep -F "NO_SCHEMA_MIGRATION" "$WRAPPER"
grep -F "NO_DB_CLAIM" "$WRAPPER"
grep -F "NO_HELPER_CALL" "$WRAPPER"
grep -F "NO_ADAPTER_CALL" "$WRAPPER"
grep -F "NO_MODEL_CALL" "$WRAPPER"
grep -F "SCHEDULER_ACTIVATION=not_performed" "$WRAPPER"
grep -F "PERSISTENT_WORKER_ACTIVATION=not_performed" "$WRAPPER"
grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$WRAPPER"
grep -F "PRAGMA query_only=ON" "$WRAPPER"
grep -F "DUPLICATE_JOB_RESULTS none" "$WRAPPER"
grep -F "E3V_DRY_RUN_ELIGIBLE_JOB_COUNT" "$WRAPPER"
grep -F "E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME" "$WRAPPER"
grep -F "WOULD_ATOMIC_CLAIM job_id=" "$WRAPPER"
grep -F "REFUSE_MULTIPLE_ELIGIBLE_JOBS" "$WRAPPER"
grep -F "REFUSE_FORBIDDEN_JOB_ID" "$WRAPPER"
grep -F "23 24 27 28" "$WRAPPER"
grep -F "qwen2.5:32b-instruct-q4_K_M" "$WRAPPER"
grep -F "tailscale status" "$WRAPPER"
grep -F "root@\$pveso_ip" "$WRAPPER"
grep -F "OLLAMA_LOCALHOST_11434_LISTENER_COUNT" "$WRAPPER"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT" "$WRAPPER"
grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT" "$WRAPPER"
grep -F "TARGET_MODEL_PRESENT=true" "$WRAPPER"
grep -F "CT101_STATUS=" "$WRAPPER"
grep -F "CT101_ONBOOT=" "$WRAPPER"
grep -F "CT203_DB_STAT_UNCHANGED=true" "$WRAPPER"
grep -F "E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK" "$WRAPPER"
grep -F "APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY" "$WRAPPER"

if grep -E "curl .*11434|/api/generate|ollama run|ollama pull|INSERT INTO job_results|UPDATE jobs SET status='running'|UPDATE jobs" "$WRAPPER"; then
  echo "REFUSE_STATIC_SMOKE_RUNTIME_OR_DB_WRITE_PATTERN"
  exit 1
fi

echo "E3V_I_DRY_RUN_ONLY_WRAPPER_GUARD_STATIC_SMOKE_OK"
