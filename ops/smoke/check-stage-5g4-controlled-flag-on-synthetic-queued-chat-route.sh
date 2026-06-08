#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-4 controlled flag-on synthetic queued-chat route ==="

echo
echo "=== previous disabled guard smoke ==="
bash ops/smoke/check-stage-5g3-laptop-controller-queued-chat-disabled-guard.sh

echo
echo "=== existing synthetic route wiring smoke ==="
bash ops/smoke/check-synthetic-queued-chat-route-wiring.sh

echo
echo "=== frontend defaults and identity safety ==="
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi

echo "ok: frontend app.js has no forbidden identity references"

echo
echo "Stage 5G-4 controlled flag-on synthetic queued-chat route passed."
