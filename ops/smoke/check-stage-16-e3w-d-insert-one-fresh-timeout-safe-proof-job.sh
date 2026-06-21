#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3w-d-insert-one-fresh-timeout-safe-proof-job.md"

echo "=== Stage 16 E3W-D smoke: inserted one fresh timeout-safe proof job ==="

test -s "$DOC"

grep -F "Insert One Fresh Timeout-Safe Proof Job" "$DOC"
grep -F "E3W_D_INSERT_ONE_FRESH_TIMEOUT_SAFE_PROOF_JOB_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3W_D_INSERT_ONE_FRESH_TIMEOUT_SAFE_PROOF_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: 952ca8c" "$DOC"
grep -F "status=queued" "$DOC"
grep -F "attempts=0" "$DOC"
grep -F "requested_model=qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "job_type=stage16_e3w_timeout_safe_one_job_model_smoke" "$DOC"
grep -F "result_rows=0" "$DOC"
grep -F "E3W-D performed one guarded DB insert only" "$DOC"
grep -F "It did not:" "$DOC"
grep -F "claim a job" "$DOC"
grep -F "insert job_results" "$DOC"
grep -F "call a model" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "JOB29_PREFLIGHT id=29 status=failed" "$DOC"
grep -F "E3W_D_EXISTING_ELIGIBLE_MATCHING_JOB_COUNT=0" "$DOC"
grep -F "E3W_D_INSERTED_JOB_ID=" "$DOC"
grep -F "E3W_D_ELIGIBLE_MATCHING_JOB_COUNT_AFTER_INSERT_IN_TX=1" "$DOC"
grep -F "E3W_D_INSERT_ONE_FRESH_TIMEOUT_SAFE_PROOF_JOB_COMMIT_OK" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "E3W_D_ELIGIBLE_MATCHING_JOB_COUNT_POSTFLIGHT=1" "$DOC"
grep -F "E3W-E — dry-run timeout-safe wrapper would claim inserted job" "$DOC"
grep -F "must run the wrapper in --dry-run mode only" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"

echo "E3W_D_INSERT_ONE_FRESH_TIMEOUT_SAFE_PROOF_JOB_SMOKE_OK"
