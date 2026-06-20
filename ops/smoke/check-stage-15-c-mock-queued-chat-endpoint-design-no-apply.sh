#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-15-c-mock-queued-chat-endpoint-design-no-apply.md"

echo "=== Stage 15-C smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 15-C doc missing"
  exit 1
fi
echo "PASS: Stage 15-C doc exists"

require_text() {
  needle="$1"
  if grep -F -- "$needle" "$DOC" >/dev/null 2>&1; then
    echo "PASS: found required text: $needle"
  else
    echo "FAIL: missing required text: $needle"
    exit 1
  fi
}

require_text "POST /api/chat/queued"
require_text "GET /api/chat/queued/{job_id}"
require_text "GET /api/chat/queue/status"
require_text "mock/no-model only"
require_text "The Decision Maker remains a controller-side policy layer, not a model worker."
require_text "Do not run Stage 15-D without explicit approval."
require_text "APPROVE_STAGE_15_D_MOCK_QUEUED_CHAT_COMPATIBILITY_APPLY_NO_MODEL_NO_WORKER_NO_SCHEDULER"
require_text "calling /tick/ollama-direct"
require_text "worker activation"
require_text "scheduler activation"
require_text "no model call"
require_text "no Ollama call"

echo "PASS_STAGE_15_C_SMOKE"
