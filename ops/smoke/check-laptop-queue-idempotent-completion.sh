#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop queue idempotent completion smoke ==="

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
PORT="${LAPTOP_QUEUE_IDEMPOTENT_SMOKE_PORT:-7108}"
IDS_FILE="/tmp/laptop-queue-s5e17-ids-$PORT.json"

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
LOG_FILE="/tmp/laptop-queue-idempotent-smoke-$PORT.log"

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
    print("OK: cleanup removed synthetic Stage 5E-17 rows")
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

from edge_modules.laptop_queue import LaptopQueueClient

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

suffix = f"s5e17-{int(time.time())}-{os.getpid()}"

status, setup = call(
    "POST",
    "/internal/laptop-queue/synthetic/setup",
    {
        "suffix": suffix,
        "job_type": "ollama_chat",
        "requested_model": "stage-5e17-synthetic-model",
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
job_fail_id = ids["job_fail_id"]

status, register = call(
    "POST",
    "/internal/laptop-queue/workers/register",
    {
        "worker_id": worker_id,
        "name": "Stage 5E-17 Synthetic Worker",
        "worker_node_id": node_id,
        "node_name": "Stage 5E-17 Synthetic Node",
        "node_type": "synthetic",
        "host_machine": "laptop-controller-smoke",
        "tailscale_ip": "127.0.0.1",
        "capabilities": {"job_types": ["ollama_chat"], "stage": "5e17"},
        "idle_shutdown_seconds": 300,
        "status": "idle",
    },
    token_value=token,
)
assert register.get("ok") is True, register

status, claim_ok = call(
    "POST",
    "/internal/laptop-queue/jobs/claim",
    {"worker_id": worker_id, "job_type": "ollama_chat"},
    token_value=token,
)
assert claim_ok.get("ok") is True, claim_ok
assert claim_ok["job"]["id"] == job_ok_id, claim_ok
assert claim_ok["job"]["status"] == "running", claim_ok
print("OK: synthetic success job claimed")

status, complete_ok = call(
    "POST",
    f"/internal/laptop-queue/jobs/{job_ok_id}/complete",
    {
        "worker_id": worker_id,
        "ok": True,
        "result": {
            "reply": "stage 5e17 original success",
            "model": "stage-5e17-synthetic-model",
        },
    },
    token_value=token,
)
assert complete_ok.get("ok") is True, complete_ok
assert complete_ok["job"]["status"] == "complete", complete_ok
assert complete_ok["job"]["result_json"]["reply"] == "stage 5e17 original success", complete_ok
original_finished_at = complete_ok["job"]["finished_at"]
original_updated_at = complete_ok["job"]["updated_at"]
print("OK: first success completion worked")

time.sleep(1)

status, duplicate_ok = call(
    "POST",
    f"/internal/laptop-queue/jobs/{job_ok_id}/complete",
    {
        "worker_id": worker_id,
        "ok": True,
        "result": {
            "reply": "stage 5e17 duplicate should not overwrite",
            "model": "stage-5e17-synthetic-model",
        },
    },
    token_value=token,
)
assert duplicate_ok.get("ok") is True, duplicate_ok
assert duplicate_ok["job"]["status"] == "complete", duplicate_ok
assert duplicate_ok["job"]["result_json"]["reply"] == "stage 5e17 original success", duplicate_ok
assert duplicate_ok["job"]["finished_at"] == original_finished_at, duplicate_ok
assert duplicate_ok["job"]["updated_at"] == original_updated_at, duplicate_ok
print("OK: duplicate success returned existing complete row without mutation")

status, late_failure = call(
    "POST",
    f"/internal/laptop-queue/jobs/{job_ok_id}/complete",
    {
        "worker_id": worker_id,
        "ok": False,
        "error_text": "stage 5e17 late failure should be rejected",
    },
    token_value=token,
    expect_status=None,
)
assert status == 500, (status, late_failure)
print("OK: late failure after success rejected")

status, claim_fail = call(
    "POST",
    "/internal/laptop-queue/jobs/claim",
    {"worker_id": worker_id, "job_type": "ollama_chat"},
    token_value=token,
)
assert claim_fail.get("ok") is True, claim_fail
assert claim_fail["job"]["id"] == job_fail_id, claim_fail
assert claim_fail["job"]["status"] == "running", claim_fail
print("OK: synthetic recovery job claimed")

status, heartbeat_busy = call(
    "POST",
    "/internal/laptop-queue/workers/heartbeat",
    {
        "worker_id": worker_id,
        "worker_node_id": node_id,
        "status": "busy",
        "current_job_id": job_fail_id,
    },
    token_value=token,
)
assert heartbeat_busy.get("ok") is True, heartbeat_busy

client = LaptopQueueClient()
client.psql_run(
    f"""
    UPDATE app_workers
    SET last_heartbeat_at = now() - interval '10 minutes',
        updated_at = now() - interval '10 minutes'
    WHERE id = '{worker_id}';

    UPDATE app_jobs
    SET started_at = now() - interval '10 minutes',
        updated_at = now() - interval '10 minutes'
    WHERE id = '{job_fail_id}';
    """
)

status, recovery = call(
    "POST",
    "/internal/laptop-queue/recover",
    {
        "stale_seconds": 60,
        "fail_stuck_jobs": True,
        "synthetic_prefixes": ["s5e"],
    },
    token_value=token,
)
assert recovery.get("ok") is True, recovery
assert job_fail_id in recovery["recovery"]["failed_job_ids"], recovery
print("OK: recovery failed stale running job")

status, late_success = call(
    "POST",
    f"/internal/laptop-queue/jobs/{job_fail_id}/complete",
    {
        "worker_id": worker_id,
        "ok": True,
        "result": {
            "reply": "stage 5e17 late success should be rejected",
            "model": "stage-5e17-synthetic-model",
        },
    },
    token_value=token,
    expect_status=None,
)
assert status == 500, (status, late_success)
print("OK: late success after recovered failure rejected")

status, duplicate_failure = call(
    "POST",
    f"/internal/laptop-queue/jobs/{job_fail_id}/complete",
    {
        "worker_id": worker_id,
        "ok": False,
        "error_text": "stage 5e17 duplicate failure should not overwrite",
    },
    token_value=token,
)
assert duplicate_failure.get("ok") is True, duplicate_failure
assert duplicate_failure["job"]["status"] == "failed", duplicate_failure
assert duplicate_failure["job"]["error_text"] == "Recovered by Stage 5E-16: assigned worker heartbeat stale", duplicate_failure
print("OK: duplicate failure returned existing failed row without mutation")

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

print("PASS: laptop queue idempotent completion smoke passed and cleaned up")
PY

trap - EXIT
cleanup_server
