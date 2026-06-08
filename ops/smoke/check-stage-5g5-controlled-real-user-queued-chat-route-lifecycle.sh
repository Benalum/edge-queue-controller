#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-5 controlled real-user queued-chat route lifecycle ==="

echo
echo "=== previous controlled synthetic route smoke ==="
bash ops/smoke/check-stage-5g4-controlled-flag-on-synthetic-queued-chat-route.sh

echo
echo "=== real-user queued chat guard helper ==="
bash ops/smoke/check-real-user-queued-chat-guard-helper.sh

echo
echo "=== real-user queued chat route creation ==="
bash ops/smoke/check-real-user-queued-chat-route-creation.sh

echo
echo "=== real-user queued chat status route ==="
bash ops/smoke/check-real-user-queued-chat-status-route.sh

echo
echo "=== frontend defaults and identity safety ==="
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi

echo "ok: frontend app.js has no forbidden identity references"

echo
echo "Stage 5G-5 controlled real-user queued-chat route lifecycle passed."
