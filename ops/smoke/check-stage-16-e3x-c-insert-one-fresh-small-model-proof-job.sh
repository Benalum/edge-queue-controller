#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3x-c-insert-one-fresh-small-model-proof-job.md"

echo "=== Stage 16 E3X-C smoke: inserted one fresh small-model proof job ==="

test -s "$DOC"

grep -F "Insert One Fresh Small-Model Proof Job" "$DOC"
grep -F "E3X_C_INSERT_ONE_FRESH_SMALL_MODEL_PROOF_JOB_OK" "$DOC"
grep -F "APPROVE_STAGE_16_E3X_C_INSERT_ONE_FRESH_SMALL_MODEL_PROOF_JOB_ONLY" "$DOC"
grep -F "HEAD/origin/main/remote: 90c1f4c" "$DOC"
grep -F "job_id=31" "$DOC"
grep -F "requested_model=qwen2.5:0.5b" "$DOC"
grep -F "job_type=stage16_e3x_small_model_timeout_safe_completion_smoke" "$DOC"
grep -F "status=queued" "$DOC"
grep -F "attempts=0" "$DOC"
grep -F "result_rows=0" "$DOC"
grep -F "E3X_C_SMALL_MODEL_VISIBLE_TO_HOST_OLLAMA=true" "$DOC"
grep -F "E3X_C_PVESO_MODEL_PREFLIGHT_OK" "$DOC"
grep -F "DB_INTEGRITY_BEFORE=ok" "$DOC"
grep -F "DB_INTEGRITY_AFTER=ok" "$DOC"
grep -F "JOB_RESULTS_TOTAL_AFTER=10" "$DOC"
grep -F "E3X_C_EXISTING_ELIGIBLE_SMALL_MODEL_JOB_COUNT_BEFORE=0" "$DOC"
grep -F "E3X_C_ELIGIBLE_SMALL_MODEL_JOB_COUNT_AFTER=1" "$DOC"
grep -F "E3X-C did not:" "$DOC"
grep -F "claim the job" "$DOC"
grep -F "call a model" "$DOC"
grep -F "insert job_results" "$DOC"
grep -F "E3X-D — dry-run timeout-safe wrapper would-claim fresh small-model job" "$DOC"
grep -F "E3X-D must not claim the job or call the model" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Use job 31 for the small-model completion proof path" "$DOC"

echo "E3X_C_INSERT_ONE_FRESH_SMALL_MODEL_PROOF_JOB_SMOKE_OK"
