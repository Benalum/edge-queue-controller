#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ea-limited-persistent-worker-service-design-no-apply.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "repository-only no-apply planning stage"
  "job_id: 45"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "job_id: 46"
  "E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK"
  "jobs_total: 45"
  "job_results_total: 26"
  "E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK"
  "stage16_e3z_limited_persistent_worker_one_job_proof"
  "The first persistent worker proof must process exactly one eligible job"
  "EDGE_ALLOWED_JOB_IDS"
  "EDGE_EXIT_AFTER_ONE_SUCCESS"
  "EDGE_MAX_RUNTIME_SECONDS"
  "EDGE_REFUSE_IF_SCHEDULER_ACTIVE"
  "EDGE_REFUSE_IF_TIMER_ACTIVE"
  "APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START"
  "APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START"
  "APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY"
  "APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_ONLY"
  "Do not enable a production persistent worker loop"
  "Do not enable scheduler"
  "Do not enable timer"
  "Do not enable model concurrency"
  "Do not allow queue drain behavior"
  "Proceed with EB"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EA_SMOKE_OK=1"
