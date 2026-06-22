#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cu-ct101-worker-install-only-plan-no-apply.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "This is a repository-only no-apply planning stage"
  "jobs 37 through 44 completed attempts=1 result_rows=1"
  "ops/workers/ct101_minimal_ollama_worker.py"
  "ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"
  "/etc/edge-ct101-worker/ct101-worker.env"
  "EDGE_WORKER_ENABLED=0"
  "EDGE_CLAIM_POLICY=one_at_a_time"
  "EDGE_ALLOW_MODEL_CONCURRENCY=0"
  "EDGE_ALLOWED_CONTAINER_NAMES=ollama"
  "Do not start it"
  "Do not enable it"
  "Do not activate it through timers or scheduler"
  "APPROVE_STAGE_16_E3Z_CV_INSTALL_CT101_WORKER_FILES_DISABLED_ONLY_NO_START"
  "Activation would require a different explicit approval phrase"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not connect to live CT203 API in this repo-only plan"
  "Do not connect to live CT101 in this repo-only plan"
  "Do not start CT101 persistent worker service"
  "Do not unmask CT101 persistent worker service"
  "Do not activate scheduler or timer"
  "Do not create live systemd units in this stage"
  "Do not create runtime files under"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CU_SMOKE_OK=1"
