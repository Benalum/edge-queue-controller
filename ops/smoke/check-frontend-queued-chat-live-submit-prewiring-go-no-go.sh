#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat live-submit pre-wiring go/no-go static check ==="

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

require_file docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md
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
require_file docs/real-user-route-ct101-bounded-lifecycle.md
require_file docs/real-user-queued-chat-rollback-offline.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "planning and static verification only" "planning/static only"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "does not modify app.js" "does not modify app"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "does not wire queued chat into the real submit handler" "no submit wiring"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "does not enable queued chat by default" "default disabled"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "AI_PLATFORM_QUEUED_CHAT_ENABLED defaults false" "flag default go criterion"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "flag-off live submit path is unchanged" "flag off unchanged"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "live app.js outside isolated helpers does not call queued helpers" "no live helper calls"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "live app.js outside isolated helpers does not call /api/chat/queued" "no live queued API"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "app.js does not reference user_id" "no user_id"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "guardedLiveSubmitGateWired remains false before live wiring" "gate remains false"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "duplicate queued POST protection is not proven" "no-go duplicate POST"
require_fixed docs/frontend-queued-chat-live-submit-prewiring-go-no-go.md "Stage 5F-69 should add the first guarded live-submit branch skeleton" "next stage"

require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "frontend queued flag default false"

require_fixed frontend/wrapper-ui/app.js "Stage 5F-43: queued-chat submit insertion guard marker." "5F-43 submit marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-57: guarded queued submit branch skeleton marker." "5F-57 guarded marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-60: guarded live-submit branch marker." "5F-60 live-submit marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-63: guarded live-submit gate marker." "5F-63 gate marker"

require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH" "guarded gate branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH" "guarded live submit branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH" "guarded skeleton branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH" "orchestration branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH" "payload branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH" "send branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH" "poll branch exists"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH" "placeholder branch exists"

require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitGateWired: false" "guarded gate not wired"
require_fixed frontend/wrapper-ui/app.js "guardedLiveSubmitWired: false" "guarded live submit not wired"
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
    ("guarded readiness live call", r"AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH[.]buildGuardedLiveSubmitReadiness\s*\("),
    ("guarded skeleton live call", r"AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH[.]buildGuardedQueuedSubmitSkeleton\s*\("),
    ("orchestration live call", r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH[.]runQueuedChatSubmitOrchestration\s*\("),
    ("payload builder live call", r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH[.]buildQueuedChatSubmitPayload\s*\("),
    ("dry-run live call", r"AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH[.]buildQueuedChatSubmitDryRun\s*\("),
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

required_markers = [
    "Stage 5F-43: queued-chat submit insertion guard marker.",
    "Stage 5F-57: guarded queued submit branch skeleton marker.",
    "Stage 5F-60: guarded live-submit branch marker.",
    "Stage 5F-63: guarded live-submit gate marker.",
]

for marker in required_markers:
    if marker not in live_text:
        print(f"FAIL: missing marker in live text: {marker}")
        sys.exit(1)

lines = live_text.splitlines()
submit_marker = "Stage 5F-63: guarded live-submit gate marker."
submit_marker_line = next((i for i, line in enumerate(lines, 1) if submit_marker in line), None)

if submit_marker_line is None:
    print("FAIL: Stage 5F-63 marker line missing")
    sys.exit(1)

nearby = "\n".join(lines[submit_marker_line - 1:min(len(lines), submit_marker_line + 180)])
anchors = [
    'addEventListener("submit"',
    "addEventListener('submit'",
    "handleChatSubmit",
    "sendChatMessage",
    "sendMessage",
    "Stage 5F-60: guarded live-submit branch marker.",
    "Stage 5F-57: guarded queued submit branch skeleton marker.",
]

if not any(anchor in nearby for anchor in anchors):
    print("FAIL: Stage 5F-63 marker is not near live submit/send anchor")
    print(f"marker_line={submit_marker_line}")
    sys.exit(1)

print("OK: no queued submit helpers are called from live paths")
print("OK: no /api/chat/queued call exists in live paths")
print("OK: go/no-go live submit markers remain near submit path")
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

echo "PASS: frontend queued chat live-submit pre-wiring go/no-go markers are present"
