#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3x-d-dry-run-timeout-safe-wrapper-would-claim-job-31.md"

echo "=== Stage 16 E3X-D smoke: dry-run timeout-safe wrapper would claim job 31 ==="

test -s "$DOC"

grep -F "Dry-Run Timeout-Safe Wrapper Would Claim Job 31" "$DOC"
grep -F "E3X_D_DRY_RUN_TIMEOUT_SAFE_WRAPPER_WOULD_CLAIM_JOB_31_OK" "$DOC"
grep -F "HEAD/origin/main/remote: 9d510f8" "$DOC"
grep -F "job_id=31" "$DOC"
grep -F "requested_model=qwen2.5:0.5b" "$DOC"
grep -F "job_type=stage16_e3x_small_model_timeout_safe_completion_smoke" "$DOC"
grep -F "model_timeout_seconds=45" "$DOC"
grep -F "wrapper_total_seconds=120" "$DOC"
grep -F "num_predict=8" "$DOC"
grep -F "E3W_TIMEOUT_SAFE_WRAPPER_DRY_RUN_ONLY" "$DOC"
grep -F "E3W_READONLY_CANDIDATE_PREFLIGHT_OK" "$DOC"
grep -F "E3W_CANDIDATE_JOB id=31 status=queued attempts=0" "$DOC"
grep -F "E3W_EXPECTED_ELIGIBLE_JOB_COUNT=1" "$DOC"
grep -F "E3W_PVESO_PREFLIGHT_OK" "$DOC"
grep -F "WOULD_ATOMIC_CLAIM job_id=31 model=qwen2.5:0.5b" "$DOC"
grep -F "WOULD_MARK_FAILED_INTERNALLY_ON_MODEL_TIMEOUT_OR_ERROR" "$DOC"
grep -F "E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME" "$DOC"
grep -F "E3X_D_DB_STAT_UNCHANGED_DURING_DRY_RUN=true" "$DOC"
grep -F "JOB31_AFTER_DRY_RUN id=31 status=queued attempts=0" "$DOC"
grep -F "E3X_D_ELIGIBLE_SMALL_MODEL_JOB_COUNT_AFTER_DRY_RUN=1" "$DOC"
grep -F "E3X_D_READONLY_POSTFLIGHT_OK" "$DOC"
grep -F "E3X-E — approved timeout-safe runtime completion proof for job 31" "$DOC"
grep -F "APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Use job 31 only for the approved small-model completion proof path" "$DOC"

echo "E3X_D_DRY_RUN_TIMEOUT_SAFE_WRAPPER_WOULD_CLAIM_JOB_31_SMOKE_OK"
