#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3y-f-approved-one-shot-scheduler-runtime-proof-job-32.md"

echo "=== Stage 16 E3Y-F smoke: approved one-shot scheduler runtime proof job 32 ==="

test -s "$DOC"

grep -F "Approved One-Shot Scheduler Runtime Proof for Job 32" "$DOC"
grep -F "E3Y_F_APPROVED_ONE_SHOT_SCHEDULER_RUNTIME_PROOF_JOB_32_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3Y_F_RUN_ONE_SHOT_SCHEDULER_SMALL_MODEL_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: 1ed6e5d" "$DOC"
grep -F "job_id=32" "$DOC"
grep -F "requested_model=qwen2.5:0.5b" "$DOC"
grep -F "job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke" "$DOC"
grep -F "one scheduler one-shot invocation" "$DOC"
grep -F "one timeout-safe wrapper delegation" "$DOC"
grep -F "one bounded PVESO Ollama generate call to qwen2.5:0.5b" "$DOC"
grep -F "E3Y_F_SCHEDULER_APPROVAL_ACCEPTED=true" "$DOC"
grep -F "E3Y_F_SCHEDULER_DELEGATION_MARKER_PRESENT=true" "$DOC"
grep -F "E3Y_F_WRAPPER_APPROVAL_OVERRIDE_ACCEPTED=true" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "JOB_32_PREFLIGHT id=32 status=queued attempts=0" "$DOC"
grep -F "E3Y_F_ELIGIBLE_SCHEDULER_SELECTED_JOB_COUNT_BEFORE=1" "$DOC"
grep -F "E3Y_ONE_SHOT_SCHEDULER_APPROVAL_ACCEPTED=true" "$DOC"
grep -F "E3Y_ONE_SHOT_SCHEDULER_DELEGATING_TO_TIMEOUT_SAFE_WRAPPER=true" "$DOC"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$DOC"
grep -F "E3Y_F_ATOMIC_CLAIM_MARKER_PRESENT=true" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "JOB32_POSTFLIGHT id=32" "$DOC"
grep -F "attempts=1" "$DOC"
grep -F "E3Y_F_RUNTIME_CLASSIFICATION=" "$DOC"
grep -F "E3Y_F_RUNNING_STAGE16_PROOF_JOB_COUNT_AFTER=0" "$DOC"
grep -F "E3Y_F_READONLY_POSTFLIGHT_OK" "$DOC"
grep -F "E3Y-F proves the manually invoked scheduler one-shot path" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Do not rerun job 31" "$DOC"
grep -F "Do not rerun job 32 without a new explicit plan and approval" "$DOC"

if grep -F "E3Y_F_RUNTIME_CLASSIFICATION=completed_with_one_result" "$DOC" >/dev/null; then
  grep -F "E3W_RUNTIME_COMPLETION_OK" "$DOC"
  grep -F "E3Y_F_WRAPPER_COMPLETION_MARKER_PRESENT=true" "$DOC"
  grep -F "E3Y_F_SCHEDULER_RUNTIME_DELEGATION_DONE_MARKER_PRESENT=true" "$DOC"
  grep -F "result_rows=1" "$DOC"
elif grep -F "E3Y_F_RUNTIME_CLASSIFICATION=internal_failure_no_result" "$DOC" >/dev/null; then
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$DOC"
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK" "$DOC"
  grep -F "E3Y_F_WRAPPER_INTERNAL_FAILURE_MARKER_PRESENT=true" "$DOC"
  grep -F "result_rows=0" "$DOC"
else
  echo "REFUSE_E3Y_F_CLASSIFICATION_MISSING"
  exit 1
fi

echo "E3Y_F_APPROVED_ONE_SHOT_SCHEDULER_RUNTIME_PROOF_JOB_32_SMOKE_OK"
