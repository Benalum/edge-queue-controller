#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-de-service-managed-postflight-read-only-guard.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "Service-Managed Postflight Read-Only Guard"
  "did not mutate CT203 DB state"
  "edge-ct101-ollama-worker-oneshot-job46.service"
  "systemd-run --wait --collect"
  "job_id: 46"
  "stage16_e3z_service_managed_worker_one_shot_proof"
  "E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK"
  "job_id: 45"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "jobs_total: 45"
  "job_results_total: 26"
  "jobs_status_running: 0"
  "jobs_max_id: 46"
  "Jobs 37 through 46 remain completed"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "transient edge-ct101-ollama-worker-oneshot-job46.service is not left active"
  "REFUSE_WORKER_DISABLED"
  "only ollama container running"
  "no scheduler activation"
  "no timer activation"
  "no persistent worker activation"
  "Stage 16 E3Z-EA"
  "Do not rerun jobs 37 through 46"
  "Do not call models in DE"
  "Do not enable model concurrency yet"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_DE_SMOKE_OK=1"
