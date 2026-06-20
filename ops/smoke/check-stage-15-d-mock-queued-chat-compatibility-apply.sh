#!/usr/bin/env bash
set -euo pipefail
set +H

SRC="edge_controller.py"

echo "=== Stage 15-D smoke ==="

if [ ! -f "$SRC" ]; then
  echo "FAIL: edge_controller.py missing"
  exit 1
fi

require_text() {
  needle="$1"
  if grep -F -- "$needle" "$SRC" >/dev/null 2>&1; then
    echo "PASS: found required source text: $needle"
  else
    echo "FAIL: missing required source text: $needle"
    exit 1
  fi
}

require_text "STAGE_15_D_MOCK_QUEUED_CHAT_COMPAT_BEGIN"
require_text '@app.post("/api/chat/queued")'
require_text '@app.get("/api/chat/queued/{job_id}")'
require_text '@app.get("/api/chat/queue/status")'
require_text '_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"'
require_text '"no_model_call"'
require_text '"no_worker_activation"'
require_text '"no_scheduler_activation"'
require_text 'INSERT INTO jobs'
require_text 'job_type = ?'

python3 -m py_compile "$SRC"

echo "PASS_STAGE_15_D_SMOKE"
