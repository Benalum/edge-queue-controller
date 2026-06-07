#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 worker token prep smoke ==="

TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "FAIL: missing token file: $TOKEN_FILE"
  exit 1
fi

if [ "$(stat -c '%a' "$TOKEN_FILE")" != "600" ]; then
  echo "FAIL: token file must be chmod 600: $TOKEN_FILE"
  exit 1
fi

TOKEN="$(awk -F= '/^LAPTOP_QUEUE_INTERNAL_TOKEN=/{print $2}' "$TOKEN_FILE" | tail -1)"

if [ -z "$TOKEN" ]; then
  echo "FAIL: LAPTOP_QUEUE_INTERNAL_TOKEN missing from $TOKEN_FILE"
  exit 1
fi

if [ "${#TOKEN}" -lt 32 ]; then
  echo "FAIL: token is too short"
  exit 1
fi

# Verify token value is not committed or present in tracked project files.
# Do not print the token.
if grep -RIl --exclude-dir=.git --exclude-dir=.venv --exclude-dir=__pycache__ --exclude='*.pyc' "$TOKEN" . >/dev/null 2>&1; then
  echo "FAIL: token value appears inside the repository"
  exit 1
fi

echo "OK: token file exists, permissions are strict, and token is outside repo"

source .venv/bin/activate 2>/dev/null || true

PORT="${LAPTOP_QUEUE_TOKEN_FILE_SMOKE_PORT:-7101}"
LOG_FILE="/tmp/laptop-queue-token-file-smoke-$PORT.log"

export PAGER=cat
export PSQL_PAGER=cat

# Start without LAPTOP_QUEUE_INTERNAL_TOKEN in the environment.
# The app must load the token from ~/.config/ai-platform-controller/internal-queue.env.
env -u LAPTOP_QUEUE_INTERNAL_TOKEN \
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

port = int(os.environ.get("LAPTOP_QUEUE_TOKEN_FILE_SMOKE_PORT", "$PORT"))
token = """$TOKEN"""
base = f"http://127.0.0.1:{port}"

def request(method, path, token_value=None):
    headers = {}
    if token_value is not None:
        headers["X-Laptop-Queue-Token"] = token_value

    req = urllib.request.Request(
        base + path,
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
print("OK: missing token rejected while file token is configured")

status, body = request("GET", "/internal/laptop-queue/summary", token_value="wrong-token")
assert status == 403, (status, body)
print("OK: wrong token rejected while file token is configured")

status, body = request("GET", "/internal/laptop-queue/summary", token_value=token)
assert status == 200, (status, body)
assert body.get("ok") is True, body
print("OK: correct file token accepted")

print("PASS: CT101 worker token prep smoke passed")
PY

trap - EXIT
cleanup_server
