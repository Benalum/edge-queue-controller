#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-cm-concurrency-proof-results-and-routing-defaults-plan.md"

needles=(
  "This stage is repo-only documentation and smoke"
  "job_results_total: 24"
  "jobs_status_running: 0"
  "E3Z-CON-QWEN25-A-OK"
  "E3Z-CON-QWEN25-B-OK"
  "E3Z-CON-QWEN3-A-OK"
  "E3Z-CON-QWEN3-B-OK"
  "concurrency batch elapsed seconds: 1.695"
  "model call overlap seconds: 1.452"
  "concurrency batch elapsed seconds: 0.792"
  "model call overlap seconds: 0.566"
  "--think=false"
  "--hidethinking"
  "claim endpoint currently behaves as one-at-a-time"
  "qwen2.5:0.5b"
  "qwen3:0.6b"
  "gemma4:e4b"
  "Do not rerun jobs 37 through 44"
  "Do not start CT101 persistent worker service"
  "Do not activate scheduler or timer"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_CM_SMOKE_OK=1"
