#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat status helper smoke ==="

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

require_file frontend/wrapper-ui/queued_chat_status.js
require_file docs/frontend-queued-chat-status-helper.md
require_file docs/frontend-queued-chat-polling-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html

require_fixed frontend/wrapper-ui/queued_chat_status.js "Stage 5F-27" "stage marker"
require_fixed frontend/wrapper-ui/queued_chat_status.js "queuedChatShouldPoll" "poll helper"
require_fixed frontend/wrapper-ui/queued_chat_status.js "queuedChatPollDelayMs" "delay helper"
require_fixed frontend/wrapper-ui/queued_chat_status.js "queuedChatBuildStatusView" "view helper"
require_fixed frontend/wrapper-ui/queued_chat_status.js "does not send user_id" "no user id"
require_fixed frontend/wrapper-ui/queued_chat_status.js "does not send X-Synthetic-User-Id" "no synthetic header"
require_fixed docs/frontend-queued-chat-status-helper.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-status-helper.md "The helper is intentionally unimported." "unimported helper"
require_fixed docs/frontend-queued-chat-status-helper.md "does not call CT101" "no CT101"
require_fixed docs/frontend-queued-chat-status-helper.md "Stage 5F-28 should add a guarded frontend UI smoke" "next stage"

if grep -F -n "queued_chat_status.js" frontend/wrapper-ui/app.js frontend/wrapper-ui/index.html >/dev/null 2>&1; then
  echo "FAIL: queued_chat_status.js is imported before runtime wiring stage"
  exit 1
fi

echo "OK: helper is not imported by app.js or index.html"

if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/queued_chat_status.js

  node - <<'NODE'
const helper = require("./frontend/wrapper-ui/queued_chat_status.js");

const queued = helper.queuedChatBuildStatusView({ status: "queued" }, 1000);
if (!queued.shouldPoll || queued.delayMs !== 2000 || queued.label !== "Queued") {
  throw new Error("queued status view failed: " + JSON.stringify(queued));
}

const complete = helper.queuedChatBuildStatusView(
  { status: "complete", result_json: { reply: "OK" } },
  1000
);
if (complete.shouldPoll || !complete.canRenderAssistant || complete.assistantReply !== "OK") {
  throw new Error("complete status view failed: " + JSON.stringify(complete));
}

const failed = helper.queuedChatBuildStatusView({ status: "failed" }, 1000);
if (failed.shouldPoll || !failed.terminal || failed.label !== "Failed") {
  throw new Error("failed status view failed: " + JSON.stringify(failed));
}

console.log("OK: frontend queued chat helper behavior checks passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat status helper smoke passed"
