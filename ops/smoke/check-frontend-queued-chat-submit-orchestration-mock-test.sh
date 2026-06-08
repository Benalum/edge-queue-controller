#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit orchestration mock test smoke ==="

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

require_file docs/frontend-queued-chat-submit-orchestration-mock-test.md
require_file docs/frontend-queued-chat-submit-orchestration-branch.md
require_file docs/frontend-queued-chat-submit-orchestration-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed frontend/wrapper-ui/app.js "Stage 5F-51: disabled queued-chat submit orchestration branch." "orchestration branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f51RunQueuedChatSubmitOrchestration" "orchestration helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH" "orchestration branch global"
require_fixed frontend/wrapper-ui/app.js "orchestrationWired: false" "not wired"
require_fixed frontend/wrapper-ui/app.js "queued_orchestration_flag_disabled_stage_5f51" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "queued_orchestration_payload_helper_missing_stage_5f51" "missing payload helper result"
require_fixed frontend/wrapper-ui/app.js "queued_orchestration_payload_failed_stage_5f51" "payload failed result"
require_fixed frontend/wrapper-ui/app.js "queued_orchestration_decision_refused_stage_5f51" "decision refused result"

require_fixed docs/frontend-queued-chat-submit-orchestration-mock-test.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-orchestration-mock-test.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-orchestration-mock-test.md "helper order is payload, decision, send, placeholder, poll" "helper order doc"
require_fixed docs/frontend-queued-chat-submit-orchestration-mock-test.md "Stage 5F-53 should add a rollback/static smoke" "next stage"

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

const context = {
  console,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: false,
};

vm.createContext(context);
vm.runInContext(block, context);

const branch = context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH;

if (!branch) {
  throw new Error("AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH missing");
}

if (branch.orchestrationWired !== false) {
  throw new Error("orchestration branch should remain unwired");
}

(async () => {
  const disabled = await branch.runQueuedChatSubmitOrchestration({
    message: "disabled",
  });

  if (!disabled.skipped || disabled.reason !== "queued_orchestration_flag_disabled_stage_5f51") {
    throw new Error("disabled orchestration result mismatch: " + JSON.stringify(disabled));
  }

  if (disabled.legacyChatPathActive !== true) {
    throw new Error("disabled orchestration should keep legacy path active: " + JSON.stringify(disabled));
  }

  context.AI_PLATFORM_QUEUED_CHAT_ENABLED = true;

  delete context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH;

  const missingPayloadHelper = await branch.runQueuedChatSubmitOrchestration({
    message: "missing payload helper",
  });

  if (missingPayloadHelper.error !== "queued_orchestration_payload_helper_missing_stage_5f51") {
    throw new Error("missing payload helper result mismatch: " + JSON.stringify(missingPayloadHelper));
  }

  let payloadCalls = 0;
  let decisionCalls = 0;
  let sendCalls = 0;
  let placeholderCalls = 0;
  let pollCalls = 0;

  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = {
    buildQueuedChatSubmitPayload: () => {
      payloadCalls += 1;
      return {
        ok: false,
        error: "mock_payload_failure",
      };
    },
  };

  const payloadFailure = await branch.runQueuedChatSubmitOrchestration({
    message: "payload failure",
  });

  if (payloadFailure.error !== "queued_orchestration_payload_failed_stage_5f51") {
    throw new Error("payload failure result mismatch: " + JSON.stringify(payloadFailure));
  }

  if (payloadFailure.calls.join(",") !== "payload") {
    throw new Error("payload failure call order mismatch: " + JSON.stringify(payloadFailure.calls));
  }

  payloadCalls = 0;
  decisionCalls = 0;
  sendCalls = 0;
  placeholderCalls = 0;
  pollCalls = 0;

  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = {
    buildQueuedChatSubmitPayload: (input) => {
      payloadCalls += 1;
      return {
        ok: true,
        payload: {
          message: String(input.message || "").trim(),
          chat_id: "chat-mock",
          requested_model: "model-mock",
        },
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = {
    shouldUseQueuedChatForSubmit: () => {
      decisionCalls += 1;
      return {
        ok: true,
        shouldUseQueuedChat: false,
        reason: "mock_decision_refused",
      };
    },
  };

  const decisionRefused = await branch.runQueuedChatSubmitOrchestration({
    message: "decision refused",
    user_id: "must-not-matter",
    authenticated_user_id: "must-not-matter",
    "X-Synthetic-User-Id": "must-not-matter",
  });

  if (decisionRefused.error !== "queued_orchestration_decision_refused_stage_5f51") {
    throw new Error("decision refused result mismatch: " + JSON.stringify(decisionRefused));
  }

  if (decisionRefused.calls.join(",") !== "payload,decision") {
    throw new Error("decision refused call order mismatch: " + JSON.stringify(decisionRefused.calls));
  }

  if (payloadCalls !== 1 || decisionCalls !== 1 || sendCalls !== 0 || placeholderCalls !== 0 || pollCalls !== 0) {
    throw new Error("decision refusal call counts mismatch");
  }

  payloadCalls = 0;
  decisionCalls = 0;
  sendCalls = 0;
  placeholderCalls = 0;
  pollCalls = 0;

  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = {
    buildQueuedChatSubmitPayload: (input) => {
      payloadCalls += 1;

      const payload = {
        message: String(input.message || "").trim(),
      };

      if (input.chat_id) {
        payload.chat_id = String(input.chat_id);
      }

      if (input.requested_model) {
        payload.requested_model = String(input.requested_model);
      }

      return {
        ok: true,
        payload,
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = {
    shouldUseQueuedChatForSubmit: (payload) => {
      decisionCalls += 1;

      const keys = Object.keys(payload).sort().join(",");
      if (keys !== "chat_id,message,requested_model") {
        throw new Error("unsafe payload keys reached decision helper: " + keys);
      }

      return {
        ok: true,
        shouldUseQueuedChat: true,
        reason: "mock_decision_accepted",
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = {
    sendQueuedChat: async (payload) => {
      sendCalls += 1;

      const keys = Object.keys(payload).sort().join(",");
      if (keys !== "chat_id,message,requested_model") {
        throw new Error("unsafe payload keys reached send helper: " + keys);
      }

      return {
        ok: true,
        job_id: "job-stage-5f52",
        chat_id: payload.chat_id,
        user_message_id: "msg-stage-5f52-user",
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = {
    buildQueuedAssistantPlaceholder: (job, options) => {
      placeholderCalls += 1;

      if (job.job_id !== "job-stage-5f52") {
        throw new Error("placeholder received wrong job: " + JSON.stringify(job));
      }

      return {
        ok: true,
        placeholderText: "Queued...",
        canRenderAssistant: false,
      };
    },
  };

  context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = {
    pollQueuedChatStatus: async (jobId, options) => {
      pollCalls += 1;

      if (jobId !== "job-stage-5f52") {
        throw new Error("poll received wrong job id: " + jobId);
      }

      return {
        ok: true,
        status: "complete",
        result_json: {
          reply: "mock final reply",
        },
      };
    },
  };

  const success = await branch.runQueuedChatSubmitOrchestration(
    {
      message: "  hello queued orchestration  ",
      chat_id: "chat-stage-5f52",
      requested_model: "model-stage-5f52",
      user_id: "must-not-send",
      authenticated_user_id: "must-not-send",
      "X-Synthetic-User-Id": "must-not-send",
      extra: "must-not-send",
    },
    {
      pollIntervalMs: 1,
      maxPolls: 1,
    }
  );

  if (success.ok !== true) {
    throw new Error("success result should be ok: " + JSON.stringify(success));
  }

  if (success.orchestrationWired !== false) {
    throw new Error("success result should report orchestrationWired false: " + JSON.stringify(success));
  }

  if (success.calls.join(",") !== "payload,decision,send,placeholder,poll") {
    throw new Error("success call order mismatch: " + JSON.stringify(success.calls));
  }

  if (payloadCalls !== 1 || decisionCalls !== 1 || sendCalls !== 1 || placeholderCalls !== 1 || pollCalls !== 1) {
    throw new Error(
      "success call counts mismatch: "
        + JSON.stringify({ payloadCalls, decisionCalls, sendCalls, placeholderCalls, pollCalls })
    );
  }

  if (success.job_id !== "job-stage-5f52") {
    throw new Error("success job_id mismatch: " + JSON.stringify(success));
  }

  if (success.chat_id !== "chat-stage-5f52") {
    throw new Error("success chat_id mismatch: " + JSON.stringify(success));
  }

  if (success.user_message_id !== "msg-stage-5f52-user") {
    throw new Error("success user_message_id mismatch: " + JSON.stringify(success));
  }

  if (Object.keys(success.payload).sort().join(",") !== "chat_id,message,requested_model") {
    throw new Error("success payload contains unsafe fields: " + JSON.stringify(success.payload));
  }

  if (success.payload.message !== "hello queued orchestration") {
    throw new Error("success payload message should be trimmed: " + JSON.stringify(success.payload));
  }

  console.log("OK: queued submit orchestration helper mock behavior passed");
})().catch((err) => {
  console.error(err && err.stack ? err.stack : err);
  process.exit(1);
});
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat submit orchestration mock test smoke passed"
