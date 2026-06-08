#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-11 CT101 bridge real-worker lifecycle readiness ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"
CT101_API_HEALTH_URL="${CT101_API_HEALTH_URL:-http://100.88.245.33:8088/health}"

echo
echo "=== checkpoint safety ==="
git status --short
git rev-parse --short HEAD
git tag --points-at HEAD | grep -F "controller-stage-5g10-ct101-compatible-completed-queued-assistant-message-2026-06-08"

echo
echo "=== syntax and feature defaults ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js
node --check frontend/wrapper-ui/queued_chat_status.js

grep -n 'WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED = os.getenv("WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED", "")' frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G9_CT101_QUEUED_CHAT_BRIDGE_V1" frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G10_CT101_COMPAT_ASSISTANT_MESSAGE_V1" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== CT101 reachability ==="
ssh -o BatchMode=yes -o ConnectTimeout=5 "$CT_SSH" "pct status $CT_ID >/dev/null"
ssh "$CT_SSH" "pct exec $CT_ID -- bash -lc 'curl -fsS \"$CT101_API_HEALTH_URL\" >/dev/null'"

echo "ok: CT101 reachable and API health candidate works: $CT101_API_HEALTH_URL"

echo
echo "=== proof 1: CT101-shaped bridge completed compatibility ==="
bash ops/smoke/check-stage-5g10-ct101-compatible-completed-queued-assistant-message.sh

echo
echo "=== proof 2: real-user route to CT101 bounded worker lifecycle ==="
bash ops/smoke/check-real-user-route-ct101-bounded-lifecycle.sh

echo
echo "=== proof 3: assistant persistence remains idempotent ==="
bash ops/smoke/check-synthetic-chat-assistant-message-persistence.sh

echo
echo "Stage 5G-11 CT101 bridge real-worker lifecycle readiness passed."
