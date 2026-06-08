#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat guarded live-submit readiness smoke ==="

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

require_file docs/frontend-queued-chat-guarded-live-submit-readiness.md
require_file docs/frontend-queued-chat-submit-prewiring-readiness-map.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton-mock-test.md
require_file docs/frontend-queued-chat-guarded-submit-skeleton.md
require_file docs/frontend-queued-chat-flag-on-submit-orchestration-harness.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness.md "guardedLiveSubmitWired false" "guarded live submit not wired doc"
require_fixed docs/frontend-queued-chat-guarded-live-submit-readiness.md "Stage 5F-61 should add a mocked test" "next stage"

require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "frontend queued flag default false"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-60: guarded live-submit branch marker." "live submit marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-60: disabled guarded live-submit readiness branch." "readiness branch marker"
require_fixed frontend/wrapper-ui/app.js "stage5f60BuildGuardedLiveSubmitReadiness" "readiness helper"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH" "readiness branch global"
require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitWired: false" "guarded live submit not wired"
require_fixed frontend/wrapper-ui/app.js "guarded_live_submit_flag_disabled_stage_5f60" "flag disabled result"
require_fixed frontend/wrapper-ui/app.js "guarded_live_submit_unwired_stage_5f60" "enabled unwired result"

python3 - <<'PYCHECK'
from pathlib import Path
import re
import sys

text = Path("frontend/wrapper-ui/app.js").read_text()

marker = "Stage 5F-60: guarded live-submit branch marker."
if text.count(marker) != 1:
    print(f"FAIL: expected exactly one Stage 5F-60 live-submit marker, found {text.count(marker)}")
    sys.exit(1)

lines = text.splitlines()
marker_line = next((i for i, line in enumerate(lines, 1) if marker in line), None)

if marker_line is None:
    print("FAIL: Stage 5F-60 marker line missing")
    sys.exit(1)

nearby = "\n".join(lines[marker_line - 1:min(len(lines), marker_line + 120)])
anchors = [
    'addEventListener("submit"',
    "addEventListener('submit'",
    "handleChatSubmit",
    "sendChatMessage",
    "sendMessage",
    "Stage 5F-57: guarded queued submit branch skeleton marker.",
]

if not any(anchor in nearby for anchor in anchors):
    print("FAIL: Stage 5F-60 marker is not near live submit/send anchor")
    print(f"marker_line={marker_line}")
    sys.exit(1)

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
        "guarded live readiness live call",
        r"AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH[.]buildGuardedLiveSubmitReadiness\s*\(",
    ),
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
        print(f"FAIL: {label} found outside isolated helper branches")
        live_lines = live_text.splitlines()
        for m in matches:
            line_no = live_text[:m.start()].count("\n") + 1
            line = live_lines[line_no - 1] if 0 <= line_no - 1 < len(live_lines) else ""
            print(f"{line_no}: {line}")
        sys.exit(1)

for required_marker in [
    "Stage 5F-43: queued-chat submit insertion guard marker.",
    "Stage 5F-57: guarded queued submit branch skeleton marker.",
    "Stage 5F-60: guarded live-submit branch marker.",
]:
    if required_marker not in live_text:
        print(f"FAIL: missing marker in live text: {required_marker}")
        sys.exit(1)

print("OK: Stage 5F-60 marker is near live submit path")
print("OK: guarded live-submit readiness is not called from live submit")
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

echo "PASS: frontend queued chat guarded live-submit readiness smoke passed"
