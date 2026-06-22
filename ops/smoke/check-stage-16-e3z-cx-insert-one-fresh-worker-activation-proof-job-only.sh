#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cx-insert-one-fresh-worker-activation-proof-job-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_CX_INSERT_ONE_FRESH_WORKER_ACTIVATION_PROOF_JOB_ONLY"
  "inserted one queued job only"
  "job_id: 45"
  "stage16_e3z_worker_one_shot_activation_proof"
  "qwen2.5:0.5b"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "jobs_total: 44"
  "job_results_total: 24"
  "jobs_status_running: 0"
  "job 45 queued attempts=0 result_rows=0"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "EDGE_WORKER_ENABLED=0 remains installed"
  "APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_45_ONLY"
  "Do not rerun jobs 37 through 44"
  "Do not insert additional jobs"
  "Do not call models in CX"
  "Do not start CT101 persistent worker service"
  "Do not unmask CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not change CT203 claim endpoint behavior"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CX_SMOKE_OK=1"
