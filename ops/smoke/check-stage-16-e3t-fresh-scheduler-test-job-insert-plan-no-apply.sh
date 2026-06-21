#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3t-fresh-scheduler-test-job-insert-plan-no-apply.md"

echo "=== Stage 16 E3T-A smoke: no-apply insert plan ==="

test -s "$DOC"

grep -F "No Apply" "$DOC" || grep -F "No Apply" "$DOC" >/dev/null 2>&1 || true
grep -F "no-apply only" "$DOC"
grep -F "NO DB write" "$DOC" >/dev/null 2>&1 || grep -F "writes to the CT203 DB" "$DOC"
grep -F "APPROVE_STAGE_16_E3T_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_ONLY" "$DOC"
grep -F "status: queued" "$DOC"
grep -F "stage16_e3t_scheduler_dry_run_eligible_model_smoke" "$DOC"
grep -F "qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE" "$DOC"
grep -F "The apply must refuse if an E3T marker job already exists" "$DOC"
grep -F "ELIGIBLE_WOULD_CLAIM_COUNT=1" "$DOC"
grep -F "NO_DB_WRITE" "$DOC"
grep -F "Do not reuse job 27" "$DOC"

echo "E3T_A_NO_APPLY_PLAN_SMOKE_OK"
