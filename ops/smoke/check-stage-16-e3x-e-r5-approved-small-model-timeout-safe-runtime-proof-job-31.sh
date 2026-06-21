#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3x-e-r5-approved-small-model-timeout-safe-runtime-proof-job-31.md"

echo "=== Stage 16 E3X-E-R5 smoke: approved small-model timeout-safe runtime proof job 31 ==="

test -s "$DOC"

grep -F "Approved Small-Model Timeout-Safe Runtime Proof for Job 31" "$DOC"
grep -F "E3X_E_R5_APPROVED_SMALL_MODEL_TIMEOUT_SAFE_RUNTIME_PROOF_JOB_31_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: 9c66d28" "$DOC"
grep -F "job_id=31" "$DOC"
grep -F "requested_model=qwen2.5:0.5b" "$DOC"
grep -F "job_type=stage16_e3x_small_model_timeout_safe_completion_smoke" "$DOC"
grep -F "one atomic claim for job 31" "$DOC"
grep -F "one bounded PVESO Ollama generate call to qwen2.5:0.5b" "$DOC"
grep -F "E3X_E_R5_RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "JOB31_PREFLIGHT id=31 status=queued attempts=0" "$DOC"
grep -F "E3X_E_R5_ELIGIBLE_SMALL_MODEL_JOB_COUNT_BEFORE=1" "$DOC"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$DOC"
grep -F "E3X_E_R5_ATOMIC_CLAIM_MARKER_PRESENT=true" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "JOB31_POSTFLIGHT id=31" "$DOC"
grep -F "attempts=1" "$DOC"
grep -F "E3X_E_R5_RUNTIME_CLASSIFICATION=" "$DOC"
grep -F "E3X_E_R5_READONLY_POSTFLIGHT_OK" "$DOC"
grep -F "job 31 did not remain running" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Do not rerun job 31 without a new explicit plan and approval" "$DOC"

if grep -F "E3X_E_R5_RUNTIME_CLASSIFICATION=completed_with_one_result" "$DOC" >/dev/null; then
  grep -F "E3W_RUNTIME_COMPLETION_OK" "$DOC"
  grep -F "E3X_E_R5_WRAPPER_COMPLETION_MARKER_PRESENT=true" "$DOC"
  grep -F "result_rows=1" "$DOC"
elif grep -F "E3X_E_R5_RUNTIME_CLASSIFICATION=internal_failure_no_result" "$DOC" >/dev/null; then
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$DOC"
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK" "$DOC"
  grep -F "E3X_E_R5_WRAPPER_INTERNAL_FAILURE_MARKER_PRESENT=true" "$DOC"
  grep -F "result_rows=0" "$DOC"
else
  echo "REFUSE_E3X_E_R5_CLASSIFICATION_MISSING"
  exit 1
fi

echo "E3X_E_R5_APPROVED_SMALL_MODEL_TIMEOUT_SAFE_RUNTIME_PROOF_JOB_31_SMOKE_OK"
