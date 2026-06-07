#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop queue worker register/heartbeat smoke ==="

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
PORT="${LAPTOP_QUEUE_WORKER_HEARTBEAT_SMOKE_PORT:-7106}"
IDS_FILE="/tmp/laptop-queue-s5e15-ids-$PORT.json"

if [ ! -f "$LAPTOP_TOKEN_FILE" ]; then
  echo "FAIL: missing laptop token file: $LAPTOP_TOKEN_FILE"
  exit 1
fi

if [ "$(stat -c '%a' "$LAPTOP_TOKEN_FILE")" != "600" ]; then
  echo "FAIL: laptop token file must be chmod 600: $LAPTOP_TOKEN_FILE"
  exit 1
fi

TOKEN="$(awk -F= '/^LAPTOP_QUEUE_INTERNAL_TOKEN=/{print $2}' "$LAPTOP_TOKEN_FILE" | tail -1)"

if [ -z "$TOKEN" ]; then
  echo "FAIL: LAPTOP_QUEUE_INTERNAL_TOKEN missing from $LAPTOP_TOKEN_FILE"
  exit 1
fi

BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/laptop-queue-worker-heartbeat-smoke-$PORT.log"

export PAGER=cat
export PSQL_PAGER=cat

python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID="$!"

cleanup_synthetic() {
  if [ ! -f "$IDS_FILE" ]; then
    return 0
  fi

  TOKEN="$TOKEN" BASE_URL="$BASE_URL" IDS_FILE="$IDS_FILE" python3 - <<'PY' || true
import json
import os
import urllib.request

token = os.environ["TOKEN"]
base = os.environ["BASE_URL"].rstrip("/")
ids_file = os.environ["IDS_FILE"]

try:
    with open(ids_file, "r", encoding="utf-8") as fh:
        ids = json.load(fh)
except Exception:
    raise SystemExit(0)

payload = {
    "user_id": ids["user_id"],
    "node_id": ids["node_id"],
    "worker_id": ids["worker_id"],
    "job_ids": ids["job_ids"],
}

data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(
    base + "/internal/laptop-queue/synthetic/cleanup",
    data=data,
    headers={
        "Content-Type": "application/json",
        "X-Laptop-Queue-Token": token,
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        body = resp.read().decode("utf-8")
        parsed = json.loads(body) if body else {}
except Exception:
    raise SystemExit(0)

if parsed.get("ok") is True and parsed.get("leftover_count") == 0:
    print("OK: cleanup removed synthetic Stage 5E-15 rows")
PY

  rm -f "$IDS_FILE"
}

cleanup_server() {
  kill "$SERVER_PID" >/dev/null 2>&1 || true
  wait "$SERVER_PID" >/dev/null 2>&1 || true
}

cleanup_all() {
  cleanup_synthetic || true
  cleanup_server || true
}

trap cleanup_all EXIT

TOKEN="$TOKEN" BASE_URL="$BASE_URL" IDS_FILE="$IDS_FILE" python3 - <<'PY'
import json
import os
import time
import urllib.error
import urllib.request

token = os.environ["TOKEN"]
base = os.environ["BASE_URL"].rstrip("/")
ids_file = os.environ["IDS_FILE"]

def call(method, path, payload=None, token_value=None, expect_status=200):
    headers = {}
    data = None

    if token_value is not None:
        headers["X-Laptop-Queue-Token"] = token_value

    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(base + path, data=data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            status = resp.status
            parsed = json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8")
        status = exc.code
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
    except urllib.error.URLError as exc:
        return 0, {"error": str(exc)}

    if expect_status is not None and status != expect_status:
        raise AssertionError(f"{method} {path} expected {expect_status}, got {status}: {parsed}")

    return status, parsed

last = None
for _ in range(40):
    status, body = call("GET", "/internal/laptop-queue/summary", token_value=token, expect_status=None)
    last = (status, body)
    if status == 200:
        break
    time.sleep(0.25)
else:
    raise SystemExit(f"Laptop temporary queue API did not become ready: {last}")

assert last[1].get("ok") is True, last
print("OK: laptop temporary queue API is ready")

suffix = f"s5e15-{int(time.time())}-{os.getpid()}"

status, setup = call(
    "POST",
    "/internal/laptop-queue/synthetic/setup",
    {
        "suffix": suffix,
        "job_type": "ollama_chat",
        "requested_model": "stage-5e15-synthetic-model",
    },
    token_value=token,
)
assert setup.get("ok") is True, setup
ids = setup["ids"]

with open(ids_file, "w", encoding="utf-8") as fh:
    json.dump(ids, fh)

worker_id = ids["worker_id"]
node_id = ids["node_id"]
job_ok_id = ids["job_ok_id"]

status, register = call(
    "POST",
    "/internal/laptop-queue/workers/register",
    {
        "worker_id": worker_id,
        "name": "Stage 5E-15 Synthetic Worker",
        "worker_node_id": node_id,
        "node_name": "Stage 5E-15 Synthetic Node",
        "node_type": "synthetic",
        "host_machine": "laptop-controller-smoke",
        "tailscale_ip": "127.0.0.1",
        "capabilities": {"job_types": ["ollama_chat"], "stage": "5e15"},
        "idle_shutdown_seconds": 300,
        "status": "idle",
    },
    token_value=token,
)
assert register.get("ok") is True, register
assert register["worker"]["id"] == worker_id, register
assert register["worker"]["status"] == "idle", register
assert register["worker"]["worker_node_id"] == node_id, register
print("OK: synthetic worker registered idle")

status, heartbeat_idle = call(
    "POST",
    "/internal/laptop-queue/workers/heartbeat",
    {
        "worker_id": worker_id,
        "worker_node_id": node_id,
        "status": "idle",
        "current_job_id": None,
    },
    token_value=token,
)
assert heartbeat_idle.get("ok") is True, heartbeat_idle
assert heartbeat_idle["worker"]["status"] == "idle", heartbeat_idle
assert heartbeat_idle["worker"]["current_job_id"] is None, heartbeat_idle
print("OK: synthetic worker heartbeat idle")

status, claim = call(
    "POST",
    "/internal/laptop-queue/jobs/claim",
    {
        "worker_id": worker_id,
        "job_type": "ollama_chat",
    },
    token_value=token,
)
assert claim.get("ok") is True, claim
assert claim["job"]["id"] == job_ok_id, claim
assert claim["job"]["status"] == "running", claim
print("OK: synthetic worker claimed job")

status, heartbeat_busy = call(
    "POST",
    "/internal/laptop-queue/workers/heartbeat",
    {
        "worker_id": worker_id,
        "worker_node_id": node_id,
        "status": "busy",
        "current_job_id": job_ok_id,
    },
    token_value=token,
)
assert heartbeat_busy.get("ok") is True, heartbeat_busy
assert heartbeat_busy["worker"]["status"] == "busy", heartbeat_busy
assert heartbeat_busy["worker"]["current_job_id"] == job_ok_id, heartbeat_busy
print("OK: synthetic worker heartbeat busy with current job")

status, complete = call(
    "POST",
    f"/internal/laptop-queue/jobs/{job_ok_id}/complete",
    {
        "worker_id": worker_id,
        "ok": True,
        "result": {
            "reply": "stage 5e15 heartbeat synthetic reply",
            "model": "stage-5e15-synthetic-model",
        },
    },
    token_value=token,
)
assert complete.get("ok") is True, complete
assert complete["job"]["status"] == "complete", complete
print("OK: synthetic worker completed job")

status, heartbeat_idle_2 = call(
    "POST",
    "/internal/laptop-queue/workers/heartbeat",
    {
        "worker_id": worker_id,
        "worker_node_id": node_id,
        "status": "idle",
        "current_job_id": None,
    },
    token_value=token,
)
assert heartbeat_idle_2.get("ok") is True, heartbeat_idle_2
assert heartbeat_idle_2["worker"]["status"] == "idle", heartbeat_idle_2
assert heartbeat_idle_2["worker"]["current_job_id"] is None, heartbeat_idle_2
print("OK: synthetic worker heartbeat idle after completion")

status, cleanup = call(
    "POST",
    "/internal/laptop-queue/synthetic/cleanup",
    {
        "user_id": ids["user_id"],
        "node_id": node_id,
        "worker_id": worker_id,
        "job_ids": ids["job_ids"],
    },
    token_value=token,
)
assert cleanup.get("ok") is True, cleanup
assert cleanup.get("leftover_count") == 0, cleanup

try:
    os.remove(ids_file)
except FileNotFoundError:
    pass

print("PASS: laptop queue worker register/heartbeat smoke passed and cleaned up")
PY

trap - EXIT
cleanup_server
