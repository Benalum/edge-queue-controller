#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3y-c-insert-one-fresh-scheduler-selected-small-model-job.md"

echo "=== Stage 16 E3Y-C smoke: insert one fresh scheduler-selected small-model job ==="

test -s "$DOC"

grep -F "Insert One Fresh Scheduler-Selected Small-Model Job" "$DOC"
grep -F "E3Y_C_INSERT_ONE_FRESH_SCHEDULER_SELECTED_SMALL_MODEL_JOB_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3Y_C_INSERT_ONE_FRESH_SCHEDULER_SELECTED_SMALL_MODEL_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: 5c54554" "$DOC"
grep -F "requested_model=qwen2.5:0.5b" "$DOC"
grep -F "job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke" "$DOC"
grep -F "status=queued" "$DOC"
grep -F "attempts=0" "$DOC"
grep -F "result_rows=0" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "JOBS_TOTAL_BEFORE=30" "$DOC"
grep -F "JOB_RESULTS_TOTAL_BEFORE=11" "$DOC"
grep -F "E3Y_C_EXISTING_ELIGIBLE_SCHEDULER_SELECTED_JOB_COUNT_BEFORE=0" "$DOC"
grep -F "JOBS_TOTAL_AFTER=31" "$DOC"
grep -F "JOB_RESULTS_TOTAL_AFTER=11" "$DOC"
grep -F "E3Y_C_ELIGIBLE_SCHEDULER_SELECTED_JOB_COUNT_AFTER=1" "$DOC"
grep -F "E3Y-C did not:" "$DOC"
grep -F "claim the job" "$DOC"
grep -F "call a model" "$DOC"
grep -F "activate scheduler" "$DOC"
grep -F "activate persistent workers" "$DOC"
grep -F "E3Y-D — implement one-shot scheduler wrapper, no run" "$DOC"
grep -F "No DB write. No claim. No model call. No scheduler activation." "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Do not rerun job 31" "$DOC"
grep -F "only for the E3Y scheduler one-shot proof path" "$DOC"

echo "E3Y_C_INSERT_ONE_FRESH_SCHEDULER_SELECTED_SMALL_MODEL_JOB_SMOKE_OK"
