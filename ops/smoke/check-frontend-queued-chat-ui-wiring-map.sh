#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat UI wiring map static check ==="

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

require_file docs/frontend-queued-chat-ui-wiring-inspection.md
require_file docs/frontend-queued-chat-ui-wiring-map.md
require_file docs/frontend-queued-chat-polling-plan.md
require_file docs/frontend-queued-chat-status-helper.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/dev_server.py
require_file frontend/wrapper-ui/queued_chat_status.js

require_fixed docs/frontend-queued-chat-ui-wiring-map.md "inspection and planning only" "planning only"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "does not change frontend runtime behavior" "no frontend runtime change"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "does not import queued_chat_status.js" "not imported"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "Queued chat UI must be disabled by default." "disabled by default"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "preserve the current non-queued chat path when the flag is off" "preserve current chat path"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "POST to /api/chat/queued" "future POST"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "poll GET /api/chat/queued/{job_id}" "future polling"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "avoid duplicate assistant messages" "duplicate safety"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "The frontend must not send user_id." "no user id"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "The frontend must not send X-Synthetic-User-Id in real-user mode." "no synthetic header"
require_fixed docs/frontend-queued-chat-ui-wiring-map.md "Stage 5F-29 should import queued_chat_status.js in index.html" "next stage"

require_fixed docs/frontend-queued-chat-ui-wiring-inspection.md "Chat send/render/status markers in app.js" "app inspection"
require_fixed docs/frontend-queued-chat-ui-wiring-inspection.md "Chat markup/script markers in index.html" "html inspection"
require_fixed docs/frontend-queued-chat-ui-wiring-inspection.md "Dormant queued chat status helper markers" "helper inspection"

if grep -F -n "queued_chat_status.js" frontend/wrapper-ui/app.js frontend/wrapper-ui/index.html >/dev/null 2>&1; then
  echo "FAIL: queued_chat_status.js is imported before Stage 5F-29"
  exit 1
fi

echo "OK: queued_chat_status.js remains unimported"

echo "PASS: frontend queued chat UI wiring map markers are present"
