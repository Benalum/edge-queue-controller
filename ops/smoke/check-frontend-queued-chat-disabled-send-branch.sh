#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat disabled send branch smoke ==="

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

require_file docs/frontend-queued-chat-disabled-send-branch.md
require_file docs/frontend-queued-chat-app-flag-detection.md
require_file docs/frontend-queued-chat-config-flag.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-32: disabled queued-chat send branch." "stage marker"
require_fixed frontend/wrapper-ui/app.js "stage5f32SendQueuedChat" "send helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ENABLED === true" "flag gate"
require_fixed frontend/wrapper-ui/app.js "queued_chat_disabled_stage_5f32" "disabled result"
require_fixed frontend/wrapper-ui/app.js "/api/chat/queued" "queued route"
require_fixed frontend/wrapper-ui/app.js "credentials: \"include\"" "session credentials"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "not wired to submit"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch global"

require_fixed docs/frontend-queued-chat-disabled-send-branch.md "does not wire the branch into the current chat submit flow" "no submit wiring"
require_fixed docs/frontend-queued-chat-disabled-send-branch.md "Queued chat UI remains disabled by default." "default disabled"
require_fixed docs/frontend-queued-chat-disabled-send-branch.md "Stage 5F-33 should add a disabled-by-default frontend smoke" "next stage"

if grep -F -n "QueuedChatStatusHelper" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not use QueuedChatStatusHelper in Stage 5F-32"
  exit 1
fi

echo "OK: app.js does not use QueuedChatStatusHelper"

if grep -F -n "user_id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not send/read user_id"
  exit 1
fi

echo "OK: app.js does not reference user_id"

if grep -F -n "authenticated_user_id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not send/read authenticated_user_id"
  exit 1
fi

echo "OK: app.js does not reference authenticated_user_id"

if grep -F -n "X-Synthetic-User-Id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not send X-Synthetic-User-Id"
  exit 1
fi

echo "OK: app.js does not send synthetic-user header"

if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/queued_chat_config.js
  node --check frontend/wrapper-ui/queued_chat_status.js
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat disabled send branch smoke passed"
