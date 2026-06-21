#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3t-c-e3s-r4-insert-and-read-only-would-claim-result.md"

echo "=== Stage 16 E3T-C/E3S-R4 smoke: documented insert and would-claim result ==="

test -s "$DOC"

grep -F "E3T_C_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_OK" "$DOC"
grep -F "E3S_R4_CT203_READ_ONLY_DRY_RUN_WOULD_CLAIM_JOB_28_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3T_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_ONLY" "$DOC"
grep -F "NEW_JOB_ID=28" "$DOC"
grep -F "JOBS_BEFORE=26" "$DOC"
grep -F "JOBS_AFTER=27" "$DOC"
grep -F "JOB_RESULTS_AFTER=9" "$DOC"
grep -F "NEW_JOB_STATUS=queued" "$DOC"
grep -F "NEW_JOB_TYPE=stage16_e3t_scheduler_dry_run_eligible_model_smoke" "$DOC"
grep -F "NEW_JOB_MODEL=qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "NEW_JOB_PROMPT=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE" "$DOC"
grep -F "NEW_JOB_ATTEMPTS=0" "$DOC"
grep -F "NEW_JOB_RESULT_ROWS=0" "$DOC"
grep -F "NO_DB_WRITE" "$DOC"
grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$DOC"
grep -F "QUEUED_INSPECTED=3" "$DOC"
grep -F "ELIGIBLE_WOULD_CLAIM_COUNT=1" "$DOC"
grep -F "WOULD_CLAIM job_id=28" "$DOC"
grep -F "REJECT model_not_allowlisted job_id=23" "$DOC"
grep -F "REJECT model_not_allowlisted job_id=24" "$DOC"
grep -F "scheduler activation=not performed" "$DOC"
grep -F "persistent worker activation=not performed" "$DOC"
grep -F "Do not reuse job 27" "$DOC"

echo "E3T_C_E3S_R4_DOC_SMOKE_OK"
