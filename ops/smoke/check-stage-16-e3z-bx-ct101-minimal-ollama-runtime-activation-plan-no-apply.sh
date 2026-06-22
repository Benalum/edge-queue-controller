#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-bx-ct101-minimal-ollama-runtime-activation-plan-no-apply.md"

needles=(
  "This stage is no-apply"
  "job 37: queued"
  "job 38: queued"
  "Use only:"
  "/opt/llm-stack/docker-compose.yml"
  "service: ollama"
  "container_name: ollama"
  "Do not use:"
  "/opt/ai-platform/docker-compose.yml"
  "/opt/ai-platform/docker-compose.fresh.yml"
  "Start only the ollama service/container"
  "Verify no non-Ollama containers are running"
  "Do not call a generation endpoint yet unless separately approved"
  "Claim exact job 37 only"
  "Keep CT101 persistent worker service inactive and masked"
)

for needle in "${needles[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_BX_SMOKE_OK=1"
