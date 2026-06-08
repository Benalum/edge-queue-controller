#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat flag-on submit orchestration harness smoke ==="

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

require_file docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md
require_file docs/frontend-queued-chat-flag-on-submit-wiring-plan.md
require_file docs/frontend-queued-chat-flag-off-live-submit-preservation.md
require_file docs/frontend-queued-chat-submit-disabled-rollback-smoke.md
require_file docs/frontend-queued-chat-submit-orchestration-mock-test.md
require_file docs/frontend-queued-chat-submit-orchestration-branch.md
require_file docs/frontend-queued-chat-submit-orchestration-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md "flag off uses mocked legacy submit path" "flag off legacy"
require_fixed docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md "flag on calls queued orchestration once" "flag on once"
require_fixed docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md "no duplicate queued POST is simulated" "no duplicate POST"
require_fixed docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md "Stage 5F-57 should add a guarded submit branch skeleton" "next stage"

require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "frontend queued flag default false"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-43: queued-chat submit insertion guard marker." "submit insertion marker"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH" "orchestration branch exists"
require_fixed frontend/wrapper-ui/app.js "orchestrationWired: false" "orchestration not wired"
require_fixed frontend/wrapper-ui/app.js "payloadWired: false" "payload not wired"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller not wired"
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
    (
        "orchestration live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH[.]runQueuedChatSubmitOrchestration\s*\(",
    ),
    (
        "payload builder live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH[.]buildQueuedChatSubmitPayload\s*\(",
    ),
    (
        "decision live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit\s*\(",
    ),
    (
        "queued send live call",
        r"AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH[.]sendQueuedChat\s*\(",
    ),
    (
        "queued poll live call",
        r"AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH[.]pollQueuedChatStatus\s*\(",
    ),
    (
        "queued placeholder live call",
        r"AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH[.]buildQueuedAssistantPlaceholder\s*\(",
    ),
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

if "Stage 5F-43: queued-chat submit insertion guard marker." not in live_text:
    print("FAIL: Stage 5F-43 marker missing from live path")
    sys.exit(1)

print("OK: no queued submit helpers are called from live paths")
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
const marker = "(function stage5f51QueuedChatSubmitOrchestrationBranch(root)";
const start = source.indexOf(marker);

if (start < 0) {
  throw new Error("Stage 5F-51 queued submit orchestration branch block not found");
}

const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";
const end = source.indexOf(endMarker, start);

if (end < 0) {
  throw new Error("Stage 5F-51 queued submit orchestration branch block end not found");
}

const block = source.slice(start, end + endMarker.length);

const counts = {
  legacySubmit: 0,
  orchestration: 0,
  payload: 0,
  decision: 0,
  send: 0,
  placeholder: 0,
  poll: 0,
  finalRender: 0,
};

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
};

vm.createContext(context);
vm.runInContext(block, context);

const branch = context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH;

if (!branch) {
  throw new Error("orchestration branch missing");
}

if (branch.orchestrationWired !== false) {
  throw new Error("orchestration branch should remain unwired");
}

async function mockedLiveSubmit(input) {
  if (context.AI_PLATFORM_QUEUED_CHAT_ENABLED !== true) {
    counts.legacySubmit += 1;
    return {
      ok: true,
      path: "legacy",
      legacySubmitActive: true,
      queuedSelected: false,
    };
  }

  counts.orchestration += 1;
  const result = await branch.runQueuedChatSubmitOrchestration(input, {
    pollIntervalMs: 1,
    maxPolls: 1,
  });

  if (result && result.ok === true && result.statusResult && result.statusResult.result_json) {
    counts.finalRender += 1;
  }

  return {
    ok: result.ok === true,
    path: "queued",
    legacySubmitActive: false,
    queuedSelected: true,
    result,
  };
}

(async () => {
  const flagOff = await mockedLiveSubmit({
    message: "flag off should stay legacy",
    chat_id: "chat-off",
    requested_model: "model-off",
  });

  if (flagOff.path !== "legacy" || flagOff.queuedSelected !== false) {
    throw new Error("flag-off submit should remain legacy: " + JSON.stringify(flagOff));
  }

  if (counts.legacySubmit !== 1 || counts.orchestration !== 0) {
    throw new Error("flag-off counts mismatch: " + JSON.stringify(counts));
  }

  context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;

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
        job_id: "stage-5f56-job",
        chat_id: payload.chat_id,
        user_message_id: "stage-5f56-user-message",
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = {
    buildQueuedAssistantPlaceholder: (job) => {
      counts.placeholder += 1;

      if (job.job_id !== "stage-5f56-job") {
        throw new Error("placeholder received wrong job: " + JSON.stringify(job));
      }

      return {
        ok: true,
        placeholder_id: "stage-5f56-placeholder",
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = {
    pollQueuedChatStatus: async (jobId) => {
      counts.poll += 1;

      if (jobId !== "stage-5f56-job") {
        throw new Error("poll received wrong job id: " + jobId);
      }

      return {
        ok: true,
        status: "complete",
        result_json: {
          reply: "stage 5f56 final reply",
        },
      };
    },
  };

  const flagOn = await mockedLiveSubmit({
    message: "  flag on queued message  ",
    chat_id: "stage-5f56-chat",
    requested_model: "stage-5f56-model",
    user_id: "must-not-send",
    authenticated_user_id: "must-not-send",
    "X-Synthetic-User-Id": "must-not-send",
    extra: "must-not-send",
  });

  if (flagOn.path !== "queued" || flagOn.queuedSelected !== true) {
    throw new Error("flag-on submit should select queued path: " + JSON.stringify(flagOn));
  }

  if (!flagOn.result || flagOn.result.ok !== true) {
    throw new Error("flag-on orchestration result should be ok: " + JSON.stringify(flagOn));
  }

  const expected = {
    legacySubmit: 1,
    orchestration: 1,
    payload: 1,
    decision: 1,
    send: 1,
    placeholder: 1,
    poll: 1,
    finalRender: 1,
  };

  for (const [key, value] of Object.entries(expected)) {
    if (counts[key] !== value) {
      throw new Error("call count mismatch for " + key + ": " + JSON.stringify(counts));
    }
  }

  if (flagOn.result.calls.join(",") !== "payload,decision,send,placeholder,poll") {
    throw new Error("orchestration order mismatch: " + JSON.stringify(flagOn.result.calls));
  }

  if (Object.keys(flagOn.result.payload).sort().join(",") !== "chat_id,message,requested_model") {
    throw new Error("unsafe payload keys in orchestration result: " + JSON.stringify(flagOn.result.payload));
  }

  if (flagOn.result.payload.message !== "flag on queued message") {
    throw new Error("queued message was not trimmed: " + JSON.stringify(flagOn.result.payload));
  }

  console.log("OK: mocked flag-on live-submit-style orchestration harness passed");
})().catch((err) => {
  console.error(err && err.stack ? err.stack : err);
  process.exit(1);
});
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat flag-on submit orchestration harness smoke passed"
