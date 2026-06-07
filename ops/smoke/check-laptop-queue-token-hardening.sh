#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop queue internal API token hardening smoke ==="

source .venv/bin/activate 2>/dev/null || true

PORT="${LAPTOP_QUEUE_TOKEN_SMOKE_PORT:-7100}"
TOKEN="stage-5e5-token-$(date +%s)-$$"
BAD_TOKEN="bad-stage-5e5-token-$(date +%s)-$$"
LOG_FILE="/tmp/laptop-queue-token-smoke-$PORT.log"

export LAPTOP_QUEUE_INTERNAL_TOKEN="$TOKEN"
export PAGER=cat
export PSQL_PAGER=cat

python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID="$!"

cleanup_server() {
  kill "$SERVER_PID" >/dev/null 2>&1 || true
  wait "$SERVER_PID" >/dev/null 2>&1 || true
}
trap cleanup_server EXIT

python3 - <<PY
import json
import os
import time
import urllib.error
import urllib.request

port = int(os.environ.get("LAPTOP_QUEUE_TOKEN_SMOKE_PORT", "$PORT"))
token = os.environ["LAPTOP_QUEUE_INTERNAL_TOKEN"]
bad_token = "$BAD_TOKEN"
base = f"http://127.0.0.1:{port}"

def request(method, path, payload=None, token_value=None):
    data = None
    headers = {}

    if token_value is not None:
        headers["X-Laptop-Queue-Token"] = token_value

    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(
        base + path,
        data=data,
        headers=headers,
        method=method,
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return exc.code, parsed
    except urllib.error.URLError as exc:
        return 0, {"error": str(exc)}

# Wait for server to bind. Use a missing-token request because it should return 401 once ready.
last = None
for _ in range(40):
    status, body = request("GET", "/internal/laptop-queue/summary")
    last = (status, body)
    if status in {401, 403, 503, 200}:
        break
    time.sleep(0.25)
else:
    raise SystemExit(f"Server did not become ready: {last}")

status, body = request("GET", "/internal/laptop-queue/summary")
assert status == 401, (status, body)
print("OK: missing token rejected with 401")

status, body = request("GET", "/internal/laptop-queue/summary", token_value=bad_token)
assert status == 403, (status, body)
print("OK: wrong token rejected with 403")

status, body = request("GET", "/internal/laptop-queue/summary", token_value=token)
assert status == 200, (status, body)
assert body.get("ok") is True, body
print("OK: correct token accepted for summary")

suffix = f"{int(time.time())}-{os.getpid()}"

status, setup = request(
    "POST",
    "/internal/laptop-queue/synthetic/setup",
    {
        "suffix": suffix,
        "job_type": "ollama_chat",
        "requested_model": "stage-5e5-synthetic-model",
    },
    token_value=token,
)

assert status == 200, (status, setup)
assert setup.get("ok") is True, setup
ids = setup["ids"]
print("OK: correct token accepted for synthetic setup")

try:
    status, claim = request(
        "POST",
        "/internal/laptop-queue/jobs/claim",
        {"worker_id": ids["worker_id"], "job_type": "ollama_chat"},
        token_value=bad_token,
    )
    assert status == 403, (status, claim)
    print("OK: wrong token rejected for claim")

    status, claim = request(
        "POST",
        "/internal/laptop-queue/jobs/claim",
        {"worker_id": ids["worker_id"], "job_type": "ollama_chat"},
        token_value=token,
    )
    assert status == 200, (status, claim)
    assert claim.get("ok") is True, claim
    assert claim["job"]["id"] == ids["job_ok_id"], claim
    print("OK: correct token accepted for claim")

finally:
    status, cleanup = request(
        "POST",
        "/internal/laptop-queue/synthetic/cleanup",
        {
            "user_id": ids["user_id"],
            "node_id": ids["node_id"],
            "worker_id": ids["worker_id"],
            "job_ids": ids["job_ids"],
        },
        token_value=token,
    )
    assert status == 200, (status, cleanup)
    assert cleanup.get("ok") is True, cleanup
    assert cleanup.get("leftover_count") == 0, cleanup

print("PASS: laptop queue token hardening smoke passed and cleaned up")
PY

trap - EXIT
cleanup_server
