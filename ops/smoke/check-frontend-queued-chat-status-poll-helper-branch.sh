#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat status poll helper branch smoke ==="

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

require_file docs/frontend-queued-chat-status-poll-helper-branch.md
require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-35: disabled queued-chat status polling branch." "stage marker"
require_fixed frontend/wrapper-ui/app.js "stage5f35PollQueuedChatStatus" "poll helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "poll branch global"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller not wired"
require_fixed frontend/wrapper-ui/app.js "queued_status_poll_disabled_stage_5f35" "disabled result"
require_fixed frontend/wrapper-ui/app.js "QueuedChatStatusHelper" "status helper usage"
require_fixed frontend/wrapper-ui/app.js "/api/chat/queued/" "queued status route"
require_fixed frontend/wrapper-ui/app.js "credentials: \"include\"" "session credentials"

require_fixed docs/frontend-queued-chat-status-poll-helper-branch.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-status-poll-helper-branch.md "does not wire polling into submit" "no submit wiring"
require_fixed docs/frontend-queued-chat-status-poll-helper-branch.md "Stage 5F-36 should add a mocked test" "next stage"

call_count="$(grep -Eo 'stage5f35PollQueuedChatStatus[[:space:]]*\\(' frontend/wrapper-ui/app.js | wc -l | tr -d ' ')"

if [ "$call_count" != "1" ]; then
  echo "FAIL: expected only the stage5f35PollQueuedChatStatus function declaration, found $call_count call-like occurrences"
  grep -nE 'stage5f35PollQueuedChatStatus[[:space:]]*\\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: stage5f35PollQueuedChatStatus is not called by normal submit path"

if grep -E -n 'AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH[.]pollQueuedChatStatus[[:space:]]*\\(' frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH.pollQueuedChatStatus should not be called yet"
  exit 1
fi

echo "OK: pollQueuedChatStatus is not called"

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

echo "PASS: frontend queued chat status poll helper branch smoke passed"
