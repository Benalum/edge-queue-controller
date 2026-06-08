#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat disabled submit path smoke ==="

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

require_file docs/frontend-queued-chat-disabled-submit-path.md
require_file docs/frontend-queued-chat-disabled-send-branch.md
require_file docs/frontend-queued-chat-app-flag-detection.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-32: disabled queued-chat send branch." "send branch stage marker"
require_fixed frontend/wrapper-ui/app.js "stage5f32SendQueuedChat" "send helper exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ENABLED === true" "flag gate"
require_fixed frontend/wrapper-ui/app.js "queued_chat_disabled_stage_5f32" "disabled branch result"
require_fixed frontend/wrapper-ui/app.js "/api/chat/queued" "queued route present"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "not wired to submit"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch global"

require_fixed docs/frontend-queued-chat-disabled-submit-path.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-disabled-submit-path.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-queued-chat-disabled-submit-path.md "Stage 5F-34 should add a guarded frontend queued-send unit/static test" "next stage"

# Function declaration should be the only stage5f32SendQueuedChat(...) occurrence.
call_count="$(grep -Eo 'stage5f32SendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js | wc -l | tr -d ' ')"

if [ "$call_count" != "1" ]; then
  echo "FAIL: expected only the stage5f32SendQueuedChat function declaration, found $call_count call-like occurrences"
  grep -nE 'stage5f32SendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: stage5f32SendQueuedChat is not called by normal submit path"

if grep -E -n 'AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH[.]sendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.sendQueuedChat should not be called yet"
  grep -E -n 'AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH[.]sendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.sendQueuedChat is not called"

if grep -E -n '[^A-Za-z0-9_]sendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: direct sendQueuedChat(...) call found"
  grep -E -n '[^A-Za-z0-9_]sendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: direct sendQueuedChat(...) is not called"

if grep -F -n "Stage 5F-35: disabled queued-chat status polling branch." frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  require_fixed frontend/wrapper-ui/app.js "QueuedChatStatusHelper" "status helper available after Stage 5F-35"
  require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "status poller not wired"
else
  if grep -F -n "QueuedChatStatusHelper" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
    echo "FAIL: app.js should not use QueuedChatStatusHelper before Stage 5F-35"
    exit 1
  fi
  echo "OK: app.js does not use QueuedChatStatusHelper yet"
fi

if grep -F -n "user_id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not reference user_id"
  exit 1
fi

echo "OK: app.js does not reference user_id"

if grep -F -n "authenticated_user_id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not reference authenticated_user_id"
  exit 1
fi

echo "OK: app.js does not reference authenticated_user_id"

if grep -F -n "X-Synthetic-User-Id" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not send X-Synthetic-User-Id"
  exit 1
fi

echo "OK: app.js does not send X-Synthetic-User-Id"

if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/queued_chat_config.js
  node --check frontend/wrapper-ui/queued_chat_status.js
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat disabled submit path smoke passed"
