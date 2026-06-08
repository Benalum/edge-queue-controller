#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit dry-run mock test smoke ==="

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

require_file docs/frontend-queued-chat-submit-dry-run-mock-test.md
require_file docs/frontend-queued-chat-submit-dry-run-branch.md
require_file docs/frontend-chat-submit-marker-proximity.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-45: disabled queued-chat submit dry-run branch." "dry-run branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f45BuildQueuedChatSubmitDryRun" "dry-run helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH" "dry-run branch global"
require_fixed frontend/wrapper-ui/app.js "dryRunWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "queued_submit_dry_run_flag_disabled_stage_5f45" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "queued_submit_dry_run_unwired_stage_5f45" "enabled unwired result"

require_fixed docs/frontend-queued-chat-submit-dry-run-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-dry-run-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-dry-run-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-submit-dry-run-mock-test.md "Stage 5F-47 should inspect the real submit handler payload shape" "next stage"

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
const marker = "(function stage5f45QueuedChatSubmitDryRunBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-45 queued submit dry-run branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-45 queued submit dry-run branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const fetchCalls = [];

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
  AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH: {
    decisionWired: false,
  },
  AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH: {
    wiredToSubmit: false,
  },
  AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH: {
    pollerWired: false,
  },
  AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH: {
    placeholderWired: false,
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

const branch = context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH missing");
}

if (branch.dryRunWired !== false) {
  throw new Error("submit dry-run branch should remain unwired");
}

const disabled = branch.buildQueuedChatSubmitDryRun({
  message: "disabled message",
  chat_id: "chat-disabled",
  requested_model: "model-disabled",
  unsafeIdentityField: "must-not-matter",
});

if (disabled.reason !== "queued_submit_dry_run_flag_disabled_stage_5f45") {
  throw new Error("disabled dry-run reason mismatch: " + JSON.stringify(disabled));
}

if (disabled.wouldUseQueuedChat !== false) {
  throw new Error("disabled dry-run should not use queued chat: " + JSON.stringify(disabled));
}

if (disabled.legacyChatPathActive !== true) {
  throw new Error("disabled dry-run should keep legacy path active: " + JSON.stringify(disabled));
}

if (disabled.dryRunWired !== false) {
  throw new Error("disabled dry-run should report dryRunWired false: " + JSON.stringify(disabled));
}

if (!disabled.decisionBranchPresent || !disabled.sendBranchPresent || !disabled.pollBranchPresent || !disabled.placeholderBranchPresent) {
  throw new Error("disabled dry-run should report helper branches present: " + JSON.stringify(disabled));
}

if (disabled.decisionWired || disabled.sendWired || disabled.pollerWired || disabled.placeholderWired) {
  throw new Error("disabled dry-run should report helper branches unwired: " + JSON.stringify(disabled));
}

if (!disabled.payload || disabled.payload.message !== "disabled message") {
  throw new Error("disabled dry-run payload missing message: " + JSON.stringify(disabled));
}

if (disabled.payload.chat_id !== "chat-disabled") {
  throw new Error("disabled dry-run payload missing chat_id: " + JSON.stringify(disabled));
}

if (disabled.payload.requested_model !== "model-disabled") {
  throw new Error("disabled dry-run payload missing requested_model: " + JSON.stringify(disabled));
}

if (Object.keys(disabled.payload).sort().join(",") !== "chat_id,message,requested_model") {
  throw new Error("disabled dry-run payload should only contain safe fields: " + JSON.stringify(disabled.payload));
}

context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = {
  decisionWired: true,
};
context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {
  wiredToSubmit: true,
};
context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = {
  pollerWired: true,
};
context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = {
  placeholderWired: true,
};

const enabled = branch.buildQueuedChatSubmitDryRun({
  message: "enabled message",
  chat_id: "chat-enabled",
  requested_model: "model-enabled",
  unsafeIdentityField: "must-not-matter",
});

if (enabled.reason !== "queued_submit_dry_run_unwired_stage_5f45") {
  throw new Error("enabled dry-run reason mismatch: " + JSON.stringify(enabled));
}

if (enabled.wouldUseQueuedChat !== false) {
  throw new Error("enabled dry-run should still not use queued chat while dryRunWired=false: " + JSON.stringify(enabled));
}

if (enabled.legacyChatPathActive !== true) {
  throw new Error("enabled dry-run should keep legacy path active: " + JSON.stringify(enabled));
}

if (enabled.dryRunWired !== false) {
  throw new Error("enabled dry-run should report dryRunWired false: " + JSON.stringify(enabled));
}

if (!enabled.decisionWired || !enabled.sendWired || !enabled.pollerWired || !enabled.placeholderWired) {
  throw new Error("enabled dry-run should report mocked helper branches wired: " + JSON.stringify(enabled));
}

if (Object.keys(enabled.payload).sort().join(",") !== "chat_id,message,requested_model") {
  throw new Error("enabled dry-run payload should only contain safe fields: " + JSON.stringify(enabled.payload));
}

if (enabled.payload.message !== "enabled message") {
  throw new Error("enabled dry-run payload missing message: " + JSON.stringify(enabled));
}

if (fetchCalls.length !== 0) {
  throw new Error("submit dry-run helper must not call fetch");
}

console.log("OK: queued submit dry-run helper mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat submit dry-run mock test smoke passed"
