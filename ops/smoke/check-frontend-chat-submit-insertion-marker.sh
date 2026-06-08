#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend chat submit insertion marker smoke ==="

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

require_file docs/frontend-chat-submit-insertion-marker.md
require_file docs/frontend-chat-submit-handler-insertion-map.md
require_file docs/frontend-chat-submit-handler-inspection.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-43: queued-chat submit insertion guard marker." "stage marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-43 is marker-only." "marker only"
require_fixed frontend/wrapper-ui/app.js "It does not call the decision helper." "no decision call in marker"
require_fixed frontend/wrapper-ui/app.js "It does not call the queued send helper." "no send call in marker"
require_fixed frontend/wrapper-ui/app.js "It does not change submit behavior." "no submit behavior change"

require_fixed docs/frontend-chat-submit-insertion-marker.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-chat-submit-insertion-marker.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-chat-submit-insertion-marker.md "The marker is comment-only." "comment only"
require_fixed docs/frontend-chat-submit-insertion-marker.md "Stage 5F-44 should add a static smoke" "next stage"

require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision still not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send still not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller still not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder still not wired"

call_count="$((grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ')"

if [ "$call_count" != "0" ]; then
  echo "FAIL: submit decision helper should not be called in Stage 5F-43"
  grep -nE 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: submit decision helper is not called"

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

echo "PASS: frontend chat submit insertion marker smoke passed"
