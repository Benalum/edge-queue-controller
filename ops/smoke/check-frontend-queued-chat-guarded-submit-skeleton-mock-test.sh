#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat guarded submit skeleton mock test smoke ==="

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

require_file docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton.md
require_file docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md
require_file docs/frontend-queued-chat-flag-on-submit-wiring-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-57: disabled guarded queued submit skeleton branch." "skeleton branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f57BuildGuardedQueuedSubmitSkeleton" "skeleton helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH" "skeleton branch global"
require_fixed frontend/wrapper-ui/app.js "guardedSubmitWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "guarded_queued_submit_skeleton_flag_disabled_stage_5f57" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "guarded_queued_submit_skeleton_unwired_stage_5f57" "enabled unwired result"

require_fixed docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md "Stage 5F-59 should add a final pre-wiring readiness map" "next stage"

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
const marker = "(function stage5f57GuardedQueuedSubmitSkeletonBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-57 guarded submit skeleton branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-57 guarded submit skeleton branch block end not found");
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
      json: async () => ({ ok: true }),
    };
  },
};

vm.createContext(context);
vm.runInContext(block, context);

const branch = context.AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH missing");
}

if (branch.guardedSubmitWired !== false) {
  throw new Error("guarded submit skeleton should remain unwired");
}

const disabled = branch.buildGuardedQueuedSubmitSkeleton({
  message: "flag off",
  chat_id: "chat-off",
  requested_model: "model-off",
});

if (disabled.reason !== "guarded_queued_submit_skeleton_flag_disabled_stage_5f57") {
  throw new Error("disabled reason mismatch: " + JSON.stringify(disabled));
}

if (disabled.enabled !== false) {
  throw new Error("disabled result should report enabled false: " + JSON.stringify(disabled));
}

if (disabled.legacyChatPathActive !== true) {
  throw new Error("disabled result should keep legacy path active: " + JSON.stringify(disabled));
}

if (disabled.queuedSubmitSelected !== false) {
  throw new Error("disabled result should not select queued submit: " + JSON.stringify(disabled));
}

if (disabled.guardedSubmitWired !== false) {
  throw new Error("disabled result should report guardedSubmitWired false: " + JSON.stringify(disabled));
}

if (!Array.isArray(disabled.plannedOrder)) {
  throw new Error("plannedOrder missing: " + JSON.stringify(disabled));
}

const expectedOrder = [
  "build_safe_payload",
  "make_submit_decision",
  "run_orchestration_once",
  "render_placeholder_once",
  "poll_status_once",
  "render_final_once",
];

if (disabled.plannedOrder.join(",") !== expectedOrder.join(",")) {
  throw new Error("plannedOrder mismatch: " + JSON.stringify(disabled.plannedOrder));
}

context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = {};

const enabled = branch.buildGuardedQueuedSubmitSkeleton({
  message: "flag on but unwired",
  chat_id: "chat-on",
  requested_model: "model-on",
});

if (enabled.reason !== "guarded_queued_submit_skeleton_unwired_stage_5f57") {
  throw new Error("enabled reason mismatch: " + JSON.stringify(enabled));
}

if (enabled.enabled !== true) {
  throw new Error("enabled result should report enabled true: " + JSON.stringify(enabled));
}

if (enabled.legacyChatPathActive !== false) {
  throw new Error("enabled skeleton should report legacy path inactive only in skeleton result: " + JSON.stringify(enabled));
}

if (enabled.queuedSubmitSelected !== false) {
  throw new Error("enabled skeleton must still not select queued submit while unwired: " + JSON.stringify(enabled));
}

if (enabled.guardedSubmitWired !== false) {
  throw new Error("enabled result should report guardedSubmitWired false: " + JSON.stringify(enabled));
}

const presence = enabled.helperPresence || {};

for (const key of ["payload", "decision", "orchestration", "send", "poll", "placeholder"]) {
  if (presence[key] !== true) {
    throw new Error("helperPresence missing " + key + ": " + JSON.stringify(enabled));
  }
}

if (fetchCalls.length !== 0) {
  throw new Error("guarded submit skeleton must not call fetch");
}

console.log("OK: guarded queued submit skeleton mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat guarded submit skeleton mock test smoke passed"
