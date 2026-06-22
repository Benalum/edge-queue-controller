#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cz-read-only-post-activation-guard.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Read-Only Post-Activation Guard"
  "This stage did not mutate CT203 DB state"
  "job_id: 45"
  "stage16_e3z_worker_one_shot_activation_proof"
  "qwen2.5:0.5b"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "jobs_total: 44"
  "job_results_total: 25"
  "jobs_status_running: 0"
  "Jobs 37 through 45 remain completed"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "REFUSE_WORKER_DISABLED"
  "only ollama container running"
  "no scheduler activation"
  "no timer activation"
  "no persistent worker activation"
  "The installed CT101 worker can run as a bounded one-shot process"
  "Stage 16 E3Z-DA"
  "Do not rerun jobs 37 through 45"
  "Do not call models in CZ"
  "Do not enable model concurrency yet"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CZ_SMOKE_OK=1"
