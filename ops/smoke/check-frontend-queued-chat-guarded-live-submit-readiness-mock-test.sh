#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat guarded live-submit readiness mock test smoke ==="

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

require_file docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md
require_file docs/frontend-queued-chat-guarded-live-submit-readiness.md
require_file docs/frontend-queued-chat-submit-prewiring-readiness-map.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-60: disabled guarded live-submit readiness branch." "readiness branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f60BuildGuardedLiveSubmitReadiness" "readiness helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH" "readiness branch global"
require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "guarded_live_submit_flag_disabled_stage_5f60" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "guarded_live_submit_unwired_stage_5f60" "enabled unwired result"

require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md "Stage 5F-62 should add a final flag-off live-submit regression smoke" "next stage"

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
const marker = "(function stage5f60GuardedLiveSubmitReadinessBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-60 guarded live-submit readiness branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-60 guarded live-submit readiness branch block end not found");
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

const branch = context.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH missing");
}

if (branch.guardedLiveSubmitWired !== false) {
  throw new Error("guarded live submit readiness branch should remain unwired");
}

const disabled = branch.buildGuardedLiveSubmitReadiness({
  message: "flag off",
  chat_id: "chat-off",
  requested_model: "model-off",
});

if (disabled.reason !== "guarded_live_submit_flag_disabled_stage_5f60") {
  throw new Error("disabled reason mismatch: " + JSON.stringify(disabled));
}

if (disabled.enabled !== false) {
  throw new Error("disabled result should report enabled false: " + JSON.stringify(disabled));
}

if (disabled.liveSubmitSelected !== false) {
  throw new Error("disabled result should not select live queued submit: " + JSON.stringify(disabled));
}

if (disabled.legacyChatPathActive !== true) {
  throw new Error("disabled result should keep legacy path active: " + JSON.stringify(disabled));
}

if (disabled.guardedLiveSubmitWired !== false) {
  throw new Error("disabled result should report guardedLiveSubmitWired false: " + JSON.stringify(disabled));
}

const expectedBeforeEnable = [
  "flag_off_legacy_submit_unchanged",
  "single_orchestration_call",
  "single_queued_send",
  "single_placeholder",
  "single_poll_loop",
  "single_final_render",
  "rollback_flag_off",
];

if (!Array.isArray(disabled.requiredBeforeEnable)) {
  throw new Error("requiredBeforeEnable missing: " + JSON.stringify(disabled));
}

if (disabled.requiredBeforeEnable.join(",") !== expectedBeforeEnable.join(",")) {
  throw new Error("requiredBeforeEnable mismatch: " + JSON.stringify(disabled.requiredBeforeEnable));
}

context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;
context.AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = {};
context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = {};

const enabled = branch.buildGuardedLiveSubmitReadiness({
  message: "flag on but unwired",
  chat_id: "chat-on",
  requested_model: "model-on",
});

if (enabled.reason !== "guarded_live_submit_unwired_stage_5f60") {
  throw new Error("enabled reason mismatch: " + JSON.stringify(enabled));
}

if (enabled.enabled !== true) {
  throw new Error("enabled result should report enabled true: " + JSON.stringify(enabled));
}

if (enabled.liveSubmitSelected !== false) {
  throw new Error("enabled result must still not select live queued submit while unwired: " + JSON.stringify(enabled));
}

if (enabled.legacyChatPathActive !== true) {
  throw new Error("enabled result should keep legacy path active while unwired: " + JSON.stringify(enabled));
}

if (enabled.guardedLiveSubmitWired !== false) {
  throw new Error("enabled result should report guardedLiveSubmitWired false: " + JSON.stringify(enabled));
}

const presence = enabled.helperPresence || {};

for (const key of ["guardedSkeleton", "orchestration", "payload", "decision", "send", "poll", "placeholder"]) {
  if (presence[key] !== true) {
    throw new Error("helperPresence missing " + key + ": " + JSON.stringify(enabled));
  }
}

if (fetchCalls.length !== 0) {
  throw new Error("guarded live-submit readiness helper must not call fetch");
}

console.log("OK: guarded live-submit readiness helper mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat guarded live-submit readiness mock test smoke passed"
