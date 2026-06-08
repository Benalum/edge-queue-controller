#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat submit pre-wiring readiness map static check ==="

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

require_file docs/frontend-queued-chat-submit-prewiring-readiness-map.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton.md
require_file docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md
require_file docs/frontend-queued-chat-flag-on-submit-wiring-plan.md
require_file docs/frontend-queued-chat-flag-off-live-submit-preservation.md
require_file docs/frontend-queued-chat-submit-disabled-rollback-smoke.md
require_file docs/frontend-queued-chat-submit-orchestration-mock-test.md
require_file docs/frontend-queued-chat-submit-orchestration-branch.md
require_file docs/frontend-queued-chat-submit-orchestration-plan.md
require_file docs/frontend-queued-chat-submit-payload-builder-mock-test.md
require_file docs/frontend-queued-chat-submit-payload-builder-branch.md
require_file docs/frontend-queued-chat-submit-dry-run-mock-test.md
require_file docs/frontend-queued-chat-submit-dry-run-branch.md
require_file docs/frontend-queued-chat-submit-decision-mock-test.md
require_file docs/frontend-queued-chat-submit-decision-branch.md
require_file docs/frontend-queued-chat-send-helper-mock-test.md
require_file docs/frontend-queued-chat-status-poll-helper-mock-test.md
require_file docs/frontend-queued-chat-assistant-placeholder-mock-test.md
require_file docs/real-user-route-ct101-bounded-lifecycle.md
require_file docs/real-user-queued-chat-rollback-offline.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "planning and static verification only" "planning/static only"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "does not enable queued chat by default" "default disabled"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "check AI_PLATFORM_QUEUED_CHAT_ENABLED" "flag first"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "build safe payload once" "payload once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "make submit decision once" "decision once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "run queued submit orchestration once" "orchestration once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "call queued send once" "send once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "render assistant placeholder once" "placeholder once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "poll status once per job_id" "poll once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "render final assistant reply once" "final once"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "duplicate POST /api/chat/queued calls" "duplicate POST protection"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "AI_PLATFORM_QUEUED_CHAT_ENABLED false keeps legacy submit active" "rollback flag off"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "The frontend must not send:" "security behavior"
require_fixed docs/frontend-queued-chat-submit-prewiring-readiness-map.md "Stage 5F-60 should add the first guarded live-submit branch" "next stage"

require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "frontend queued flag default false"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-57: guarded queued submit branch skeleton marker." "guarded marker near submit"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH" "guarded skeleton branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH" "orchestration branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "poll branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch exists"

require_fixed frontend/wrapper-ui/app.js "guardedSubmitWired: false" "guarded submit not wired"
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
        "guarded skeleton live call",
        r"AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH[.]buildGuardedQueuedSubmitSkeleton\s*\(",
    ),
    (
        "orchestration live call",
        r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH[.]runQueuedChatSubmitOrchestration\s*\(",
    ),
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

for marker in [
    "Stage 5F-43: queued-chat submit insertion guard marker.",
    "Stage 5F-57: guarded queued submit branch skeleton marker.",
]:
    if marker not in live_text:
        print(f"FAIL: missing marker in live text: {marker}")
        sys.exit(1)

lines = live_text.splitlines()
marker = "Stage 5F-57: guarded queued submit branch skeleton marker."
marker_line = next((i for i, line in enumerate(lines, 1) if marker in line), None)

if marker_line is None:
    print("FAIL: Stage 5F-57 marker line missing")
    sys.exit(1)

nearby = "\n".join(lines[marker_line - 1:min(len(lines), marker_line + 100)])
anchors = [
    'addEventListener("submit"',
    "addEventListener('submit'",
    "handleChatSubmit",
    "sendChatMessage",
    "sendMessage",
]

if not any(anchor in nearby for anchor in anchors):
    print("FAIL: Stage 5F-57 marker is not near live submit/send anchor")
    print(f"marker_line={marker_line}")
    sys.exit(1)

print("OK: no queued submit helpers are called from live paths")
print("OK: pre-wiring markers remain near live submit path")
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

echo "PASS: frontend queued chat submit pre-wiring readiness map markers are present"
