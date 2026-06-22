#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-bt-ct203-native-worker-endpoint-runtime-proof-summary.md"

needles=(
  "Stages E3Z-BQ through E3Z-BS proved the CT203-native SQLite internal worker endpoint path"
  "BQ enabled the CT203-native SQLite worker API flag"
  "BR proved direct CT203 endpoint claim and completion for job 35 only"
  "BS proved CT101-origin bounded one-shot endpoint client claim and completion for job 36 only"
  "job 35 response_text was E3Z-N-A-OK"
  "job 36 response_text was E3Z-N-B-OK"
  "job_results_total: 16"
  "jobs_status_running: 0"
  "CT101 worker service: inactive and masked"
  "Docker service: inactive"
  "Ollama service: inactive"
  "The next model-facing path should use fresh proof jobs and a separate approval boundary"
)

for needle in "${needles[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_BT_SMOKE_OK=1"
