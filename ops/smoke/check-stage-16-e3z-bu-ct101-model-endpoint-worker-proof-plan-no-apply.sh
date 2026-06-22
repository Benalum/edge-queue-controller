#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-bu-ct101-model-endpoint-worker-proof-plan-no-apply.md"

needles=(
  "This stage is no-apply"
  "Do not reuse jobs 35 or 36"
  "Stage 16 E3Z model endpoint proof A"
  "stage16_e3z_ct101_model_endpoint_worker_proof"
  "the next runtime proof must not blindly start Docker"
  "Do not unmask, enable, or start ai-platform-laptop-queue-worker.service"
  "Use a bounded one-shot script inside CT101"
  "only one job may become running"
  "Keep it enabled only while actively continuing the next proof"
  "Separate approvals are required"
)

for needle in "${needles[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_BU_SMOKE_OK=1"
