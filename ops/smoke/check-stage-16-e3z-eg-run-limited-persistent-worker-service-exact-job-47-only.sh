#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-eg-run-limited-persistent-worker-service-exact-job-47-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_47_ONLY"
  "limited_persistent_one_job"
  "EDGE_ALLOWED_JOB_IDS: 47"
  "EDGE_EXIT_AFTER_ONE_SUCCESS: 1"
  "EDGE_MAX_RUNTIME_SECONDS: 180"
  "EDGE_ALLOW_MODEL_CONCURRENCY: 0"
  "stage16_e3z_limited_persistent_worker_one_job_proof"
  "E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK"
  "E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1"
  "job 47 completed attempts=1 result_rows=1"
  "jobs_total: 46"
  "job_results_total: 27"
  "jobs_status_running: 0"
  "jobs_max_id: 47"
  "installed edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "only ollama container running"
  "Do not enable or unmask CT101 worker services in EG"
  "Do not activate scheduler or timer in EG"
  "Do not claim any job other than 47"
  "Proceed with EH"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EG_SMOKE_OK=1"
