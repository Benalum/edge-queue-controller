#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ej-b-insert-one-fresh-repeat-limited-persistent-worker-proof-job-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_EJ_B_INSERT_ONE_FRESH_REPEAT_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY"
  "job_id: 48"
  "stage16_e3z_limited_persistent_worker_repeat_proof"
  "qwen2.5:0.5b"
  "E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK"
  "status: queued"
  "attempts: 0"
  "result_rows: 0"
  "jobs_total: 47"
  "job_results_total: 27"
  "jobs_status_running: 0"
  "jobs_max_id: 48"
  "job 48 queued attempts=0 result_rows=0"
  "qwen25_router_small includes"
  "qwen25_router_small still includes"
  "qwen3_router_small does not include"
  "installed edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "REFUSE_WORKER_DISABLED"
  "APPROVE_STAGE_16_E3Z_EJ_C_RUN_REPEAT_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_48_ONLY"
  "Do not call models in EJ-B"
  "Do not claim job 48 in EJ-B"
  "Do not complete job 48 in EJ-B"
  "Do not enable model concurrency in EJ-B"
  "Do not insert more than one job in EJ-B"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EJ_B_SMOKE_OK=1"
