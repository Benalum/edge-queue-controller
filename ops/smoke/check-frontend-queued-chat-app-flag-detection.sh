#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat app flag detection smoke ==="

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_fixed() {
  local file="$1"
  local text="$2"
  local label="$3"

  if grep -F -n "$text" "$file" >/dev/null 2>&1; then
    echo "OK: $label"
  else
    echo "FAIL: missing $label"
    echo "  file: $file"
    echo "  text: $text"
    exit 1
  fi
}

require_file docs/frontend-queued-chat-app-flag-detection.md
require_file docs/frontend-queued-chat-config-flag.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-31: queued-chat frontend flag detection." "stage marker"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ENABLED === true" "reads queued flag"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_UI_STATE" "ui state marker"
require_fixed frontend/wrapper-ui/app.js "legacyChatPathActive" "legacy path marker"
require_fixed frontend/wrapper-ui/app.js "queuedSendWired: false" "queued send not wired"
require_fixed docs/frontend-queued-chat-app-flag-detection.md "This stage does not wire queued chat send behavior." "no send wiring"
require_fixed docs/frontend-queued-chat-app-flag-detection.md "The current non-queued chat path remains active." "legacy active"
require_fixed docs/frontend-queued-chat-app-flag-detection.md "Stage 5F-32 should add a disabled-by-default app.js queued-send branch" "next stage"

if grep -F -n "/api/chat/queued" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not call /api/chat/queued yet"
  exit 1
fi

echo "OK: app.js does not call /api/chat/queued"

if grep -F -n "QueuedChatStatusHelper" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not use QueuedChatStatusHelper yet"
  exit 1
fi

echo "OK: app.js does not use QueuedChatStatusHelper yet"

if grep -F -n "user_id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not send/read user_id for queued chat"
  exit 1
fi

echo "OK: app.js does not reference user_id"

if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/queued_chat_config.js
  node --check frontend/wrapper-ui/queued_chat_status.js
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat app flag detection smoke passed"
