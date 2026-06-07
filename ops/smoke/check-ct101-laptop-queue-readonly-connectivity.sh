#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 to laptop queue read-only connectivity smoke ==="

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"
CT_TOKEN_FILE="${CT101_LAPTOP_QUEUE_TOKEN_FILE:-/opt/ai-platform/.secrets/laptop-queue.env}"
PORT="${LAPTOP_QUEUE_CT101_READONLY_SMOKE_PORT:-7102}"

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

if [ "${#TOKEN}" -lt 32 ]; then
  echo "FAIL: laptop queue token is too short"
  exit 1
fi

if command -v tailscale >/dev/null 2>&1; then
  LAPTOP_HOST="${LAPTOP_QUEUE_READONLY_HOST:-$(tailscale ip -4 | head -1)}"
else
  LAPTOP_HOST="${LAPTOP_QUEUE_READONLY_HOST:-$(hostname -I | awk '{print $1}')}"
fi

if [ -z "$LAPTOP_HOST" ]; then
  echo "FAIL: could not determine laptop host IP"
  exit 1
fi

echo "Using laptop queue smoke endpoint: http://$LAPTOP_HOST:$PORT"

LOG_FILE="/tmp/ct101-laptop-queue-readonly-smoke-$PORT.log"

export PAGER=cat
export PSQL_PAGER=cat

python -m uvicorn edge_controller:app --host 0.0.0.0 --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID="$!"

cleanup_server() {
  kill "$SERVER_PID" >/dev/null 2>&1 || true
  wait "$SERVER_PID" >/dev/null 2>&1 || true
}
trap cleanup_server EXIT

python3 - <<PY
import json
import time
import urllib.error
import urllib.request

base = "http://127.0.0.1:$PORT"
token = """$TOKEN"""

def request(token_value=None):
    headers = {}
    if token_value is not None:
        headers["X-Laptop-Queue-Token"] = token_value
    req = urllib.request.Request(base + "/internal/laptop-queue/summary", headers=headers, method="GET")
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
    status, body = request(token)
    last = (status, body)
    if status == 200:
        break
    time.sleep(0.25)
else:
    raise SystemExit(f"Laptop temporary queue API did not become ready: {last}")

assert last[1].get("ok") is True, last
print("OK: laptop temporary queue API is ready locally")
PY

TOKEN_B64="$(printf '%s' "$TOKEN" | base64 -w0)"

echo "Copying token to CT101 outside git: $CT_TOKEN_FILE"

ssh "$CT_SSH" "pct exec $CT_ID -- env TOKEN_B64='$TOKEN_B64' CT_TOKEN_FILE='$CT_TOKEN_FILE' bash -s" <<'REMOTE'
set -euo pipefail

mkdir -p "$(dirname "$CT_TOKEN_FILE")"
chmod 700 "$(dirname "$CT_TOKEN_FILE")"

TOKEN="$(printf '%s' "$TOKEN_B64" | base64 -d)"

cat > "$CT_TOKEN_FILE" <<EOF
# Laptop queue token for CT101 worker connectivity.
# Do not commit this file.
LAPTOP_QUEUE_INTERNAL_TOKEN=$TOKEN
EOF

chmod 600 "$CT_TOKEN_FILE"

test "$(stat -c '%a' "$CT_TOKEN_FILE")" = "600"
grep -q '^LAPTOP_QUEUE_INTERNAL_TOKEN=' "$CT_TOKEN_FILE"

echo "OK: CT101 token file exists with strict permissions"
REMOTE

echo "Calling laptop read-only queue summary from CT101"

ssh "$CT_SSH" "pct exec $CT_ID -- env LAPTOP_QUEUE_BASE_URL='http://$LAPTOP_HOST:$PORT' CT_TOKEN_FILE='$CT_TOKEN_FILE' bash -s" <<'REMOTE'
set -euo pipefail

set -a
source "$CT_TOKEN_FILE"
set +a

python3 - <<'PY'
import json
import os
import urllib.error
import urllib.request

base = os.environ["LAPTOP_QUEUE_BASE_URL"].rstrip("/")
token = os.environ["LAPTOP_QUEUE_INTERNAL_TOKEN"]

req = urllib.request.Request(
    base + "/internal/laptop-queue/summary",
    headers={"X-Laptop-Queue-Token": token},
    method="GET",
)

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode("utf-8")
        data = json.loads(body)
except urllib.error.HTTPError as exc:
    body = exc.read().decode("utf-8")
    raise SystemExit(f"FAIL: laptop summary HTTP {exc.code}: {body}") from exc
except Exception as exc:
    raise SystemExit(f"FAIL: could not reach laptop summary: {exc}") from exc

if data.get("ok") is not True:
    raise SystemExit(f"FAIL: summary response missing ok=true: {data}")

print("OK: CT101 reached laptop queue summary with token")
print("PASS: CT101 read-only laptop queue connectivity works")
PY
REMOTE

trap - EXIT
cleanup_server

echo "PASS: CT101 to laptop queue read-only connectivity smoke passed"
