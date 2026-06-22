#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-c-r4-reset-stale-running-job48-to-queued-only.md"
[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Reset Stale Running Job 48 to Queued Only"
  "APPROVE_STAGE_16_E3Z_EJ_C_R4_RESET_STALE_RUNNING_JOB_48_TO_QUEUED_ONLY"
  "target job: 48 only"
  "repair action: status running -> queued"
  "attempts: preserved at 1"
  "result_rows: preserved at 0"
  "job_results: no rows created"
  "job 48 queued attempts=1 result_rows=0"
  "jobs_status_running: 0"
  "jobs 45, 46, 47 remain completed"
  "installed edge-ct101-ollama-worker.service inactive and disabled"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set"
  "only ollama container running"
  "REFUSE_WORKER_DISABLED"
  "R4 did not rerun job 48"
  "R4 did not call a model"
  "R4 did not complete or fail job 48"
  "R4 did not mutate jobs 37 through 47"
  "Proceed with EJ-C-R5"
  "exact-marker mismatch"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_C_R4_SMOKE_OK=1"
