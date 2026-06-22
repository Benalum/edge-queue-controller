#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r8-reset-job48-and-repair-prompt-to-worker-marker-regex-only.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Reset Job 48 and Repair Prompt to Worker Marker Regex Only"
  "APPROVE_STAGE_16_E3Z_EJ_C_R8_RESET_JOB48_AND_REPAIR_PROMPT_TO_WORKER_MARKER_REGEX_ONLY"
  "nothing else:\\s*([A-Za-z0-9_.:-]+)\\s*$"
  "target job: 48 only"
  "status: running -> queued"
  "attempts: preserved at 2"
  "result_rows: preserved at 0"
  "job_results: no rows created"
  "model calls: none"
  "worker starts: none"
  "Return exactly this text and nothing else: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK"
  "job 48 queued attempts=2 result_rows=0 worker_regex_match=1"
  "jobs 45, 46, 47 remain completed"
  "installed edge-ct101-ollama-worker.service inactive and disabled"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set"
  "only ollama container running"
  "REFUSE_WORKER_DISABLED"
  "R8 did not rerun job 48"
  "R8 did not call a model"
  "R8 did not claim, complete, or fail job 48"
  "APPROVE_STAGE_16_E3Z_EJ_C_R9_RETRY_REPEAT_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_48_AFTER_REGEX_PROMPT_REPAIR"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_C_R8_SMOKE_OK=1"
