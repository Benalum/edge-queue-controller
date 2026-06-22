#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-dc-insert-one-fresh-service-managed-worker-proof-job-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_DC_INSERT_ONE_FRESH_SERVICE_MANAGED_WORKER_PROOF_JOB_ONLY"
  "inserted one queued job only"
  "job_id: 46"
  "stage16_e3z_service_managed_worker_one_shot_proof"
  "qwen2.5:0.5b"
  "E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK"
  "status: queued"
  "attempts: 0"
  "result_rows: 0"
  "jobs_total: 45"
  "job_results_total: 25"
  "jobs_status_running: 0"
  "job 46 queued attempts=0 result_rows=0"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "EDGE_WORKER_ENABLED=0 remains installed"
  "APPROVE_STAGE_16_E3Z_DD_RUN_SERVICE_MANAGED_CT101_WORKER_ONE_SHOT_EXACT_JOB_46_ONLY"
  "Do not call models in DC"
  "Do not claim job 46 in DC"
  "Do not start CT101 worker service in DC"
  "Do not activate scheduler or timer"
  "Do not enable model concurrency yet"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_DC_SMOKE_OK=1"
