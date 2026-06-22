#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-bz-ct101-ollama-container-only-model-runtime-and-concurrency-plan-no-apply.md"

needles=(
  "This stage is no-apply"
  "PVESO host: Proxmox host only"
  "CT101 Docker: only the Ollama runtime container should run"
  "/opt/llm-stack/docker-compose.yml"
  "/mnt/ollama-models/ollama:/root/.ollama"
  "Do not delete model paths until a separate read-only model storage authority map"
  "qwen2.5:0.5b"
  "That exact model was not present"
  "qwen3:0.6b"
  "OLLAMA_MAX_LOADED_MODELS"
  "OLLAMA_NUM_PARALLEL"
  "OLLAMA_MAX_QUEUE"
  "companion_default"
  "deep_large"
  "Do not delete model files yet"
  "Do not run model generation before the requested_model mismatch is resolved"
)

for needle in "${needles[@]}"; do
  grep -Fq "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_BZ_SMOKE_OK=1"
