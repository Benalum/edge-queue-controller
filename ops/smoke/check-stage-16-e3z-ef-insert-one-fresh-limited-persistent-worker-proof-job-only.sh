#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ef-insert-one-fresh-limited-persistent-worker-proof-job-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY"
  "job_id: 47"
  "stage16_e3z_limited_persistent_worker_one_job_proof"
  "qwen2.5:0.5b"
  "E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK"
  "status: queued"
  "attempts: 0"
  "result_rows: 0"
  "jobs_total: 46"
  "job_results_total: 26"
  "jobs_status_running: 0"
  "jobs_max_id: 47"
  "job 47 queued attempts=0 result_rows=0"
  "qwen25_router_small includes"
  "qwen3_router_small does not include"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "REFUSE_WORKER_DISABLED"
  "APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_47_ONLY"
  "Do not call models in EF"
  "Do not claim job 47 in EF"
  "Do not complete job 47 in EF"
  "Do not enable model concurrency in EF"
  "Do not insert more than one job in EF"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EF_SMOKE_OK=1"
