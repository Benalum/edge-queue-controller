#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop queue internal API smoke ==="

source .venv/bin/activate 2>/dev/null || true

PORT="${LAPTOP_QUEUE_API_SMOKE_PORT:-7099}"
TOKEN="stage-5e4-token-$(date +%s)-$$"
LOG_FILE="/tmp/laptop-queue-api-smoke-$PORT.log"

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

port = int(os.environ.get("LAPTOP_QUEUE_API_SMOKE_PORT", "$PORT"))
token = os.environ["LAPTOP_QUEUE_INTERNAL_TOKEN"]
base = f"http://127.0.0.1:{port}"

def call(method, path, payload=None, expect_ok=True):
    data = None
    headers = {"X-Laptop-Queue-Token": token}

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
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8")
        if expect_ok:
            raise AssertionError(f"{method} {path} failed HTTP {exc.code}: {body}") from exc
        return {"status": exc.code, "body": body}

# Wait for temp Uvicorn server to import app and bind.
last_error = None
for _ in range(40):
    try:
        summary = call("GET", "/internal/laptop-queue/summary")
        assert summary.get("ok") is True, summary
        break
    except Exception as exc:
        last_error = exc
        time.sleep(0.25)
else:
    raise SystemExit(f"Server did not become ready: {last_error}")

suffix = f"{int(time.time())}-{os.getpid()}"

setup = call(
    "POST",
    "/internal/laptop-queue/synthetic/setup",
    {
        "suffix": suffix,
        "job_type": "ollama_chat",
        "requested_model": "stage-5e4-synthetic-model",
    },
)

assert setup.get("ok") is True, setup
ids = setup["ids"]
worker_id = ids["worker_id"]
job_ok_id = ids["job_ok_id"]
job_fail_id = ids["job_fail_id"]

try:
    claim_ok = call(
        "POST",
        "/internal/laptop-queue/jobs/claim",
        {"worker_id": worker_id, "job_type": "ollama_chat"},
    )
    assert claim_ok.get("ok") is True, claim_ok
    assert claim_ok["job"]["id"] == job_ok_id, claim_ok
    assert claim_ok["job"]["status"] == "running", claim_ok
    print("OK: internal API claimed success job")

    complete_ok = call(
        "POST",
        f"/internal/laptop-queue/jobs/{job_ok_id}/complete",
        {
            "worker_id": worker_id,
            "ok": True,
            "result": {
                "reply": "stage 5e4 synthetic reply",
                "model": "stage-5e4-synthetic-model",
            },
        },
    )
    assert complete_ok.get("ok") is True, complete_ok
    assert complete_ok["job"]["status"] == "complete", complete_ok
    assert complete_ok["job"]["result_json"]["reply"] == "stage 5e4 synthetic reply", complete_ok
    print("OK: internal API completed success job")

    claim_fail = call(
        "POST",
        "/internal/laptop-queue/jobs/claim",
        {"worker_id": worker_id, "job_type": "ollama_chat"},
    )
    assert claim_fail.get("ok") is True, claim_fail
    assert claim_fail["job"]["id"] == job_fail_id, claim_fail
    assert claim_fail["job"]["status"] == "running", claim_fail
    print("OK: internal API claimed failure job")

    complete_fail = call(
        "POST",
        f"/internal/laptop-queue/jobs/{job_fail_id}/complete",
        {
            "worker_id": worker_id,
            "ok": False,
            "error_text": "stage 5e4 synthetic failure",
        },
    )
    assert complete_fail.get("ok") is True, complete_fail
    assert complete_fail["job"]["status"] == "failed", complete_fail
    assert complete_fail["job"]["error_text"] == "stage 5e4 synthetic failure", complete_fail
    print("OK: internal API failed failure job")

finally:
    cleanup = call(
        "POST",
        "/internal/laptop-queue/synthetic/cleanup",
        {
            "user_id": ids["user_id"],
            "node_id": ids["node_id"],
            "worker_id": worker_id,
            "job_ids": ids["job_ids"],
        },
    )
    assert cleanup.get("ok") is True, cleanup
    assert cleanup.get("leftover_count") == 0, cleanup

print("PASS: laptop queue internal API smoke passed and cleaned up")
PY

trap - EXIT
cleanup_server
