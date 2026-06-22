#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-av-ct101-docker-ollama-start-plan-no-apply.md"

needles=(
  'Ollama on CT101 should be treated as Docker-based'
  'docker.service, docker.socket, and containerd.service are masked and inactive'
  'Do not call /api/generate'
  'Do not pull images'
  'Do not run `docker compose up`'
  'Do not start or restart containers'
  'Do not write jobs or job results'
  'Do not start scheduler/timer/persistent workers'
)

for needle in "${needles[@]}"; do
  if ! grep -Fq -- "$needle" "$DOC"; then
    echo "missing_required_text=$needle"
    exit 2
  fi
done

echo "E3Z_AV_R2_SMOKE_OK=1"
