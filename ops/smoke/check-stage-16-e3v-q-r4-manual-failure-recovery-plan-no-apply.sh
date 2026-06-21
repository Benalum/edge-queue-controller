#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-q-r4-manual-failure-recovery-plan-no-apply.md"

echo "=== Stage 16 E3V-Q-R4 smoke: manual failure recovery plan, no apply ==="

test -s "$DOC"

grep -F "Manual Failure Recovery Plan, No Apply" "$DOC"
grep -F "does not modify the DB" "$DOC"
grep -F "does not rerun E3V-Q" "$DOC"
grep -F "status=running" "$DOC"
grep -F "attempts=1" "$DOC"
grep -F "result_rows=0" "$DOC"
grep -F "atomic claim succeeded" "$DOC"
grep -F "RECOVERY_R3_FINAL_CLASSIFICATION=running_zero_results_no_runner_no_artifact_manual_failure_plan_required" "$DOC"
grep -F "must not be completed as successful" "$DOC"
grep -F "must not be claimed again" "$DOC"
grep -F "must not be rerun" "$DOC"
grep -F "APPROVE_STAGE_16_E3V_Q_R5_MARK_JOB_29_FAILED_AFTER_TIMEOUT_NO_RESULT_ONLY" "$DOC"
grep -F "update jobs set status='failed'" "$DOC"
grep -F "must not:" "$DOC"
grep -F "call a model" "$DOC"
grep -F "insert job_results" "$DOC"
grep -F "REFUSE_ACTIVE_MODEL_CLIENT_OR_CONNECTION" "$DOC"
grep -F "REFUSE_MODEL_ARTIFACT_PRESENT" "$DOC"
grep -F "BEGIN IMMEDIATE" "$DOC"
grep -F "UPDATE jobs" "$DOC"
grep -F "SET status='failed'" "$DOC"
grep -F "E3V_Q_R5_FAILURE_UPDATE_CHANGES=1" "$DOC"
grep -F "REFUSE_FAILURE_UPDATE_NOT_ONE" "$DOC"
grep -F "E3V_Q_R5_MARK_JOB_29_FAILED_AFTER_TIMEOUT_NO_RESULT_OK" "$DOC"
grep -F "Runtime remains blocked" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"

echo "E3V_Q_R4_MANUAL_FAILURE_RECOVERY_PLAN_NO_APPLY_SMOKE_OK"
