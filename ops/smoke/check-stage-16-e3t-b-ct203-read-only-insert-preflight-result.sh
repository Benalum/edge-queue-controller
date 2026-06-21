#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3t-b-ct203-read-only-insert-preflight-result.md"

echo "=== Stage 16 E3T-B-R2 smoke: documented read-only insert preflight ==="

test -s "$DOC"

grep -F "E3T_B_CT203_READ_ONLY_INSERT_PREFLIGHT_OK" "$DOC"
grep -F "no DB write" "$DOC"
grep -F "JOBS_COUNT=26" "$DOC"
grep -F "JOB_RESULTS_COUNT=9" "$DOC"
grep -F "MAX_JOB_ID=27" "$DOC"
grep -F "DB_INTEGRITY=ok" "$DOC"
grep -F "job_type" "$DOC"
grep -F "prompt" "$DOC"
grep -F "requested_model" "$DOC"
grep -F "status" "$DOC"
grep -F "LANE_COLUMN=None" "$DOC"
grep -F "E3T_MARKER_HITS=0" "$DOC"
grep -F "E3T_JOB_TYPE_HITS=0" "$DOC"
grep -F "E3T_INSERT_PREFLIGHT=OK_NO_EXISTING_E3T_MARKER" "$DOC"
grep -F "APPROVE_STAGE_16_E3T_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_ONLY" "$DOC"
grep -F "stage16_e3t_scheduler_dry_run_eligible_model_smoke" "$DOC"
grep -F "APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE" "$DOC"
grep -F "qwen2.5:32b-instruct-q4_K_M" "$DOC"
grep -F "Do not reuse job 27" "$DOC"

echo "E3T_B_R2_DOC_SMOKE_OK"
