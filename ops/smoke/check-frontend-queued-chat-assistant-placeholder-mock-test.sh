#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat assistant placeholder mock test smoke ==="

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

require_file docs/frontend-queued-chat-assistant-placeholder-mock-test.md
require_file docs/frontend-queued-chat-assistant-placeholder-branch.md
require_file docs/frontend-queued-chat-status-poll-helper-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-37: disabled queued-chat assistant placeholder branch." "placeholder branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f37BuildQueuedAssistantPlaceholder" "placeholder helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch global"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "queued_placeholder_disabled_stage_5f37" "disabled result"
require_fixed frontend/wrapper-ui/app.js "queued_placeholder_helper_missing_stage_5f37" "missing helper result"
require_fixed frontend/wrapper-ui/app.js "QueuedChatStatusHelper" "status helper"

require_fixed docs/frontend-queued-chat-assistant-placeholder-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-assistant-placeholder-mock-test.md "does not wire placeholders into message rendering" "no render wiring"
require_fixed docs/frontend-queued-chat-assistant-placeholder-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-assistant-placeholder-mock-test.md "Stage 5F-39 should add a queued-chat frontend integration plan" "next stage"

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

  node - <<'NODE'
const fs = require("fs");
const vm = require("vm");
const statusHelper = require("./frontend/wrapper-ui/queued_chat_status.js");

const source = fs.readFileSync("frontend/wrapper-ui/app.js", "utf8");
const marker = "(function stage5f37QueuedChatAssistantPlaceholderBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-37 queued assistant placeholder branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-37 queued assistant placeholder branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
  QueuedChatStatusHelper: statusHelper,
};

vm.createContext(context);
vm.runInContext(block, context);

const branch = context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH missing");
}

if (branch.placeholderWired !== false) {
  throw new Error("queued assistant placeholder branch should remain unwired");
}

const disabled = branch.buildQueuedAssistantPlaceholder(
  { status: "queued" },
  { elapsedMs: 1000 }
);

if (!disabled.skipped || disabled.reason !== "queued_placeholder_disabled_stage_5f37") {
  throw new Error("disabled placeholder result mismatch: " + JSON.stringify(disabled));
}

context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;

const queued = branch.buildQueuedAssistantPlaceholder(
  { status: "queued" },
  { elapsedMs: 1000 }
);

if (!queued.ok || queued.canRenderAssistant !== false) {
  throw new Error("queued placeholder result mismatch: " + JSON.stringify(queued));
}

if (!String(queued.placeholderText || "").includes("Queued")) {
  throw new Error("queued placeholder text mismatch: " + JSON.stringify(queued));
}

const running = branch.buildQueuedAssistantPlaceholder(
  { status: "running" },
  { elapsedMs: 1000 }
);

if (!running.ok || !String(running.placeholderText || "").includes("generating")) {
  throw new Error("running placeholder result mismatch: " + JSON.stringify(running));
}

const failed = branch.buildQueuedAssistantPlaceholder(
  { status: "failed" },
  { elapsedMs: 1000 }
);

if (!failed.ok || !String(failed.placeholderText || "").includes("failed")) {
  throw new Error("failed placeholder result mismatch: " + JSON.stringify(failed));
}

const complete = branch.buildQueuedAssistantPlaceholder(
  {
    status: "complete",
    result_json: {
      reply: "OK",
    },
  },
  { elapsedMs: 1000 }
);

if (!complete.ok || complete.canRenderAssistant !== true || complete.assistantReply !== "OK") {
  throw new Error("complete placeholder result mismatch: " + JSON.stringify(complete));
}

const missingHelperContext = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: true,
};

vm.createContext(missingHelperContext);
vm.runInContext(block, missingHelperContext);

const missing = missingHelperContext.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH
  .buildQueuedAssistantPlaceholder({ status: "queued" }, { elapsedMs: 1000 });

if (missing.error !== "queued_placeholder_helper_missing_stage_5f37") {
  throw new Error("missing helper result mismatch: " + JSON.stringify(missing));
}

console.log("OK: queued assistant placeholder helper mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat assistant placeholder mock test smoke passed"
