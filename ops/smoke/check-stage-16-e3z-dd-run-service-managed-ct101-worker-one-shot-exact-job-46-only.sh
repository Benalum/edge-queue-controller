#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-dd-run-service-managed-ct101-worker-one-shot-exact-job-46-only.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "APPROVE_STAGE_16_E3Z_DD_RUN_SERVICE_MANAGED_CT101_WORKER_ONE_SHOT_EXACT_JOB_46_ONLY"
  "transient systemd unit through systemd-run --wait --collect"
  "one exact job claim for job 46 only"
  "one model call to qwen2.5:0.5b"
  "one exact completion for job 46 only"
  "job_id: 46"
  "stage16_e3z_service_managed_worker_one_shot_proof"
  "E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK"
  "status: completed"
  "attempts: 1"
  "result_rows: 1"
  "jobs_total: 45"
  "job_results_total: 26"
  "jobs_status_running: 0"
  "max job id: 46"
  "new edge-ct101-ollama-worker.service inactive and disabled"
  "installed EDGE_WORKER_ENABLED=0 remains unchanged"
  "transient systemd unit not left active"
  "systemd-run --wait --collect --unit=edge-ct101-ollama-worker-oneshot-job46"
  "Next step is DE"
  "Do not rerun jobs 37 through 46"
  "Do not call models in DE"
  "Do not activate scheduler or timer"
  "Do not enable model concurrency yet"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_DD_SMOKE_OK=1"
