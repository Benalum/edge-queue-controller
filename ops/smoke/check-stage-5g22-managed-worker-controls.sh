#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-22 managed worker controls verification ==="

source .venv/bin/activate 2>/dev/null || true

echo
echo "=== syntax and frontend safety ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile edge_modules/chat_queue_real_user_creation.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G18_DEFAULT_MODEL_ALIAS_RESOLVER_V1" edge_modules/chat_queue_real_user_creation.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== verify CT101 control command, pause-aware loop, and service ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

CTL="/usr/local/bin/ai-platform-laptop-queue-workerctl"
LOOP="/opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh"
PAUSE_FILE="/etc/ai-platform/laptop-queue-worker.paused"
SERVICE="ai-platform-laptop-queue-worker.service"

test -x "$CTL"
test -x "$LOOP"
grep -n "PAUSE_FILE" "$LOOP"
grep -n "managed laptop queue worker paused" "$LOOP"

systemctl is-active --quiet "$SERVICE"

"$CTL" status

echo
echo "=== pause ==="
"$CTL" pause stage5g22-verification-pause
sleep 8

echo
echo "=== status while paused ==="
"$CTL" status
test -f "$PAUSE_FILE"
grep -q "stage5g22-verification-pause" "$PAUSE_FILE"

echo
echo "=== paused logs ==="
"$CTL" logs 160 | grep -i "managed laptop queue worker paused" | tail -n 10

echo
echo "=== resume ==="
"$CTL" resume
sleep 8

echo
echo "=== status after resume ==="
"$CTL" status
test ! -f "$PAUSE_FILE"

echo
echo "=== post-resume logs ==="
"$CTL" logs 120 | tail -n 60

echo
echo "ok: CT101 managed worker controls verified"
REMOTE

echo
echo "Stage 5G-22 managed worker controls verification passed."
