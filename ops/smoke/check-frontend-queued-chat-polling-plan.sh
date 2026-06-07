#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat polling plan static check ==="

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

require_file docs/frontend-queued-chat-polling-plan.md
require_file docs/real-user-queued-chat-rollback-offline.md
require_file docs/real-user-route-ct101-bounded-lifecycle.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/dev_server.py

require_fixed docs/frontend-queued-chat-polling-plan.md "planning only" "planning only"
require_fixed docs/frontend-queued-chat-polling-plan.md "does not change frontend runtime behavior" "no runtime frontend change"
require_fixed docs/frontend-queued-chat-polling-plan.md "preserve legacy/current chat behavior when queued chat is disabled" "legacy fallback"
require_fixed docs/frontend-queued-chat-polling-plan.md "show assistant placeholder state while job status is queued" "queued placeholder"
require_fixed docs/frontend-queued-chat-polling-plan.md "poll GET /api/chat/queued/{job_id}" "status polling"
require_fixed docs/frontend-queued-chat-polling-plan.md "avoid duplicate assistant messages" "duplicate prevention"
require_fixed docs/frontend-queued-chat-polling-plan.md "Frontend rollback must not create duplicate messages." "rollback duplicate safety"
require_fixed docs/frontend-queued-chat-polling-plan.md "The frontend must not send user_id." "no user id"
require_fixed docs/frontend-queued-chat-polling-plan.md "The frontend must not send X-Synthetic-User-Id in real-user mode." "no synthetic header"
require_fixed docs/frontend-queued-chat-polling-plan.md "Stage 5F-27 should add a disabled-by-default frontend queue status helper" "next stage"

echo "PASS: frontend queued chat polling plan markers are present"
