#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== queued chat session auth resolver map static check ==="

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

require_file docs/queued-chat-session-auth-resolver-inspection.md
require_file docs/queued-chat-session-auth-resolver-map.md
require_file docs/session-derived-user-ownership-map.md
require_file docs/real-user-queued-chat-route-guard-placeholder.md
require_file edge_controller.py

require_fixed docs/queued-chat-session-auth-resolver-map.md "inspection and planning only" "planning only"
require_fixed docs/queued-chat-session-auth-resolver-map.md "No production chat behavior changes happen in this stage." "no production changes"
require_fixed docs/queued-chat-session-auth-resolver-map.md "derive authenticated_user_id server-side" "server-side user"
require_fixed docs/queued-chat-session-auth-resolver-map.md "reject anonymous requests" "anonymous refused"
require_fixed docs/queued-chat-session-auth-resolver-map.md "reject expired sessions" "expired refused"
require_fixed docs/queued-chat-session-auth-resolver-map.md "reject revoked sessions" "revoked refused"
require_fixed docs/queued-chat-session-auth-resolver-map.md "never trust client-provided user_id" "no client user id"
require_fixed docs/queued-chat-session-auth-resolver-map.md "never trust X-Synthetic-User-Id in real-user mode" "no synthetic header real mode"
require_fixed docs/queued-chat-session-auth-resolver-map.md "LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1" "real-user flag"
require_fixed docs/queued-chat-session-auth-resolver-map.md "session_auth_not_wired_stage_5f14" "placeholder remains"
require_fixed docs/queued-chat-session-auth-resolver-map.md "Stage 5F-16 should add a disabled helper" "next stage"
require_fixed docs/queued-chat-session-auth-resolver-map.md "Do not:" "constraints present"
require_fixed docs/queued-chat-session-auth-resolver-map.md "create real production chat jobs" "no real jobs"
require_fixed docs/queued-chat-session-auth-resolver-inspection.md "Candidate auth/session resolver markers" "auth inspection"
require_fixed docs/queued-chat-session-auth-resolver-inspection.md "Queued chat route markers" "route inspection"

echo "PASS: queued chat session auth resolver map markers are present"
