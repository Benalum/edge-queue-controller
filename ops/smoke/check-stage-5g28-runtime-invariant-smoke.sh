#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-28 runtime invariant smoke ==="

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
echo "=== controller listener invariant ==="
controller_listen="$(ss -ltnp | grep ':7070' || true)"
echo "$controller_listen"

if ! echo "$controller_listen" | grep -q '0.0.0.0:7070'; then
  echo "FAIL: controller must listen on 0.0.0.0:7070 for CT101 access" >&2
  exit 1
fi

curl -fsS http://127.0.0.1:7070/health >/tmp/stage5g28-controller-health.json
echo "ok: controller health reachable"

echo
echo "=== controller env invariant ==="
ctrl_pid="$(fuser -n tcp 7070 2>/dev/null | awk '{print $1}' | head -1 || true)"
if [ -z "$ctrl_pid" ]; then
  echo "FAIL: could not find controller pid on 7070" >&2
  exit 1
fi

python3 - "$ctrl_pid" <<'PY'
import os
import sys

pid = sys.argv[1]
env_path = f"/proc/{pid}/environ"

raw = open(env_path, "rb").read().decode("utf-8", "ignore")
env = {}
for part in raw.split("\0"):
    if "=" in part:
        k, v = part.split("=", 1)
        env[k] = v

required = [
    "LAPTOP_QUEUE_INTERNAL_TOKEN",
    "EDGE_PUBLIC_API_KEY",
    "EDGE_TRUSTED_PROXY_SECRET",
]

for key in required:
    value = env.get(key, "")
    if not value:
        raise SystemExit(f"FAIL: controller env missing {key}")
    if key == "LAPTOP_QUEUE_INTERNAL_TOKEN" and len(value) < 32:
        raise SystemExit("FAIL: LAPTOP_QUEUE_INTERNAL_TOKEN too short")

print("ok: controller env keys present")
PY

echo
echo "=== wrapper listener/env invariant ==="
wrapper_listen="$(ss -ltnp | grep ':8787' || true)"
echo "$wrapper_listen"

if ! echo "$wrapper_listen" | grep -q '127.0.0.1:8787'; then
  echo "FAIL: wrapper must listen on 127.0.0.1:8787" >&2
  exit 1
fi

wrap_pid="$(fuser -n tcp 8787 2>/dev/null | awk '{print $1}' | head -1 || true)"
if [ -z "$wrap_pid" ]; then
  echo "FAIL: could not find wrapper pid on 8787" >&2
  exit 1
fi

python3 - "$wrap_pid" <<'PY'
import os
import sys

pid = sys.argv[1]
raw = open(f"/proc/{pid}/environ", "rb").read().decode("utf-8", "ignore")

env = {}
for part in raw.split("\0"):
    if "=" in part:
        k, v = part.split("=", 1)
        env[k] = v

checks = {
    "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED": "1",
    "EDGE_CONTROLLER_URL": "http://127.0.0.1:7070",
}

for key, expected in checks.items():
    actual = env.get(key)
    if actual != expected:
        raise SystemExit(f"FAIL: wrapper env {key} expected {expected!r}, got {actual!r}")

for key in ["EDGE_TRUSTED_PROXY_SECRET", "CT101_FRONTEND", "CT101_API"]:
    if not env.get(key):
        raise SystemExit(f"FAIL: wrapper env missing {key}")

print("ok: wrapper env bridge keys present")
PY

echo
echo "=== CT101 worker invariant ==="
LAPTOP_TS_IP="$(tailscale ip -4 | head -n 1)"
EXPECTED_BASE_URL="http://${LAPTOP_TS_IP}:7070"
echo "expected_base_url=$EXPECTED_BASE_URL"

ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<REMOTE
set -euo pipefail

EXPECTED_BASE_URL="${EXPECTED_BASE_URL}"

echo "--- CT101 worker env check ---"
test -f /etc/ai-platform/laptop-queue-worker.env
test -f /opt/ai-platform/.secrets/laptop-queue.env

source /etc/ai-platform/laptop-queue-worker.env

if [ "\${LAPTOP_QUEUE_ENABLED:-}" != "1" ]; then
  echo "FAIL: LAPTOP_QUEUE_ENABLED must be 1"
  exit 1
fi

if [ "\${LAPTOP_QUEUE_SYNTHETIC_ONLY:-}" != "0" ]; then
  echo "FAIL: LAPTOP_QUEUE_SYNTHETIC_ONLY must be 0"
  exit 1
fi

if [ "\${LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED:-}" != "1" ]; then
  echo "FAIL: LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED must be 1"
  exit 1
fi

if [ "\${LAPTOP_QUEUE_MAX_JOBS_PER_RUN:-}" != "1" ]; then
  echo "FAIL: LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1"
  exit 1
fi

if [ "\${LAPTOP_QUEUE_BASE_URL:-}" != "\$EXPECTED_BASE_URL" ]; then
  echo "FAIL: LAPTOP_QUEUE_BASE_URL expected \$EXPECTED_BASE_URL got \${LAPTOP_QUEUE_BASE_URL:-missing}"
  exit 1
fi

if [ "\${LAPTOP_QUEUE_TOKEN_FILE:-}" != "/opt/ai-platform/.secrets/laptop-queue.env" ]; then
  echo "FAIL: LAPTOP_QUEUE_TOKEN_FILE mismatch"
  exit 1
fi

token="\$(awk -F= '/^LAPTOP_QUEUE_INTERNAL_TOKEN=/{print \$2}' /opt/ai-platform/.secrets/laptop-queue.env | tail -1)"
if [ "\${#token}" -lt 32 ]; then
  echo "FAIL: LAPTOP_QUEUE_INTERNAL_TOKEN missing or too short"
  exit 1
fi

echo "ok: CT101 worker env/token invariants"

echo
echo "--- CT101 reachability to laptop controller ---"
curl -fsS --connect-timeout 5 "\$LAPTOP_QUEUE_BASE_URL/health" >/tmp/stage5g28-ct101-laptop-health.json
cat /tmp/stage5g28-ct101-laptop-health.json
echo
echo "ok: CT101 can reach laptop controller health"

echo
echo "--- CT101 managed worker service ---"
systemctl is-active ai-platform-laptop-queue-worker.service

echo
echo "--- CT101 worker recent healthy log ---"
journalctl -u ai-platform-laptop-queue-worker.service --no-pager -n 40 | tail -n 40

if ! journalctl -u ai-platform-laptop-queue-worker.service --no-pager -n 40 | grep -q 'managed laptop queue poller rc=0'; then
  echo "FAIL: no recent successful worker poller rc=0"
  exit 1
fi

echo "ok: CT101 managed worker recently polled successfully"
REMOTE

echo
echo "=== wrapper system status invariant ==="
curl -fsS http://127.0.0.1:8787/api/system/status -o /tmp/stage5g28-wrapper-status.json

python3 - <<'PY'
import json

data = json.load(open("/tmp/stage5g28-wrapper-status.json"))

item = next(
    (
        x for x in data.get("normalized", {}).get("platform", [])
        if x.get("id") == "ct101-laptop-queue-worker"
    ),
    None,
)

if not item:
    raise SystemExit("FAIL: wrapper normalized platform missing ct101-laptop-queue-worker")

print(json.dumps(item, indent=2))

if item.get("state") != "online":
    raise SystemExit(f"FAIL: worker expected online, got {item.get('state')!r}")

detail = item.get("detail") or ""
for needle in ["service: active", "preflight: ok", "paused: no", "model: gemma4:e4b", "max jobs/run: 1"]:
    if needle not in detail:
        raise SystemExit(f"FAIL: worker detail missing {needle!r}: {detail!r}")

print("ok: wrapper reports managed worker online")
PY

echo
echo "Stage 5G-28 runtime invariant smoke passed."
