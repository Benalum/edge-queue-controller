#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-bk-ct203-native-sqlite-internal-worker-endpoints-no-apply.md"

needles=(
  "Do not revive Postgres"
  "GET /internal/edge-worker/summary"
  "POST /internal/edge-worker/jobs/claim"
  "POST /internal/edge-worker/jobs/{job_id}/complete"
  "EDGE_CT203_SQLITE_WORKER_API_ENABLED=0"
  "Use a single SQLite transaction"
  "Do not start Docker or Ollama for the first CT203-native API proof"
  "Keep ai-platform-laptop-queue-worker.service masked/inactive"
  "Stage 16 E3Z-BL should implement the disabled CT203-native SQLite internal worker endpoint skeleton"
)

for needle in "${needles[@]}"; do
  if ! grep -Fq "$needle" "$DOC"; then
    echo "MISSING_NEEDLE=$needle"
    exit 1
  fi
done

echo "E3Z_BK_R3_SMOKE_OK=1"
