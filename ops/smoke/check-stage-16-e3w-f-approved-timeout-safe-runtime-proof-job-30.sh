#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3w-f-approved-timeout-safe-runtime-proof-job-30.md"

echo "=== Stage 16 E3W-F smoke: approved timeout-safe runtime proof job 30 ==="

test -s "$DOC"

grep -F "Approved Timeout-Safe Runtime Proof for Job 30" "$DOC"
grep -F "E3W_F_APPROVED_TIMEOUT_SAFE_RUNTIME_PROOF_JOB_30_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: b61d606" "$DOC"
grep -F "job_id=30" "$DOC"
grep -F "requested_model=qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "job_type=stage16_e3w_timeout_safe_one_job_model_smoke" "$DOC"
grep -F "one atomic claim for job 30" "$DOC"
grep -F "one bounded PVESO Ollama generate call" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "JOB30_PREFLIGHT id=30 status=queued attempts=0" "$DOC"
grep -F "E3W_F_ELIGIBLE_MATCHING_JOB_COUNT_BEFORE=1" "$DOC"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$DOC"
grep -F "E3W_F_ATOMIC_CLAIM_MARKER_PRESENT=true" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "JOB30_POSTFLIGHT id=30" "$DOC"
grep -F "attempts=1" "$DOC"
grep -F "E3W_F_RUNTIME_CLASSIFICATION=" "$DOC"
grep -F "E3W_F_READONLY_POSTFLIGHT_OK" "$DOC"
grep -F "job 30 did not remain running" "$DOC"
grep -F "avoided the E3V-Q failure mode" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30 without a new explicit plan and approval" "$DOC"

if grep -F "E3W_F_RUNTIME_CLASSIFICATION=completed_with_one_result" "$DOC" >/dev/null; then
  grep -F "E3W_RUNTIME_COMPLETION_OK" "$DOC"
  grep -F "E3W_F_WRAPPER_COMPLETION_MARKER_PRESENT=true" "$DOC"
  grep -F "result_rows=1" "$DOC"
elif grep -F "E3W_F_RUNTIME_CLASSIFICATION=internal_failure_no_result" "$DOC" >/dev/null; then
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$DOC"
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK" "$DOC"
  grep -F "E3W_F_WRAPPER_INTERNAL_FAILURE_MARKER_PRESENT=true" "$DOC"
  grep -F "result_rows=0" "$DOC"
else
  echo "REFUSE_E3W_F_CLASSIFICATION_MISSING"
  exit 1
fi

echo "E3W_F_APPROVED_TIMEOUT_SAFE_RUNTIME_PROOF_JOB_30_SMOKE_OK"
