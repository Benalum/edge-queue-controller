#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend chat submit handler insertion map static check ==="

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

require_file docs/frontend-chat-submit-handler-inspection.md
require_file docs/frontend-chat-submit-handler-insertion-map.md
require_file docs/frontend-queued-chat-submit-decision-mock-test.md
require_file docs/frontend-queued-chat-submit-decision-branch.md
require_file docs/frontend-queued-chat-first-wiring-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/dev_server.py
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-chat-submit-handler-insertion-map.md "inspection and planning only" "planning only"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "after the user submit payload is available" "future insertion point"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "before the existing non-queued assistant request is made" "before legacy assistant request"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "must not render duplicate user messages" "no duplicate user messages"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "must not create duplicate queued jobs" "no duplicate queued jobs"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH.shouldUseQueuedChatForSubmit" "future decision call"
require_fixed docs/frontend-chat-submit-handler-insertion-map.md "Stage 5F-43 should add a static submit insertion guard marker" "next stage"

require_fixed docs/frontend-chat-submit-handler-inspection.md "app.js likely submit/send/chat markers" "app inspection"
require_fixed docs/frontend-chat-submit-handler-inspection.md "app.js queued helper branch markers" "queued helper inspection"
require_fixed docs/frontend-chat-submit-handler-inspection.md "index.html chat/control/script markers" "html inspection"

require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "submit decision branch exists"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision still not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send still not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller still not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder still not wired"

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

echo "PASS: frontend chat submit handler insertion map markers are present"
