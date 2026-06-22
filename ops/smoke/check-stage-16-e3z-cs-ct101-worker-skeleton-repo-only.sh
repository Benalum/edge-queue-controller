#!/usr/bin/env bash
set -euo pipefail

WORKER="ops/workers/ct101_minimal_ollama_worker.py"
README="ops/workers/README-ct101-minimal-ollama-worker.md"
SERVICE="ops/systemd/ct101/edge-ct101-ollama-worker.service.example"
DOC="docs/stage-16-e3z-cs-ct101-worker-skeleton-repo-only.md"
PROFILE="ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml"

for f in "$WORKER" "$README" "$SERVICE" "$DOC" "$PROFILE"; do
  [ -f "$f" ] || { echo "MISSING_FILE=$f"; exit 1; }
done

python3 -m py_compile "$WORKER"
python3 "$WORKER" --self-test --profile-file "$PROFILE"

needles_worker=(
  "REFUSE_WORKER_DISABLED"
  "REFUSE_MODEL_OUTPUT_NOT_EXACT"
  "REFUSE_QWEN3_BAD_THINK_SYNTAX"
  "def build_ollama_command"
  "def claim_one_job"
  "def complete_job"
  "--think=false"
  "--hidethinking"
  "--think false"
)

for needle in "${needles_worker[@]}"; do
  grep -Fq -- "$needle" "$WORKER" || { echo "MISSING_WORKER_NEEDLE=$needle"; exit 1; }
done

needles_doc=(
  "This stage is repo-only"
  "ops/workers/ct101_minimal_ollama_worker.py"
  "edge-ct101-ollama-worker.service.example"
  "Do not rerun jobs 37 through 44"
  "Do not call models"
  "Do not connect to live CT203 API"
  "Do not connect to live CT101"
  "Do not activate scheduler or timer"
  "Do not change CT203 claim endpoint behavior in this stage"
  "Do not create runtime files under"
)

for needle in "${needles_doc[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_DOC_NEEDLE=$needle"; exit 1; }
done

grep -Fq "Example only" "$SERVICE" || { echo "SERVICE_NOT_MARKED_EXAMPLE_ONLY=1"; exit 1; }
grep -Fq "Restart=no" "$SERVICE" || { echo "SERVICE_RESTART_NOT_NO=1"; exit 1; }

echo "E3Z_CS_SMOKE_OK=1"
