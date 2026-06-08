#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat send helper mock test smoke ==="

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

require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file docs/frontend-queued-chat-disabled-submit-path.md
require_file docs/frontend-queued-chat-disabled-send-branch.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-32: disabled queued-chat send branch." "send branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f32SendQueuedChat" "send helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch global"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "not wired to submit"
require_fixed frontend/wrapper-ui/app.js "/api/chat/queued" "queued API route"
require_fixed frontend/wrapper-ui/app.js "credentials: \"include\"" "session credentials"

require_fixed docs/frontend-queued-chat-send-helper-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-send-helper-mock-test.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-queued-chat-send-helper-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-send-helper-mock-test.md "Stage 5F-35 should add a disabled-by-default queued status polling helper branch" "next stage"

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
const marker = "(function stage5f32QueuedChatSendBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-32 queued send branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-32 queued send branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const fetchCalls = [];

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
  fetch: async (url, options) => {
    fetchCalls.push({ url, options });
    return {
      ok: true,
      status: 200,
      json: async () => ({
        ok: true,
        job_id: "mock-job",
        status: "queued",
      }),
    };
  },
};

vm.createContext(context);
vm.runInContext(block, context);

if (!context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH missing");
}

if (context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.wiredToSubmit !== false) {
  throw new Error("queued send branch should remain unwired");
}

(async () => {
  const disabled = await context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.sendQueuedChat({
    message: "disabled test",
    chat_id: "chat-disabled",
    requested_model: "model-disabled",
  });

  if (!disabled.skipped || disabled.reason !== "queued_chat_disabled_stage_5f32") {
    throw new Error("disabled queued send result mismatch: " + JSON.stringify(disabled));
  }

  if (fetchCalls.length !== 0) {
    throw new Error("disabled queued send should not call fetch");
  }

  context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;

  const enabled = await context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.sendQueuedChat({
    message: "enabled test",
    chat_id: "chat-enabled",
    requested_model: "model-enabled",
    user_id: "must-not-send",
    authenticated_user_id: "must-not-send",
  });

  if (!enabled.ok || enabled.job_id !== "mock-job") {
    throw new Error("enabled queued send mock result mismatch: " + JSON.stringify(enabled));
  }

  if (fetchCalls.length !== 1) {
    throw new Error("enabled queued send should call fetch exactly once");
  }

  const call = fetchCalls[0];

  if (call.url !== "/api/chat/queued") {
    throw new Error("unexpected queued send URL: " + call.url);
  }

  if (!call.options || call.options.method !== "POST") {
    throw new Error("queued send should use POST");
  }

  if (call.options.credentials !== "include") {
    throw new Error("queued send should use credentials include");
  }

  const headers = call.options.headers || {};
  const headerNames = Object.keys(headers).map((x) => x.toLowerCase());

  if (headerNames.includes("x-synthetic-user-id")) {
    throw new Error("queued send should not send X-Synthetic-User-Id");
  }

  const body = JSON.parse(call.options.body);

  if (body.message !== "enabled test") {
    throw new Error("queued send body missing message");
  }

  if (body.chat_id !== "chat-enabled") {
    throw new Error("queued send body missing chat_id");
  }

  if (body.requested_model !== "model-enabled") {
    throw new Error("queued send body missing requested_model");
  }

  if (Object.prototype.hasOwnProperty.call(body, "user_id")) {
    throw new Error("queued send body must not contain user_id");
  }

  if (Object.prototype.hasOwnProperty.call(body, "authenticated_user_id")) {
    throw new Error("queued send body must not contain authenticated_user_id");
  }

  console.log("OK: queued send helper mock behavior passed");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat send helper mock test smoke passed"
