#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit disabled rollback smoke ==="

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

require_file docs/frontend-queued-chat-submit-disabled-rollback-smoke.md
require_file docs/frontend-queued-chat-submit-orchestration-mock-test.md
require_file docs/frontend-queued-chat-submit-orchestration-branch.md
require_file docs/frontend-queued-chat-submit-orchestration-plan.md
require_file docs/frontend-queued-chat-submit-payload-builder-mock-test.md
require_file docs/frontend-queued-chat-submit-dry-run-mock-test.md
require_file docs/frontend-queued-chat-submit-decision-mock-test.md
require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file docs/frontend-queued-chat-status-poll-helper-mock-test.md
require_file docs/frontend-queued-chat-assistant-placeholder-mock-test.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "static verification only" "static only"
require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "does not enable queued chat by default" "default disabled"
require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "Rollback must remain instant" "rollback requirement"
require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "orchestrationWired false keeps orchestration out of live submit" "orchestration rollback"
require_fixed docs/frontend-queued-chat-submit-disabled-rollback-smoke.md "Stage 5F-54 should add a mocked flag-off live submit preservation smoke" "next stage"

require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "frontend queued flag default false"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH" "dry-run branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH" "orchestration branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "status poll branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch exists"

require_fixed frontend/wrapper-ui/app.js "payloadWired: false" "payload not wired"
require_fixed frontend/wrapper-ui/app.js "dryRunWired: false" "dry-run not wired"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision not wired"
require_fixed frontend/wrapper-ui/app.js "orchestrationWired: false" "orchestration not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder not wired"

python3 - <<'PYCHECK'
from pathlib import Path
import re
import sys

text = Path("frontend/wrapper-ui/app.js").read_text()

# Ignore isolated Stage 5F-51 orchestration helper. It is intentionally not wired
# to live submit and exists for direct mock testing.
start_marker = "(function stage5f51QueuedChatSubmitOrchestrationBranch(root)"
end_marker = "})(typeof window !== \"undefined\" ? window : globalThis);"

start = text.find(start_marker)
if start >= 0:
    end = text.find(end_marker, start)
    if end >= 0:
        live_text = text[:start] + text[end + len(end_marker):]
    else:
        live_text = text
else:
    live_text = text

checks = [
    (
        "payload builder live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH[.]buildQueuedChatSubmitPayload\s*\(",
    ),
    (
        "dry-run live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH[.]buildQueuedChatSubmitDryRun\s*\(",
    ),
    (
        "decision live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit\s*\(",
    ),
    (
        "orchestration live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH[.]runQueuedChatSubmitOrchestration\s*\(",
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
        print(f"FAIL: {label} found outside isolated Stage 5F-51 helper")
        lines = live_text.splitlines()
        for m in matches:
            line_no = live_text[:m.start()].count("\n") + 1
            line = lines[line_no - 1] if 0 <= line_no - 1 < len(lines) else ""
            print(f"{line_no}: {line}")
        sys.exit(1)

print("OK: no queued submit orchestration helpers are called from live paths")
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
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat submit disabled rollback smoke passed"
