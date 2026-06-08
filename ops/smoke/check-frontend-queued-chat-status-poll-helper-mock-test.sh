#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat status poll helper mock test smoke ==="

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

require_file docs/frontend-queued-chat-status-poll-helper-mock-test.md
require_file docs/frontend-queued-chat-status-poll-helper-branch.md
require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-35: disabled queued-chat status polling branch." "poll branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f35PollQueuedChatStatus" "poll helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "poll branch global"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "queued_status_poll_disabled_stage_5f35" "disabled result"
require_fixed frontend/wrapper-ui/app.js "QueuedChatStatusHelper" "status helper"
require_fixed frontend/wrapper-ui/app.js "/api/chat/queued/" "queued status route"
require_fixed frontend/wrapper-ui/app.js "credentials: \"include\"" "session credentials"

require_fixed docs/frontend-queued-chat-status-poll-helper-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-status-poll-helper-mock-test.md "does not wire polling into submit" "no submit wiring"
require_fixed docs/frontend-queued-chat-status-poll-helper-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-status-poll-helper-mock-test.md "Stage 5F-37 should add a disabled-by-default queued assistant placeholder helper branch" "next stage"

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
const marker = "(function stage5f35QueuedChatStatusPollBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-35 queued status poll branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-35 queued status poll branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const fetchCalls = [];

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
  QueuedChatStatusHelper: statusHelper,
  fetch: async (url, options) => {
    fetchCalls.push({ url, options });
    return {
      ok: true,
      status: 200,
      json: async () => ({
        ok: true,
        stage: "5f36-mock",
        job: {
          id: "mock-job",
          job_id: "mock-job",
          status: "complete",
          result_json: {
            reply: "OK",
          },
        },
      }),
    };
  },
  encodeURIComponent,
};

vm.createContext(context);
vm.runInContext(block, context);

if (!context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH missing");
}

if (context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH.pollerWired !== false) {
  throw new Error("queued status poll branch should remain unwired");
}

(async () => {
  const disabled = await context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH.pollQueuedChatStatus(
    "job-disabled",
    { elapsedMs: 1000 }
  );

  if (!disabled.skipped || disabled.reason !== "queued_status_poll_disabled_stage_5f35") {
    throw new Error("disabled queued status result mismatch: " + JSON.stringify(disabled));
  }

  if (fetchCalls.length !== 0) {
    throw new Error("disabled queued status poll should not call fetch");
  }

  context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;

  const missing = await context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH.pollQueuedChatStatus(
    "",
    { elapsedMs: 1000 }
  );

  if (missing.error !== "missing_job_id_stage_5f35") {
    throw new Error("missing job id result mismatch: " + JSON.stringify(missing));
  }

  if (fetchCalls.length !== 0) {
    throw new Error("missing job id should not call fetch");
  }

  const enabled = await context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH.pollQueuedChatStatus(
    "mock job/with space",
    { elapsedMs: 1000 }
  );

  if (!enabled.ok || enabled.stage !== "5f35") {
    throw new Error("enabled queued status result mismatch: " + JSON.stringify(enabled));
  }

  if (!enabled.view || enabled.view.status !== "complete" || enabled.view.assistantReply !== "OK") {
    throw new Error("enabled queued status view mismatch: " + JSON.stringify(enabled));
  }

  if (fetchCalls.length !== 1) {
    throw new Error("enabled queued status should call fetch exactly once");
  }

  const call = fetchCalls[0];

  if (call.url !== "/api/chat/queued/mock%20job%2Fwith%20space") {
    throw new Error("unexpected queued status URL: " + call.url);
  }

  if (!call.options || call.options.method !== "GET") {
    throw new Error("queued status should use GET");
  }

  if (call.options.credentials !== "include") {
    throw new Error("queued status should use credentials include");
  }

  if (Object.prototype.hasOwnProperty.call(call.options, "body")) {
    throw new Error("queued status GET should not send a body");
  }

  const headers = call.options.headers || {};
  const headerNames = Object.keys(headers).map((x) => x.toLowerCase());

  if (headerNames.includes("x-synthetic-user-id")) {
    throw new Error("queued status should not send X-Synthetic-User-Id");
  }

  if (headerNames.includes("user_id")) {
    throw new Error("queued status should not send user_id header");
  }

  if (headerNames.includes("authenticated_user_id")) {
    throw new Error("queued status should not send authenticated_user_id header");
  }

  console.log("OK: queued status poll helper mock behavior passed");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat status poll helper mock test smoke passed"
