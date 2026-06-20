#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-15-b-decision-maker-boundary-queue-contract-no-apply.md"

echo "=== Stage 15-B smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 15-B doc missing"
  exit 1
fi
echo "PASS: Stage 15-B doc exists"

require_text() {
  needle="$1"
  if grep -F -- "$needle" "$DOC" >/dev/null 2>&1; then
    echo "PASS: found required text: $needle"
  else
    echo "FAIL: missing required text: $needle"
    exit 1
  fi
}

require_text "The Decision Maker is a controller-side policy layer, not a model worker."
require_text "The Decision Maker must output a decision object, not a model response."
require_text "POST /api/chat/queued"
require_text "GET /api/chat/queued/{job_id}"
require_text "GET /api/chat/queue/status?job_id=..."
require_text 'Initial Stage 15 implementation should start with `companion.chat` using mock/no-model execution only.'
require_text "Still prohibited until explicit approval:"
require_text 'calling `/tick/ollama-direct`'
require_text "activating workers"
require_text "live model endpoint calls"
require_text "Use frontend product APIs as stable public contracts."

echo "PASS_STAGE_15_B_SMOKE"
