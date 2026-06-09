#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-29 runtime restart persistence smoke ==="

source .venv/bin/activate 2>/dev/null || true

echo
echo "=== syntax and safety ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile edge_modules/chat_queue_real_user_creation.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G24_CT101_MANAGED_WORKER_STATUS_V1" edge_controller.py
grep -n "STAGE_5G26_NORMALIZED_WORKER_DETAIL_FIELD_V1" edge_controller.py
grep -n '"ct101-laptop-queue-worker"' frontend/wrapper-ui/app.js
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== restart controller on 0.0.0.0:7070 ==="
for pid in $(fuser -n tcp 7070 2>/dev/null || true); do
  echo "killing controller pid=$pid"
  kill -TERM "$pid" || true
done

sleep 2

for pid in $(fuser -n tcp 7070 2>/dev/null || true); do
  echo "force killing controller pid=$pid"
  kill -KILL "$pid" 2>/dev/null || true
done

: > /tmp/edge-controller-7070.log

nohup bash -lc '
cd "$HOME/Desktop/edge-queue-controller"
source .venv/bin/activate
set -a
source "$HOME/.config/ai-platform-controller/runtime/controller.env"
set +a
exec python -m uvicorn edge_controller:app --host 0.0.0.0 --port 7070
' > /tmp/edge-controller-7070.log 2>&1 &

controller_deadline=$((SECONDS + 45))
until curl -fsS http://127.0.0.1:7070/health >/tmp/stage5g29-controller-health.json 2>/dev/null; do
  if [ "$SECONDS" -ge "$controller_deadline" ]; then
    echo "FAIL: controller did not become healthy" >&2
    tail -n 120 /tmp/edge-controller-7070.log || true
    exit 1
  fi
  sleep 1
done

controller_listen="$(ss -ltnp | grep ':7070' || true)"
echo "$controller_listen"

if ! echo "$controller_listen" | grep -q '0.0.0.0:7070'; then
  echo "FAIL: controller must listen on 0.0.0.0:7070" >&2
  exit 1
fi

echo "ok: controller restarted and listening on 0.0.0.0:7070"

echo
echo "=== restart wrapper on 127.0.0.1:8787 ==="
for pid in $(fuser -n tcp 8787 2>/dev/null || true); do
  echo "killing wrapper pid=$pid"
  kill -TERM "$pid" || true
done

sleep 2

for pid in $(fuser -n tcp 8787 2>/dev/null || true); do
  echo "force killing wrapper pid=$pid"
  kill -KILL "$pid" 2>/dev/null || true
done

: > /tmp/wrapper-ui-8787.log

nohup bash -lc '
cd "$HOME/Desktop/edge-queue-controller/frontend/wrapper-ui"
source ../../.venv/bin/activate
set -a
source "$HOME/.config/ai-platform-controller/runtime/wrapper.env"
set +a
exec python "$PWD/dev_server.py"
' > /tmp/wrapper-ui-8787.log 2>&1 &

wrapper_deadline=$((SECONDS + 45))
until curl -fsS http://127.0.0.1:8787/api/system/status >/tmp/stage5g29-wrapper-status-before-worker.json 2>/dev/null; do
  if [ "$SECONDS" -ge "$wrapper_deadline" ]; then
    echo "FAIL: wrapper did not become healthy" >&2
    tail -n 120 /tmp/wrapper-ui-8787.log || true
    exit 1
  fi
  sleep 1
done

wrapper_listen="$(ss -ltnp | grep ':8787' || true)"
echo "$wrapper_listen"

if ! echo "$wrapper_listen" | grep -q '127.0.0.1:8787'; then
  echo "FAIL: wrapper must listen on 127.0.0.1:8787" >&2
  exit 1
fi

echo "ok: wrapper restarted and listening on 127.0.0.1:8787"

echo
echo "=== verify restarted process env ==="
ctrl_pid="$(fuser -n tcp 7070 2>/dev/null | awk '{print $1}' | head -1 || true)"
wrap_pid="$(fuser -n tcp 8787 2>/dev/null | awk '{print $1}' | head -1 || true)"

python3 - "$ctrl_pid" "$wrap_pid" <<'PY'
import sys

ctrl_pid, wrap_pid = sys.argv[1], sys.argv[2]

if not ctrl_pid:
    raise SystemExit("FAIL: missing controller pid")
if not wrap_pid:
    raise SystemExit("FAIL: missing wrapper pid")

def read_env(pid):
    raw = open(f"/proc/{pid}/environ", "rb").read().decode("utf-8", "ignore")
    env = {}
    for part in raw.split("\0"):
        if "=" in part:
            k, v = part.split("=", 1)
            env[k] = v
    return env

ctrl = read_env(ctrl_pid)
wrap = read_env(wrap_pid)

for key in ["LAPTOP_QUEUE_INTERNAL_TOKEN", "EDGE_PUBLIC_API_KEY", "EDGE_TRUSTED_PROXY_SECRET"]:
    if not ctrl.get(key):
        raise SystemExit(f"FAIL: controller env missing {key}")

if len(ctrl.get("LAPTOP_QUEUE_INTERNAL_TOKEN", "")) < 32:
    raise SystemExit("FAIL: controller LAPTOP_QUEUE_INTERNAL_TOKEN too short")

checks = {
    "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED": "1",
    "EDGE_CONTROLLER_URL": "http://127.0.0.1:7070",
}

for key, expected in checks.items():
    actual = wrap.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: wrapper env {key} expected {expected!r}, got {actual!r}")

for key in ["EDGE_TRUSTED_PROXY_SECRET", "CT101_FRONTEND", "CT101_API"]:
    if not wrap.get(key):
        raise SystemExit(f"FAIL: wrapper env missing {key}")

print("ok: restarted controller/wrapper env invariants")
PY

echo
echo "=== restart CT101 managed worker service ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

systemctl reset-failed ai-platform-laptop-queue-worker.service || true
systemctl daemon-reload
systemctl restart ai-platform-laptop-queue-worker.service

sleep 8

systemctl is-active ai-platform-laptop-queue-worker.service

journalctl -u ai-platform-laptop-queue-worker.service --no-pager -n 60 | tail -n 60

if ! journalctl -u ai-platform-laptop-queue-worker.service --no-pager -n 60 | grep -q 'managed laptop queue poller rc=0'; then
  echo "FAIL: no recent successful managed worker poller rc=0"
  exit 1
fi

echo "ok: CT101 managed worker restarted and polled successfully"
REMOTE

echo
echo "=== run Stage 5G-28 invariant smoke after restarts ==="
bash ops/smoke/check-stage-5g28-runtime-invariant-smoke.sh

echo
echo "=== recent queued jobs summary ==="
python3 - <<'PY'
from edge_modules.chat_queue_persistence import _psql_at

print(_psql_at("""
SELECT
  COALESCE(status, '') || E'\t' ||
  COUNT(*)::text
FROM app_jobs
WHERE job_type = 'ollama_chat'
GROUP BY status
ORDER BY status;
"""))
PY

echo
echo "Stage 5G-29 runtime restart persistence smoke passed."
