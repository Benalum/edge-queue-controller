#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat live-submit wiring dry-run harness smoke ==="

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

require_file docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md
require_file docs/frontend-queued-chat-live-submit-wiring-implementation-plan.md
require_file docs/frontend-queued-chat-guarded-live-submit-gate-rollback.md
require_file docs/frontend-queued-chat-guarded-live-submit-gate-mock-test.md
require_file docs/frontend-queued-chat-guarded-live-submit-gate.md
require_file docs/frontend-queued-chat-flag-off-live-submit-regression.md
require_file docs/frontend-queued-chat-guarded-live-submit-readiness-mock-test.md
require_file docs/frontend-queued-chat-guarded-live-submit-readiness.md
require_file docs/frontend-queued-chat-submit-prewiring-readiness-map.md
require_file docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md
require_file docs/frontend-queued-chat-submit-orchestration-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "smoke-test only" "smoke only"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "does not modify app.js" "does not modify app"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "does not enable queued chat by default" "default disabled"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "flag off keeps mocked legacy submit path" "flag off legacy"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "flag on but real gate unwired blocks queued submit" "flag on unwired blocked"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "flag on with mocked future gate wiring calls orchestration once" "mocked future wiring"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "evaluate guarded live-submit gate once" "gate once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "build safe payload once" "payload once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "make submit decision once" "decision once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "run queued submit orchestration once" "orchestration once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "render placeholder once" "placeholder once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "poll status once" "poll once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "render final assistant reply once" "final once"
require_fixed docs/frontend-queued-chat-live-submit-wiring-dry-run-harness.md "Stage 5F-68 should add a final pre-wiring go/no-go checklist" "next stage"

require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "frontend queued flag default false"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-63: guarded live-submit gate marker." "gate marker"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH" "gate branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH" "orchestration branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "poll branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch exists"

require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitGateWired: false" "gate not wired"
require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitWired: false" "live submit not wired"
require_fixed frontend/wrapper-ui/app.js "orchestrationWired: false" "orchestration not wired"
require_fixed frontend/wrapper-ui/app.js "payloadWired: false" "payload not wired"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poll not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder not wired"

python3 - <<'PYCHECK'
from pathlib import Path
import re
import sys

text = Path("frontend/wrapper-ui/app.js").read_text()

helper_names = [
    "stage5f31QueuedChatFlagDetection",
    "stage5f32QueuedChatSendBranch",
    "stage5f35QueuedChatStatusPollBranch",
    "stage5f37QueuedChatAssistantPlaceholderBranch",
    "stage5f40QueuedChatSubmitDecisionBranch",
    "stage5f45QueuedChatSubmitDryRunBranch",
    "stage5f48QueuedChatSubmitPayloadBranch",
    "stage5f51QueuedChatSubmitOrchestrationBranch",
    "stage5f57GuardedQueuedSubmitSkeletonBranch",
    "stage5f60GuardedLiveSubmitReadinessBranch",
    "stage5f63GuardedLiveSubmitGateBranch",
]

end_marker = "})(typeof window !== \"undefined\" ? window : globalThis);"
live_text = text

for helper in helper_names:
    start_marker = f"(function {helper}(root)"
    while True:
        start = live_text.find(start_marker)
        if start < 0:
            break
        end = live_text.find(end_marker, start)
        if end < 0:
            print(f"FAIL: could not find end marker for helper {helper}")
            sys.exit(1)
        live_text = live_text[:start] + live_text[end + len(end_marker):]

checks = [
    ("guarded gate live call", r"AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH[.]evaluateGuardedLiveSubmitGate\s*\("),
    ("orchestration live call", r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH[.]runQueuedChatSubmitOrchestration\s*\("),
    ("payload builder live call", r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH[.]buildQueuedChatSubmitPayload\s*\("),
    ("decision live call", r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit\s*\("),
    ("queued send live call", r"AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH[.]sendQueuedChat\s*\("),
    ("queued poll live call", r"AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH[.]pollQueuedChatStatus\s*\("),
    ("queued placeholder live call", r"AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH[.]buildQueuedAssistantPlaceholder\s*\("),
    ("queued API route live call", r"/api/chat/queued"),
]

for label, pattern in checks:
    matches = list(re.finditer(pattern, live_text))
    if matches:
        print(f"FAIL: {label} found outside isolated Stage 5F helper branches")
        lines = live_text.splitlines()
        for m in matches:
            line_no = live_text[:m.start()].count("\n") + 1
            line = lines[line_no - 1] if 0 <= line_no - 1 < len(lines) else ""
            print(f"{line_no}: {line}")
        sys.exit(1)

for marker in [
    "Stage 5F-43: queued-chat submit insertion guard marker.",
    "Stage 5F-57: guarded queued submit branch skeleton marker.",
    "Stage 5F-60: guarded live-submit branch marker.",
    "Stage 5F-63: guarded live-submit gate marker.",
]:
    if marker not in live_text:
        print(f"FAIL: missing marker in live text: {marker}")
        sys.exit(1)

print("OK: real app live submit path still has no queued helper calls")
PYCHECK

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

function extractBlock(functionName) {
  const marker = `(function ${functionName}(root)`;
  const start = source.indexOf(marker);

  if (start < 0) {
    throw new Error(`block not found: ${functionName}`);
  }

  const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
  const end = source.indexOf(endMarker, start);

  if (end < 0) {
    throw new Error(`block end not found: ${functionName}`);
  }

  return source.slice(start, end + endMarker.length);
}

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
};

const fetchCalls = [];
context.fetch = async (url, options) => {
  fetchCalls.push({ url, options });
  return {
    ok: true,
    status: 200,
    json: async () => ({ ok: true }),
  };
};

vm.createContext(context);

// Load real isolated helpers, but do not touch real submit.
for (const fn of [
  "stage5f63GuardedLiveSubmitGateBranch",
  "stage5f51QueuedChatSubmitOrchestrationBranch",
]) {
  vm.runInContext(extractBlock(fn), context);
}

const gateBranch = context.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH;
const orchestrationBranch = context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH;

if (!gateBranch || !orchestrationBranch) {
  throw new Error("required helper branches missing");
}

const counts = {
  legacySubmit: 0,
  gate: 0,
  gateBlocked: 0,
  mockedGateWired: 0,
  mockedLiveWired: 0,
  orchestration: 0,
  payload: 0,
  decision: 0,
  send: 0,
  placeholder: 0,
  poll: 0,
  finalRender: 0,
};

function installMockQueuedHelpers() {
  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = {
    buildQueuedChatSubmitPayload: (input) => {
      counts.payload += 1;

      const payload = {
        message: String(input.message || "").trim(),
      };

      if (input.chat_id) {
        payload.chat_id = String(input.chat_id);
      }

      if (input.requested_model) {
        payload.requested_model = String(input.requested_model);
      }

      const keys = Object.keys(payload).sort().join(",");
      if (keys !== "chat_id,message,requested_model") {
        throw new Error("unsafe payload keys from builder: " + keys);
      }

      return {
        ok: true,
        payload,
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = {
    shouldUseQueuedChatForSubmit: (payload) => {
      counts.decision += 1;

      const keys = Object.keys(payload).sort().join(",");
      if (keys !== "chat_id,message,requested_model") {
        throw new Error("unsafe payload keys reached decision: " + keys);
      }

      return {
        ok: true,
        shouldUseQueuedChat: true,
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {
    sendQueuedChat: async (payload) => {
      counts.send += 1;

      return {
        ok: true,
        job_id: "stage-5f67-job",
        chat_id: payload.chat_id,
        user_message_id: "stage-5f67-user-message",
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = {
    buildQueuedAssistantPlaceholder: (job) => {
      counts.placeholder += 1;

      if (job.job_id !== "stage-5f67-job") {
        throw new Error("placeholder received wrong job: " + JSON.stringify(job));
      }

      return {
        ok: true,
        placeholder_id: "stage-5f67-placeholder",
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = {
    pollQueuedChatStatus: async (jobId) => {
      counts.poll += 1;

      if (jobId !== "stage-5f67-job") {
        throw new Error("poll received wrong job id: " + jobId);
      }

      return {
        ok: true,
        status: "complete",
        result_json: {
          reply: "stage 5f67 final reply",
        },
      };
    },
  };
}

async function mockedFutureLiveSubmit(input, options = {}) {
  if (context.AI_PLATFORM_QUEUED_CHAT_ENABLED !== true) {
    counts.legacySubmit += 1;
    return {
      ok: true,
      path: "legacy",
      reason: "flag_off_legacy_submit_stage_5f67",
      queuedSelected: false,
    };
  }

  counts.gate += 1;
  const gateResult = gateBranch.evaluateGuardedLiveSubmitGate(input);

  if (options.mockGateWired !== true) {
    counts.gateBlocked += 1;
    counts.legacySubmit += 1;

    if (gateResult.queuedSubmitAllowed !== false) {
      throw new Error("real unwired gate should block queued submit: " + JSON.stringify(gateResult));
    }

    return {
      ok: true,
      path: "legacy",
      reason: "real_gate_unwired_blocks_queued_stage_5f67",
      gateResult,
      queuedSelected: false,
    };
  }

  counts.mockedGateWired += 1;

  if (options.mockLiveWired !== true) {
    counts.legacySubmit += 1;
    return {
      ok: true,
      path: "legacy",
      reason: "mock_live_wire_disabled_stage_5f67",
      queuedSelected: false,
    };
  }

  counts.mockedLiveWired += 1;
  counts.orchestration += 1;

  const result = await orchestrationBranch.runQueuedChatSubmitOrchestration(input, {
    pollIntervalMs: 1,
    maxPolls: 1,
  });

  if (result && result.ok === true && result.statusResult && result.statusResult.result_json) {
    counts.finalRender += 1;
  }

  return {
    ok: result.ok === true,
    path: "queued",
    reason: "mocked_future_live_submit_queued_stage_5f67",
    queuedSelected: true,
    result,
  };
}

(async () => {
  installMockQueuedHelpers();

  const flagOff = await mockedFutureLiveSubmit({
    message: "flag off stays legacy",
    chat_id: "stage-5f67-off",
    requested_model: "stage-5f67-model",
  });

  if (flagOff.path !== "legacy" || flagOff.queuedSelected !== false) {
    throw new Error("flag off should remain legacy: " + JSON.stringify(flagOff));
  }

  context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;

  const gateBlocked = await mockedFutureLiveSubmit({
    message: "flag on real gate blocks",
    chat_id: "stage-5f67-blocked",
    requested_model: "stage-5f67-model",
  });

  if (gateBlocked.path !== "legacy" || gateBlocked.queuedSelected !== false) {
    throw new Error("real unwired gate should keep legacy path: " + JSON.stringify(gateBlocked));
  }

  const queued = await mockedFutureLiveSubmit({
    message: "  flag on queued dry run  ",
    chat_id: "stage-5f67-chat",
    requested_model: "stage-5f67-model",
    user_id: "must-not-send",
    authenticated_user_id: "must-not-send",
    "X-Synthetic-User-Id": "must-not-send",
    extra: "must-not-send",
  }, {
    mockGateWired: true,
    mockLiveWired: true,
  });

  if (queued.path !== "queued" || queued.queuedSelected !== true) {
    throw new Error("mocked future wiring should select queued path: " + JSON.stringify(queued));
  }

  if (!queued.result || queued.result.ok !== true) {
    throw new Error("queued dry-run orchestration should succeed: " + JSON.stringify(queued));
  }

  const expectedCounts = {
    legacySubmit: 2,
    gate: 2,
    gateBlocked: 1,
    mockedGateWired: 1,
    mockedLiveWired: 1,
    orchestration: 1,
    payload: 1,
    decision: 1,
    send: 1,
    placeholder: 1,
    poll: 1,
    finalRender: 1,
  };

  for (const [key, expected] of Object.entries(expectedCounts)) {
    if (counts[key] !== expected) {
      throw new Error(`count mismatch for ${key}: ` + JSON.stringify(counts));
    }
  }

  if (queued.result.calls.join(",") !== "payload,decision,send,placeholder,poll") {
    throw new Error("orchestration order mismatch: " + JSON.stringify(queued.result.calls));
  }

  const payloadKeys = Object.keys(queued.result.payload).sort().join(",");
  if (payloadKeys !== "chat_id,message,requested_model") {
    throw new Error("unsafe payload keys in result: " + JSON.stringify(queued.result.payload));
  }

  if (queued.result.payload.message !== "flag on queued dry run") {
    throw new Error("message should be trimmed: " + JSON.stringify(queued.result.payload));
  }

  if (fetchCalls.length !== 0) {
    throw new Error("dry-run harness should not call real fetch");
  }

  console.log("OK: mocked live-submit wiring dry-run harness passed");
})().catch((err) => {
  console.error(err && err.stack ? err.stack : err);
  process.exit(1);
});
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat live-submit wiring dry-run harness smoke passed"
