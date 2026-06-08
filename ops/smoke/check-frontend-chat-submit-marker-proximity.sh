#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend chat submit marker proximity smoke ==="

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

require_file docs/frontend-chat-submit-marker-proximity.md
require_file docs/frontend-chat-submit-insertion-marker.md
require_file docs/frontend-chat-submit-handler-insertion-map.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-chat-submit-marker-proximity.md "static verification only" "static only"
require_fixed docs/frontend-chat-submit-marker-proximity.md "does not change frontend runtime behavior" "no runtime change"
require_fixed docs/frontend-chat-submit-marker-proximity.md "does not wire queued chat into submit" "no submit wiring"
require_fixed docs/frontend-chat-submit-marker-proximity.md "Stage 5F-45 should add a disabled-by-default real submit decision dry-run helper" "next stage"

require_fixed frontend/wrapper-ui/app.js "Stage 5F-43: queued-chat submit insertion guard marker." "stage marker"
require_fixed frontend/wrapper-ui/app.js "Stage 5F-43 is marker-only." "marker only"
require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH" "decision branch exists"
require_fixed frontend/wrapper-ui/app.js "decisionWired: false" "decision still not wired"
require_fixed frontend/wrapper-ui/app.js "wiredToSubmit: false" "send still not wired"
require_fixed frontend/wrapper-ui/app.js "pollerWired: false" "poller still not wired"
require_fixed frontend/wrapper-ui/app.js "placeholderWired: false" "placeholder still not wired"

python3 - <<'PY'
from pathlib import Path
import sys

text = Path("frontend/wrapper-ui/app.js").read_text()
lines = text.splitlines()

marker = "Stage 5F-43: queued-chat submit insertion guard marker."
marker_lines = [i for i, line in enumerate(lines, 1) if marker in line]

if len(marker_lines) != 1:
    print(f"FAIL: expected exactly one Stage 5F-43 marker, found {len(marker_lines)}")
    sys.exit(1)

marker_line = marker_lines[0]

anchors = [
    'addEventListener("submit"',
    "addEventListener('submit'",
    "handleChatSubmit",
    "sendChatMessage",
    "sendMessage",
]

window_start = marker_line
window_end = min(len(lines), marker_line + 80)
window = "\n".join(lines[window_start - 1:window_end])

found = [anchor for anchor in anchors if anchor in window]

if not found:
    print("FAIL: Stage 5F-43 marker is not near a submit/send anchor within 80 lines")
    print(f"marker_line={marker_line}")
    print("--- nearby lines ---")
    for i in range(max(1, marker_line - 10), min(len(lines), marker_line + 90) + 1):
        print(f"{i}: {lines[i-1]}")
    sys.exit(1)

print(f"OK: Stage 5F-43 marker is near submit/send anchor(s): {', '.join(found)}")
PY

call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$call_count" != "0" ]; then
  echo "FAIL: submit decision helper should not be called yet"
  grep -nE 'AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH[.]shouldUseQueuedChatForSubmit[[:space:]]*\(' frontend/wrapper-ui/app.js || true
  exit 1
fi

echo "OK: submit decision helper is not called"

send_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH[.]sendQueuedChat[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$send_call_count" != "0" ]; then
  echo "FAIL: queued send helper should not be called by submit yet"
  exit 1
fi

echo "OK: queued send helper is not called"

poll_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH[.]pollQueuedChatStatus[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$poll_call_count" != "0" ]; then
  echo "FAIL: queued poll helper should not be called yet"
  exit 1
fi

echo "OK: queued poll helper is not called"

placeholder_call_count="$( (grep -Eo 'AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH[.]buildQueuedAssistantPlaceholder[[:space:]]*\(' frontend/wrapper-ui/app.js || true) | wc -l | tr -d ' ' )"

if [ "$placeholder_call_count" != "0" ]; then
  echo "FAIL: queued placeholder helper should not be called yet"
  exit 1
fi

echo "OK: queued placeholder helper is not called"

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

echo "PASS: frontend chat submit marker proximity smoke passed"
