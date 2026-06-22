#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cv-r2-install-ct101-worker-disabled-postflight-recovery.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "cleanup/postflight failure"
  "unset under"
  "read-only live postflight validation"
  "jobs_total remains 43"
  "job_results_total remains 24"
  "jobs_status_running remains 0"
  "jobs 37 through 44 remain completed attempts=1 result_rows=1"
  "/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py"
  "/etc/edge-ct101-worker/model-profiles.yaml"
  "/etc/edge-ct101-worker/ct101-worker.env"
  "/etc/systemd/system/edge-ct101-ollama-worker.service"
  "EDGE_WORKER_ENABLED=0"
  "EDGE_CLAIM_POLICY=one_at_a_time"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0"
  "REFUSE_WORKER_DISABLED"
  "new CT101 worker inactive and disabled"
  "Activation must be separate from install"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not start CT101 persistent worker service"
  "Do not unmask CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not create or modify installed runtime files in R2"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CV_R2_SMOKE_OK=1"
