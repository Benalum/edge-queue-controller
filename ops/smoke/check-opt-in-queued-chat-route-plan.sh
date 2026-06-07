#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== opt-in queued chat route plan static check ==="

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

require_file docs/opt-in-queued-chat-route-plan.md
require_file docs/synthetic-chat-assistant-message-persistence.md
require_file docs/chat-only-migration-map.md
require_file docs/first-production-chat-migration-plan.md
require_file edge_modules/chat_queue_persistence.py

require_fixed docs/opt-in-queued-chat-route-plan.md "planning only" "planning only"
require_fixed docs/opt-in-queued-chat-route-plan.md "No production chat behavior changes happen in this stage." "no production changes"
require_fixed docs/opt-in-queued-chat-route-plan.md "LAPTOP_CHAT_QUEUE_ENABLED=1" "enabled flag"
require_fixed docs/opt-in-queued-chat-route-plan.md "Default must remain off." "default off"
require_fixed docs/opt-in-queued-chat-route-plan.md "POST /api/chat/queued" "future queued route"
require_fixed docs/opt-in-queued-chat-route-plan.md "The server must derive user_id from the authenticated session." "server-derived user"
require_fixed docs/opt-in-queued-chat-route-plan.md "Do not include cookies, tokens, secrets" "no secrets"
require_fixed docs/opt-in-queued-chat-route-plan.md "Failed jobs must not create assistant messages." "failed no assistant"
require_fixed docs/opt-in-queued-chat-route-plan.md "Duplicate persistence must return the existing assistant message." "duplicate persistence"
require_fixed docs/opt-in-queued-chat-route-plan.md "set LAPTOP_CHAT_QUEUE_ENABLED=0" "rollback flag"
require_fixed docs/opt-in-queued-chat-route-plan.md "server offline but job queued" "offline state"
require_fixed docs/opt-in-queued-chat-route-plan.md "Stage 5F-7 should inspect current wrapper chat routes" "next stage"
require_fixed docs/opt-in-queued-chat-route-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/opt-in-queued-chat-route-plan.md "Do not:" "constraints present"
require_fixed docs/opt-in-queued-chat-route-plan.md "change production chat behavior" "no production behavior change"
require_fixed docs/opt-in-queued-chat-route-plan.md "create real production chat jobs" "no real jobs"

echo "PASS: opt-in queued chat route plan markers are present"
