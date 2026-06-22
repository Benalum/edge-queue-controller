#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-da-service-managed-ct101-worker-one-shot-plan-no-apply.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "repository-only no-apply planning stage"
  "job_id: 45"
  "E3Z-WORKER-QWEN25-ONE-SHOT-OK"
  "jobs_total: 44"
  "job_results_total: 25"
  "stage16_e3z_service_managed_worker_one_shot_proof"
  "E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK"
  "APPROVE_STAGE_16_E3Z_DB_ADD_SERVICE_MANAGED_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START"
  "APPROVE_STAGE_16_E3Z_DC_INSERT_ONE_FRESH_SERVICE_MANAGED_WORKER_PROOF_JOB_ONLY"
  "APPROVE_STAGE_16_E3Z_DD_RUN_SERVICE_MANAGED_CT101_WORKER_ONE_SHOT_EXACT_JOB_ONLY"
  "systemd-run --wait --collect"
  "EDGE_WORKER_ENABLED=1"
  "EDGE_WORKER_ENABLED=0"
  "new edge-ct101-ollama-worker.service is inactive and disabled"
  "only ollama container is running"
  "no scheduler/timer activation"
  "This plan does not enable persistent workers"
  "This plan does not enable scheduler"
  "This plan does not enable timer"
  "This plan does not create a recurring worker loop"
  "This plan does not enable model concurrency"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_DA_SMOKE_OK=1"
