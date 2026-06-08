#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit decision mock test smoke ==="

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

require_file docs/frontend-queued-chat-submit-decision-mock-test.md
require_file docs/frontend-queued-chat-submit-decision-branch.md
require_file docs/frontend-queued-chat-first-wiring-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-40: disabled queued-chat submit decision branch." "decision branch marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-41: decisionWired remains the authoritative guard." "decisionWired guard marker"
require_fixed frontend/wrapper-ui/app.js "stage5f40ShouldUseQueuedChatForSubmit" "decision helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch global"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "queued_chat_flag_disabled_stage_5f40" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "queued_chat_decision_not_wired_stage_5f41" "decision not wired result"
require_fixed frontend/wrapper-ui/app.js "queued_chat_submit_not_wired_stage_5f40" "send branch not wired result"

require_fixed docs/frontend-queued-chat-submit-decision-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-decision-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-decision-mock-test.md "decisionWired false is authoritative" "authoritative decision guard"
require_fixed docs/frontend-queued-chat-submit-decision-mock-test.md "Stage 5F-42 should inspect the real chat submit handler" "next stage"

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

const source = fs.readFileSync("frontend/wrapper-ui/app.js", "utf8");
const marker = "(function stage5f40QueuedChatSubmitDecisionBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-40 queued submit decision branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-40 queued submit decision branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const fetchCalls = [];

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
  AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH: {
    wiredToSubmit: false,
  },
  fetch: async (url, options) => {
    fetchCalls.push({ url, options });
    return {
      ok: true,
      status: 200,
      json: async () => ({ ok: true }),
    };
  },
};

vm.createContext(context);
vm.runInContext(block, context);

const branch = context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH missing");
}

if (branch.decisionWired !== false) {
  throw new Error("submit decision branch should remain unwired");
}

const disabled = branch.shouldUseQueuedChatForSubmit({
  message: "disabled",
  chat_id: "chat-disabled",
  requested_model: "model-disabled",
});

if (disabled.shouldUseQueuedChat !== false) {
  throw new Error("disabled flag should not select queued chat: " + JSON.stringify(disabled));
}

if (disabled.reason !== "queued_chat_flag_disabled_stage_5f40") {
  throw new Error("disabled reason mismatch: " + JSON.stringify(disabled));
}

if (disabled.legacyChatPathActive !== true) {
  throw new Error("disabled flag should keep legacy path active: " + JSON.stringify(disabled));
}

context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;
context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {
  wiredToSubmit: false,
};

const enabledUnwired = branch.shouldUseQueuedChatForSubmit({
  message: "enabled unwired",
  chat_id: "chat-enabled",
  requested_model: "model-enabled",
});

if (enabledUnwired.shouldUseQueuedChat !== false) {
  throw new Error("enabled but decision unwired should not select queued chat: " + JSON.stringify(enabledUnwired));
}

if (enabledUnwired.reason !== "queued_chat_decision_not_wired_stage_5f41") {
  throw new Error("enabled unwired reason mismatch: " + JSON.stringify(enabledUnwired));
}

if (enabledUnwired.legacyChatPathActive !== true) {
  throw new Error("enabled unwired should keep legacy path active: " + JSON.stringify(enabledUnwired));
}

context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {
  wiredToSubmit: true,
};

const mockedSendBranchWired = branch.shouldUseQueuedChatForSubmit({
  message: "mocked wired send branch",
  chat_id: "chat-wired",
  requested_model: "model-wired",
});

if (mockedSendBranchWired.shouldUseQueuedChat !== false) {
  throw new Error(
    "decisionWired=false must prevent queued selection even when send branch is mocked wired: "
      + JSON.stringify(mockedSendBranchWired)
  );
}

if (mockedSendBranchWired.reason !== "queued_chat_decision_not_wired_stage_5f41") {
  throw new Error("mocked wired branch reason mismatch: " + JSON.stringify(mockedSendBranchWired));
}

if (mockedSendBranchWired.decisionWired !== false) {
  throw new Error("decisionWired should remain false: " + JSON.stringify(mockedSendBranchWired));
}

if (fetchCalls.length !== 0) {
  throw new Error("submit decision helper must not call fetch");
}

console.log("OK: queued submit decision helper mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat submit decision mock test smoke passed"
