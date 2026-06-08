#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit payload builder branch smoke ==="

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

require_file docs/frontend-queued-chat-submit-payload-builder-branch.md
require_file docs/frontend-chat-submit-payload-shape-map.md
require_file docs/frontend-chat-submit-payload-shape-inspection.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-48: disabled queued-chat submit payload builder branch." "stage marker"
require_fixed frontend/wrapper-ui/app.js "stage5f48BuildQueuedChatSubmitPayload" "payload helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch global"
require_fixed frontend/wrapper-ui/app.js "payloadWired: false" "payload not wired"
require_fixed frontend/wrapper-ui/app.js "missing_message_stage_5f48" "missing message result"

require_fixed docs/frontend-queued-chat-submit-payload-builder-branch.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-payload-builder-branch.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-payload-builder-branch.md "The payload may contain only:" "safe payload shape"
require_fixed docs/frontend-queued-chat-submit-payload-builder-branch.md "Stage 5F-49 should add a mocked test" "next stage"

call_count="$( (grep -Eo 'stage5f48BuildQueuedChatSubmitPayload[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$call_count" != "1" ]; then
  echo "FAIL: expected only the stage5f48BuildQueuedChatSubmitPayload function declaration, found $call_count call-like occurrences"
  grep -nE 'stage5f48BuildQueuedChatSubmitPayload[[:space:]]*\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: stage5f48BuildQueuedChatSubmitPayload is not called by normal submit path"

if grep -E -n 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH[.]buildQueuedChatSubmitPayload[[:space:]]*\(' frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: payload builder helper should not be called yet"
  exit 1
fi

echo "OK: payload builder helper is not called"

decision_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$decision_call_count" != "0" ]; then
  echo "FAIL: submit decision helper should not be called yet"
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

echo "PASS: frontend queued chat submit payload builder branch smoke passed"
