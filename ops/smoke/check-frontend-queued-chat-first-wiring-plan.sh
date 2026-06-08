#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat first wiring plan static check ==="

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

require_file docs/frontend-queued-chat-first-wiring-plan.md
require_file docs/frontend-queued-chat-assistant-placeholder-mock-test.md
require_file docs/frontend-queued-chat-status-poll-helper-mock-test.md
require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-first-wiring-plan.md "planning only" "planning only"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "does not enable queued chat by default" "default disabled"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "preserve the current existing chat submit path" "legacy path preserved"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "window.AI_PLATFORM_QUEUED_CHAT_ENABLED === true" "flag gate"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "Rollback must be instant" "rollback behavior"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "duplicate POST /api/chat/queued calls" "duplicate protection"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "The frontend must not send:" "security behavior"
require_fixed docs/frontend-queued-chat-first-wiring-plan.md "Stage 5F-40 should add a disabled-by-default submit decision helper" "next stage"

require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send helper branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "status poll branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch exists"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send branch not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poll branch not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder branch not wired"

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

echo "PASS: frontend queued chat first wiring plan markers are present"
