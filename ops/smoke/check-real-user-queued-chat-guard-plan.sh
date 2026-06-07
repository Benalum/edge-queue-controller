#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat guard plan static check ==="

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

require_file docs/real-user-queued-chat-guard-plan.md
require_file docs/synthetic-queued-chat-route-ct101-lifecycle.md
require_file docs/synthetic-queued-chat-route-wiring.md
require_file docs/synthetic-chat-assistant-message-persistence.md
require_file docs/chat-only-migration-map.md

require_fixed docs/real-user-queued-chat-guard-plan.md "planning only" "planning only"
require_fixed docs/real-user-queued-chat-guard-plan.md "No production chat behavior changes happen in this stage." "no production changes"
require_fixed docs/real-user-queued-chat-guard-plan.md "derive user_id from the authenticated session" "session-derived user"
require_fixed docs/real-user-queued-chat-guard-plan.md "reject any client-provided user_id" "reject client user id"
require_fixed docs/real-user-queued-chat-guard-plan.md "LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1" "real-user flag"
require_fixed docs/real-user-queued-chat-guard-plan.md "Enabling LAPTOP_CHAT_QUEUE_ENABLED alone must not be enough" "flag safety"
require_fixed docs/real-user-queued-chat-guard-plan.md "GET /api/chat/queued/{job_id} must only return jobs owned by the authenticated user." "status ownership"
require_fixed docs/real-user-queued-chat-guard-plan.md "POST /api/chat/queued must not accept X-Synthetic-User-Id in real-user mode." "no synthetic header real mode"
require_fixed docs/real-user-queued-chat-guard-plan.md "wrong-user chat reuse refused smoke" "wrong chat smoke"
require_fixed docs/real-user-queued-chat-guard-plan.md "wrong-user job status refused smoke" "wrong job smoke"
require_fixed docs/real-user-queued-chat-guard-plan.md "Stage 5F-12 should inspect the current wrapper auth/session helpers" "next stage"
require_fixed docs/real-user-queued-chat-guard-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/real-user-queued-chat-guard-plan.md "Do not:" "constraints present"
require_fixed docs/real-user-queued-chat-guard-plan.md "enable real-user queued chat" "do not enable"
require_fixed docs/real-user-queued-chat-guard-plan.md "create real production chat jobs" "no real jobs"

echo "PASS: real-user queued chat guard plan markers are present"
