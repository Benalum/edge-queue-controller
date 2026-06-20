#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-15-e-authenticated-mock-queued-chat-validation.md"

echo "=== Stage 15-E smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 15-E doc missing"
  exit 1
fi
echo "PASS: Stage 15-E doc exists"

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
require_text "GET /api/chat/queue/status?job_id={job_id}"
require_text "Authenticated POST /api/chat/queued returned HTTP 200."
require_text "Created mock queued job id: 24."
require_text "Created job type: companion.chat."
require_text "Created job requested model: mock/no-model."
require_text "user_sessions plus one temporary validation session."
require_text "jobs plus one mock companion.chat job."
require_text "job_results unchanged."
require_text "router_logs unchanged."
require_text "workers unchanged."
require_text "No model call occurred."
require_text "No worker activation occurred."
require_text "No scheduler activation occurred."
require_text "Model/Ollama/worker/scheduler activation still requires a separate explicit approval."

echo "PASS_STAGE_15_E_SMOKE"
