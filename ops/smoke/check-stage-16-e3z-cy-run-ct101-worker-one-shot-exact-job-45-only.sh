#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cy-run-ct101-worker-one-shot-exact-job-45-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_45_ONLY"
  "one CT101 worker process"
  "one exact job claim for job 45 only"
  "one model call to qwen2.5:0.5b"
  "one exact completion for job 45 only"
  "job_id: 45"
  "stage16_e3z_worker_one_shot_activation_proof"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "status: completed"
  "attempts: 1"
  "result_rows: 1"
  "job_results_total: 25"
  "jobs_status_running: 0"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains unchanged"
  "Next step is CZ"
  "Do not rerun jobs 37 through 45"
  "Do not insert additional jobs"
  "Do not start CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not enable model concurrency in the first worker activation"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CY_SMOKE_OK=1"
