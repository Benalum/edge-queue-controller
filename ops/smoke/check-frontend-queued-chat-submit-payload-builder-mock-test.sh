#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit payload builder mock test smoke ==="

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

require_file docs/frontend-queued-chat-submit-payload-builder-mock-test.md
require_file docs/frontend-queued-chat-submit-payload-builder-branch.md
require_file docs/frontend-chat-submit-payload-shape-map.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-48: disabled queued-chat submit payload builder branch." "payload builder branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f48BuildQueuedChatSubmitPayload" "payload builder helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch global"
require_fixed frontend/wrapper-ui/app.js "payloadWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "missing_message_stage_5f48" "missing message result"

require_fixed docs/frontend-queued-chat-submit-payload-builder-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-payload-builder-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-payload-builder-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-submit-payload-builder-mock-test.md "Stage 5F-50 should add a disabled-by-default queued submit orchestration plan" "next stage"

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
const marker = "(function stage5f48QueuedChatSubmitPayloadBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-48 queued submit payload builder branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-48 queued submit payload builder branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const fetchCalls = [];

const context = {
  console,
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

const branch = context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH missing");
}

if (branch.payloadWired !== false) {
  throw new Error("submit payload branch should remain unwired");
}

const missing = branch.buildQueuedChatSubmitPayload({
  message: "   ",
  chat_id: "chat-missing",
  requested_model: "model-missing",
});

if (missing.ok !== false || missing.error !== "missing_message_stage_5f48") {
  throw new Error("missing message result mismatch: " + JSON.stringify(missing));
}

if (missing.payloadWired !== false) {
  throw new Error("missing message should report payloadWired false: " + JSON.stringify(missing));
}

const messageOnly = branch.buildQueuedChatSubmitPayload({
  message: "  hello world  ",
  user_id: "must-not-send",
  authenticated_user_id: "must-not-send",
  "X-Synthetic-User-Id": "must-not-send",
});

if (messageOnly.ok !== true) {
  throw new Error("message-only payload should be ok: " + JSON.stringify(messageOnly));
}

if (messageOnly.payloadWired !== false) {
  throw new Error("message-only payload should report payloadWired false: " + JSON.stringify(messageOnly));
}

if (!messageOnly.payload || messageOnly.payload.message !== "hello world") {
  throw new Error("message should be trimmed: " + JSON.stringify(messageOnly));
}

if (Object.keys(messageOnly.payload).sort().join(",") !== "message") {
  throw new Error("message-only payload should only contain message: " + JSON.stringify(messageOnly.payload));
}

const full = branch.buildQueuedChatSubmitPayload({
  message: "  queued test  ",
  chat_id: "chat-123",
  requested_model: "model-abc",
  user_id: "must-not-send",
  authenticated_user_id: "must-not-send",
  "X-Synthetic-User-Id": "must-not-send",
  extra: "must-not-send",
});

if (full.ok !== true) {
  throw new Error("full payload should be ok: " + JSON.stringify(full));
}

if (!full.payload) {
  throw new Error("full payload missing payload object: " + JSON.stringify(full));
}

if (full.payload.message !== "queued test") {
  throw new Error("full payload message mismatch: " + JSON.stringify(full));
}

if (full.payload.chat_id !== "chat-123") {
  throw new Error("full payload chat_id mismatch: " + JSON.stringify(full));
}

if (full.payload.requested_model !== "model-abc") {
  throw new Error("full payload requested_model mismatch: " + JSON.stringify(full));
}

const keys = Object.keys(full.payload).sort();

if (keys.join(",") !== "chat_id,message,requested_model") {
  throw new Error("full payload should only contain safe fields: " + JSON.stringify(full.payload));
}

if (Object.prototype.hasOwnProperty.call(full.payload, "user_id")) {
  throw new Error("payload must not contain user_id");
}

if (Object.prototype.hasOwnProperty.call(full.payload, "authenticated_user_id")) {
  throw new Error("payload must not contain authenticated_user_id");
}

if (Object.prototype.hasOwnProperty.call(full.payload, "X-Synthetic-User-Id")) {
  throw new Error("payload must not contain X-Synthetic-User-Id");
}

if (fetchCalls.length !== 0) {
  throw new Error("submit payload builder must not call fetch");
}

console.log("OK: queued submit payload builder mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat submit payload builder mock test smoke passed"
