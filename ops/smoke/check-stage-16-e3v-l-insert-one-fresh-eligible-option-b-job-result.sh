#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3v-l-insert-one-fresh-eligible-option-b-job-result.md"

echo "=== Stage 16 E3V-L smoke: inserted one fresh eligible Option B job result ==="

test -s "$DOC"

grep -F "E3V_L_INSERT_ONE_FRESH_ELIGIBLE_JOB_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3V_L_INSERT_ONE_FRESH_ELIGIBLE_OPTION_B_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: a2c5f53" "$DOC"
grep -F "INSERT INTO jobs" "$DOC"
grep -F "E3V-L did not:" "$DOC"
grep -F "claim a job" "$DOC"
grep -F "call a model" "$DOC"
grep -F "insert job_results" "$DOC"
grep -F "E3V_L_INSERTED_FRESH_JOB_ID=" "$DOC"
grep -F "E3V_L_INSERTED_JOB_STATUS=queued" "$DOC"
grep -F "E3V_L_INSERTED_JOB_ATTEMPTS=0" "$DOC"
grep -F "E3V_L_INSERTED_JOB_MODEL=qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "E3V_L_INSERTED_JOB_TYPE=stage16_e3v_option_b_atomic_claim_fresh_model_smoke" "$DOC"
grep -F "E3V_L_INSERTED_JOB_RESULT_ROWS=0" "$DOC"
grep -F "E3V_L_ELIGIBLE_JOB_COUNT_AFTER=1" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "DUPLICATE_JOB_RESULTS_BEFORE none" "$DOC"
grep -F "DUPLICATE_JOB_RESULTS_AFTER none" "$DOC"
grep -F "DB stat changed as expected" "$DOC"
grep -F "Runtime remains blocked" "$DOC"
grep -F "E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1" "$DOC"
grep -F "E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME" "$DOC"
grep -F "E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK" "$DOC"

echo "E3V_L_DOC_SMOKE_OK"
