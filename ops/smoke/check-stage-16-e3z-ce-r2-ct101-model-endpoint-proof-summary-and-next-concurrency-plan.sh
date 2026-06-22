#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ce-r2-ct101-model-endpoint-proof-summary-and-next-concurrency-plan.md"

needles=(
  "This stage is repo-only documentation and smoke"
  "qwen2.5:0.5b"
  "gemma4:e4b"
  "Job 37"
  "E3Z-MODEL-A-OK"
  "Job 38"
  "ENDPOINT-PROOF-E3Z-MODEL-B OK"
  "transport_success_response_adherence_failure"
  "The CT203-to-CT101 model transport path is proven"
  "Exact model response adherence is not fully proven"
  "Create fresh jobs instead of reusing jobs 37 and 38"
  "router_small"
  "study_light"
  "companion_default"
  "deep_large"
  "Do not rerun job 37"
  "Do not rerun job 38"
  "Do not start CT101 persistent worker service"
)

for needle in "${needles[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CE_R2_SMOKE_OK=1"
