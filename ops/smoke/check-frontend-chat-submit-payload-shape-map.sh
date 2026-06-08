#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend chat submit payload shape map static check ==="

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

require_file docs/frontend-chat-submit-payload-shape-inspection.md
require_file docs/frontend-chat-submit-payload-shape-map.md
require_file docs/frontend-chat-submit-marker-proximity.md
require_file docs/frontend-chat-submit-insertion-marker.md
require_file docs/frontend-chat-submit-handler-insertion-map.md
require_file docs/frontend-queued-chat-submit-dry-run-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-chat-submit-payload-shape-map.md "inspection and planning only" "planning only"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "message" "message field"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "chat_id" "chat id field"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "requested_model" "requested model field"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "The frontend must not include any other user identity field." "no identity payload"
require_fixed docs/frontend-chat-submit-payload-shape-map.md "Stage 5F-48 should add a disabled-by-default payload builder helper branch" "next stage"

require_fixed docs/frontend-chat-submit-payload-shape-inspection.md "Stage 5F queued submit helper markers" "queued marker inspection"
require_fixed docs/frontend-chat-submit-payload-shape-inspection.md "Likely payload/model/chat/message markers in app.js" "payload marker inspection"
require_fixed docs/frontend-chat-submit-payload-shape-inspection.md "Lines around Stage 5F-43 submit insertion marker" "submit marker context"

require_fixed frontend/wrapper-ui/app.js "Stage 5F-43: queued-chat submit insertion guard marker." "submit insertion marker"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH" "dry-run branch exists"
require_fixed frontend/wrapper-ui/app.js "dryRunWired: false" "dry-run not wired"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder not wired"

dry_run_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH[.]buildQueuedChatSubmitDryRun[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$dry_run_call_count" != "0" ]; then
  echo "FAIL: dry-run helper should not be called from live submit"
  exit 1
fi

echo "OK: dry-run helper is not called from live submit"

decision_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$decision_call_count" != "0" ]; then
  echo "FAIL: decision helper should not be called from live submit"
  exit 1
fi

echo "OK: decision helper is not called from live submit"

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

echo "PASS: frontend chat submit payload shape map markers are present"
