#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r5-prompt-repair-job48-repeat-marker-only-no-worker-start.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Prompt Repair Job 48 Repeat Marker Only"
  "APPROVE_STAGE_16_E3Z_EJ_C_R5_PROMPT_REPAIR_JOB_48_REPEAT_MARKER_ONLY_NO_WORKER_START"
  "target job: 48 only"
  "updated_fields:"
  "status: preserved as queued"
  "attempts: preserved at 1"
  "result_rows: preserved at 0"
  "job_results: no rows created"
  "model calls: none"
  "worker starts: none"
  "E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK"
  "job_48_prompt_repaired_exact=1"
  "job 48 queued attempts=1 result_rows=0"
  "jobs 45, 46, 47 remain completed"
  "installed edge-ct101-ollama-worker.service inactive and disabled"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set"
  "only ollama container running"
  "REFUSE_WORKER_DISABLED"
  "R5 did not rerun job 48"
  "R5 did not call a model"
  "R5 did not claim, complete, or fail job 48"
  "R5 did not mutate jobs 37 through 47"
  "APPROVE_STAGE_16_E3Z_EJ_C_R6_RETRY_REPEAT_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_48_ONLY"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_C_R5_SMOKE_OK=1"
