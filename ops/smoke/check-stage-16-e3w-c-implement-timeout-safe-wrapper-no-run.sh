#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3w-c-implement-timeout-safe-wrapper-no-run.md"
WRAPPER="ops/scheduler/stage-16-e3w-timeout-safe-one-job-dispatch.sh"

echo "=== Stage 16 E3W-C smoke: timeout-safe wrapper implemented, no run ==="

test -s "$DOC"
test -s "$WRAPPER"
test -x "$WRAPPER"

bash -n "$WRAPPER"

grep -F "Implement Timeout-Safe Wrapper, No Run" "$DOC"
grep -F "E3W_C_TIMEOUT_SAFE_WRAPPER_IMPLEMENTED_NO_RUN_OK" "$DOC"
grep -F "$WRAPPER" "$DOC"
grep -F "APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "The wrapper explicitly refuses job 29" "$DOC"
grep -F "model timeout < wrapper total timeout" "$DOC"
grep -F "E3W_MODEL_TIMEOUT_SECONDS=45" "$DOC"
grep -F "E3W_WRAPPER_TOTAL_SECONDS=120" "$DOC"
grep -F "E3W_NUM_PREDICT=8" "$DOC"
grep -F "E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME" "$DOC"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$DOC"
grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$DOC"
grep -F "E3W_RUNTIME_COMPLETION_OK" "$DOC"
grep -F "E3W-D — insert one fresh timeout-safe proof job" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"

grep -F "REQUIRED_APPROVAL=\"APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY\"" "$WRAPPER"
grep -F "if [ \"\$JOB_ID\" = \"29\" ]" "$WRAPPER"
grep -F "refuse \"job 29 is closed failed and must not be retried\"" "$WRAPPER"
grep -F "E3W_TIMEOUT_SAFE_WRAPPER_DRY_RUN_ONLY" "$WRAPPER"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=" "$WRAPPER"
grep -F "REFUSE_E3W_ATOMIC_CLAIM_NOT_ONE" "$WRAPPER"
grep -F "E3W_ONE_SHOT_MODEL_RESULT=ok" "$WRAPPER"
grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=" "$WRAPPER"
grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_OK" "$WRAPPER"
grep -F "E3W_RUNTIME_COMPLETION_OK" "$WRAPPER"
grep -F "E3W_TIMEOUT_SAFE_RUNTIME_DONE" "$WRAPPER"

echo "E3W_C_TIMEOUT_SAFE_WRAPPER_IMPLEMENTED_NO_RUN_SMOKE_OK"
