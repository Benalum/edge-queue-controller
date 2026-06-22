#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ed-install-updated-worker-guards-disabled-only-no-start.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START"
  "Install Updated Worker Guards Disabled Only"
  "/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py"
  "EDGE_ALLOWED_JOB_IDS"
  "EDGE_EXIT_AFTER_ONE_SUCCESS"
  "EDGE_MAX_RUNTIME_SECONDS"
  "EDGE_REFUSE_IF_SCHEDULER_ACTIVE"
  "EDGE_REFUSE_IF_TIMER_ACTIVE"
  "EDGE_PROOF_MODE=limited_persistent_one_job"
  "REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED"
  "E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains set"
  "worker self-test passes on CT101"
  "REFUSE_WORKER_DISABLED"
  "jobs_total: 45"
  "job_results_total: 26"
  "jobs_status_running: 0"
  "jobs_max_id: 46"
  "E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK"
  "APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START"
  "Do not call models in ED"
  "Do not mutate CT203 DB in ED"
  "Do not enable persistent worker behavior in ED"
  "Do not enable model concurrency"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_ED_SMOKE_OK=1"
