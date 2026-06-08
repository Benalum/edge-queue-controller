#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat helper import smoke ==="

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

require_file docs/frontend-queued-chat-helper-import.md
require_file docs/frontend-queued-chat-status-helper.md
require_file docs/frontend-queued-chat-ui-wiring-map.md
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-helper-import.md "does not wire queued chat send behavior" "no queued send wiring"
require_fixed docs/frontend-queued-chat-helper-import.md "does not enable queued chat by default" "disabled by default"
require_fixed docs/frontend-queued-chat-helper-import.md "app.js still does not POST to /api/chat/queued" "no POST from app"
require_fixed docs/frontend-queued-chat-helper-import.md "window.AI_PLATFORM_QUEUED_CHAT_ENABLED === true" "future flag"
require_fixed docs/frontend-queued-chat-helper-import.md "Stage 5F-30 should add a disabled-by-default frontend queued-chat config flag" "next stage"

require_fixed frontend/wrapper-ui/index.html "queued_chat_status.js" "index imports helper"
require_fixed frontend/wrapper-ui/queued_chat_status.js "QueuedChatStatusHelper" "helper global"

if grep -F -n "queued_chat_status.js" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not import queued_chat_status.js yet"
  exit 1
fi

echo "OK: app.js does not import queued_chat_status.js"

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

if grep -F -n "Stage 5F-32: disabled queued-chat send branch." frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  require_fixed frontend/wrapper-ui/app.js "/api/chat/queued" "queued route present after Stage 5F-32"
  require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "queued send branch not wired"
else
  if grep -F -n "/api/chat/queued" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
    echo "FAIL: app.js should not POST/poll queued chat route yet"
    exit 1
  fi
  echo "OK: app.js does not call /api/chat/queued"
fi

if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/queued_chat_status.js

  node - <<'NODE'
const helper = require("./frontend/wrapper-ui/queued_chat_status.js");

const view = helper.queuedChatBuildStatusView(
  { status: "complete", result_json: { reply: "OK" } },
  1000
);

if (!view.canRenderAssistant || view.assistantReply !== "OK") {
  throw new Error("helper import behavior failed: " + JSON.stringify(view));
}

console.log("OK: queued chat helper remains valid after import stage");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat helper import smoke passed"
