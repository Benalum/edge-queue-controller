#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ci-deterministic-model-proof-summary-and-concurrency-probe-plan.md"

needles=(
  "This stage is repo-only documentation and smoke"
  "jobs_total: 39"
  "job_results_total: 20"
  "E3Z-DET-QWEN25-OK"
  "E3Z-DET-QWEN3-OK"
  "--think=false --hidethinking"
  "incorrect syntax --think false"
  "false as the model-name token"
  "bounded small-model concurrency probe"
  "qwen2.5:0.5b"
  "qwen3:0.6b"
  "E3Z-CON-QWEN25-A-OK"
  "E3Z-CON-QWEN3-A-OK"
  "Do not rerun jobs 37, 38, 39, or 40"
  "Do not start CT101 persistent worker service"
  "Do not activate scheduler or timer"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CI_R2_SMOKE_OK=1"
