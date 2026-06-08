#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-23 managed worker startup safety checks ==="

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
echo "=== verify CT101 preflight and service ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

PREFLIGHT="/opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh"
SERVICE_FILE="/etc/systemd/system/ai-platform-laptop-queue-worker.service"
ENV_FILE="/etc/ai-platform/laptop-queue-worker.env"
CTL="/usr/local/bin/ai-platform-laptop-queue-workerctl"

test -x "$PREFLIGHT"
test -f "$SERVICE_FILE"
test -f "$ENV_FILE"
test -x "$CTL"

grep -n "ExecStartPre=/opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh" "$SERVICE_FILE"

grep -n "LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1" "$ENV_FILE"
grep -n "LAPTOP_QUEUE_SYNTHETIC_ONLY=0" "$ENV_FILE"
grep -n "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" "$ENV_FILE"
grep -n "LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK=gemma4:e4b" "$ENV_FILE"

/opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh

systemctl is-active --quiet ai-platform-laptop-queue-worker.service
"$CTL" status

echo
echo "=== negative preflight with bad laptop URL ==="
tmp_env=/tmp/stage5g23-bad-worker.env
cat "$ENV_FILE" > "$tmp_env"
sed -i "s#^LAPTOP_QUEUE_BASE_URL=.*#LAPTOP_QUEUE_BASE_URL=http://127.0.0.1:9#" "$tmp_env"

set +e
STAGE5G23_OVERRIDE_ENV_FILE="$tmp_env" "$PREFLIGHT"
rc=$?
set -e

rm -f "$tmp_env"

echo "negative_rc=$rc"

if [ "$rc" = "0" ]; then
  echo "FAIL: negative preflight unexpectedly passed" >&2
  exit 1
fi

echo "ok: negative preflight failed as expected"

systemctl is-active --quiet ai-platform-laptop-queue-worker.service

echo
echo "=== recent logs ==="
journalctl -u ai-platform-laptop-queue-worker.service --no-pager -n 80

echo
echo "ok: Stage 5G-23 CT101 startup safety checks verified"
REMOTE

echo
echo "Stage 5G-23 managed worker startup safety checks passed."
