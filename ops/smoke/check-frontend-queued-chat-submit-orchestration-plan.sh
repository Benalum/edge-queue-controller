#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit orchestration plan static check ==="

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

require_file docs/frontend-queued-chat-submit-orchestration-plan.md
require_file docs/frontend-queued-chat-submit-payload-builder-mock-test.md
require_file docs/frontend-queued-chat-submit-payload-builder-branch.md
require_file docs/frontend-queued-chat-submit-dry-run-mock-test.md
require_file docs/frontend-queued-chat-submit-decision-mock-test.md
require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file docs/frontend-queued-chat-status-poll-helper-mock-test.md
require_file docs/frontend-queued-chat-assistant-placeholder-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "planning only" "planning only"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "build safe payload" "payload first"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "make submit decision" "decision second"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "call queued send once" "send once"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "render queued assistant placeholder once" "placeholder once"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "poll status once per job" "poll once"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "render final assistant reply once" "final once"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "duplicate POST /api/chat/queued calls" "duplicate POST protection"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "The queued submit payload may contain only:" "safe payload"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "The frontend must not send:" "security behavior"
require_fixed docs/frontend-queued-chat-submit-orchestration-plan.md "Stage 5F-51 should add a mocked orchestration helper branch" "next stage"

require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH" "dry-run branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "status poll branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch exists"
require_fixed frontend/wrapper-ui/app.js "payloadWired: false" "payload not wired"
require_fixed frontend/wrapper-ui/app.js "dryRunWired: false" "dry-run not wired"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder not wired"

payload_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH[.]buildQueuedChatSubmitPayload[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"
decision_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"
send_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH[.]sendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"
poll_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH[.]pollQueuedChatStatus[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"
placeholder_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH[.]buildQueuedAssistantPlaceholder[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$payload_call_count" != "0" ]; then
  echo "FAIL: payload builder should not be called from live submit"
  exit 1
fi

if [ "$decision_call_count" != "0" ]; then
  echo "FAIL: decision helper should not be called from live submit"
  exit 1
fi

if [ "$send_call_count" != "0" ]; then
  echo "FAIL: queued send helper should not be called from live submit"
  exit 1
fi

if [ "$poll_call_count" != "0" ]; then
  echo "FAIL: queued poll helper should not be called from live submit"
  exit 1
fi

if [ "$placeholder_call_count" != "0" ]; then
  echo "FAIL: queued placeholder helper should not be called from live rendering"
  exit 1
fi

echo "OK: queued orchestration helpers are not called from live paths"

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

echo "PASS: frontend queued chat submit orchestration plan markers are present"
