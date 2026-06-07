#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== session-derived user ownership map static check ==="

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

require_file docs/session-derived-user-ownership-inspection.md
require_file docs/session-derived-user-ownership-map.md
require_file docs/real-user-queued-chat-guard-plan.md
require_file edge_controller.py

require_fixed docs/session-derived-user-ownership-map.md "inspection and planning only" "planning only"
require_fixed docs/session-derived-user-ownership-map.md "No production chat behavior changes happen in this stage." "no production changes"
require_fixed docs/session-derived-user-ownership-map.md "derive user_id from the authenticated session" "session-derived user"
require_fixed docs/session-derived-user-ownership-map.md "must not trust" "do not trust client"
require_fixed docs/session-derived-user-ownership-map.md "X-Synthetic-User-Id in real-user mode" "no synthetic header real mode"
require_fixed docs/session-derived-user-ownership-map.md "verify app_chats.user_id before reusing chat_id" "chat ownership"
require_fixed docs/session-derived-user-ownership-map.md "return queued job status only if app_jobs.user_id matches authenticated_user_id" "job ownership"
require_fixed docs/session-derived-user-ownership-map.md "LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1" "real user flag"
require_fixed docs/session-derived-user-ownership-map.md "Synthetic mode remains test-only." "synthetic separation"
require_fixed docs/session-derived-user-ownership-map.md "Stage 5F-13 should add a disabled-by-default real-user auth guard helper." "next stage"
require_fixed docs/session-derived-user-ownership-map.md "Do not:" "constraints present"
require_fixed docs/session-derived-user-ownership-map.md "create real production chat jobs" "no real jobs"

require_fixed docs/session-derived-user-ownership-inspection.md "Auth/session/chat markers in edge_controller.py" "controller inspection"
require_fixed docs/session-derived-user-ownership-inspection.md "Queue and persistence helper markers" "helper inspection"

echo "PASS: session-derived user ownership map markers are present"
