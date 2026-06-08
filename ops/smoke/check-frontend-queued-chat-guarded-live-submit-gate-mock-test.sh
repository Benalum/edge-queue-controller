#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat guarded live-submit gate mock test smoke ==="

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

require_file docs/frontend-queued-chat-guarded-live-submit-gate-mock-test.md
require_file docs/frontend-queued-chat-guarded-live-submit-gate.md
require_file docs/frontend-queued-chat-flag-off-live-submit-regression.md
require_file docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md
require_file docs/frontend-queued-chat-guarded-live-submit-readiness.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-63: disabled guarded live-submit gate branch." "gate branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f63EvaluateGuardedLiveSubmitGate" "gate helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH" "gate branch global"
require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitGateWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "guarded_live_submit_gate_flag_disabled_stage_5f63" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "guarded_live_submit_gate_unwired_stage_5f63" "enabled unwired result"

require_fixed docs/frontend-queued-chat-guarded-live-submit-gate-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-guarded-live-submit-gate-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-guarded-live-submit-gate-mock-test.md "No real CT101 call is made." "no CT101"
require_fixed docs/frontend-queued-chat-guarded-live-submit-gate-mock-test.md "Stage 5F-65 should add a final guarded live-submit gate rollback smoke" "next stage"

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
const marker = "(function stage5f63GuardedLiveSubmitGateBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-63 guarded live-submit gate branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-63 guarded live-submit gate branch block end not found");
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

const branch = context.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH missing");
}

if (branch.guardedLiveSubmitGateWired !== false) {
  throw new Error("guarded live-submit gate branch should remain unwired");
}

const disabled = branch.evaluateGuardedLiveSubmitGate({
  message: "flag off",
  chat_id: "chat-off",
  requested_model: "model-off",
});

if (disabled.reason !== "guarded_live_submit_gate_flag_disabled_stage_5f63") {
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

if (disabled.queuedSubmitAllowed !== false) {
  throw new Error("disabled result should not allow queued submit: " + JSON.stringify(disabled));
}

if (disabled.readinessPresent !== false) {
  throw new Error("disabled result should report readiness absent by default in isolated block: " + JSON.stringify(disabled));
}

if (disabled.guardedLiveSubmitGateWired !== false) {
  throw new Error("disabled result should report guardedLiveSubmitGateWired false: " + JSON.stringify(disabled));
}

const expectedBlockedActions = [
  "queued_orchestration",
  "queued_send",
  "queued_polling",
  "queued_placeholder",
  "queued_final_render",
];

if (!Array.isArray(disabled.blockedActions)) {
  throw new Error("blockedActions missing: " + JSON.stringify(disabled));
}

if (disabled.blockedActions.join(",") !== expectedBlockedActions.join(",")) {
  throw new Error("blockedActions mismatch: " + JSON.stringify(disabled.blockedActions));
}

const expectedRequiredBeforeWire = [
  "flag_off_regression_passes",
  "gate_mock_test_passes",
  "single_orchestration_call_proven",
  "single_send_call_proven",
  "single_poll_loop_proven",
  "single_final_render_proven",
  "rollback_flag_off_proven",
];

if (!Array.isArray(disabled.requiredBeforeWire)) {
  throw new Error("requiredBeforeWire missing: " + JSON.stringify(disabled));
}

if (disabled.requiredBeforeWire.join(",") !== expectedRequiredBeforeWire.join(",")) {
  throw new Error("requiredBeforeWire mismatch: " + JSON.stringify(disabled.requiredBeforeWire));
}

context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;
context.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH = {};

const enabled = branch.evaluateGuardedLiveSubmitGate({
  message: "flag on but unwired",
  chat_id: "chat-on",
  requested_model: "model-on",
});

if (enabled.reason !== "guarded_live_submit_gate_unwired_stage_5f63") {
  throw new Error("enabled reason mismatch: " + JSON.stringify(enabled));
}

if (enabled.enabled !== true) {
  throw new Error("enabled result should report enabled true: " + JSON.stringify(enabled));
}

if (enabled.readinessPresent !== true) {
  throw new Error("enabled result should report readiness present: " + JSON.stringify(enabled));
}

if (enabled.liveSubmitSelected !== false) {
  throw new Error("enabled result must still not select live queued submit while unwired: " + JSON.stringify(enabled));
}

if (enabled.legacyChatPathActive !== true) {
  throw new Error("enabled result should keep legacy path active while unwired: " + JSON.stringify(enabled));
}

if (enabled.queuedSubmitAllowed !== false) {
  throw new Error("enabled result should not allow queued submit while unwired: " + JSON.stringify(enabled));
}

if (enabled.guardedLiveSubmitGateWired !== false) {
  throw new Error("enabled result should report guardedLiveSubmitGateWired false: " + JSON.stringify(enabled));
}

if (enabled.blockedActions.join(",") !== expectedBlockedActions.join(",")) {
  throw new Error("enabled blockedActions mismatch: " + JSON.stringify(enabled.blockedActions));
}

if (enabled.requiredBeforeWire.join(",") !== expectedRequiredBeforeWire.join(",")) {
  throw new Error("enabled requiredBeforeWire mismatch: " + JSON.stringify(enabled.requiredBeforeWire));
}

if (fetchCalls.length !== 0) {
  throw new Error("guarded live-submit gate helper must not call fetch");
}

console.log("OK: guarded live-submit gate helper mock behavior passed");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat guarded live-submit gate mock test smoke passed"
