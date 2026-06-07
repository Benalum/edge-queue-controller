#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 laptop queue one-shot worker smoke ==="

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"
CT_TOKEN_FILE="${CT101_LAPTOP_QUEUE_TOKEN_FILE:-/opt/ai-platform/.secrets/laptop-queue.env}"
PORT="${LAPTOP_QUEUE_CT101_ONESHOT_SMOKE_PORT:-7104}"
IDS_FILE="/tmp/ct101-laptop-queue-s5e10-ids-$PORT.json"

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

if command -v tailscale >/dev/null 2>&1; then
  LAPTOP_HOST="${LAPTOP_QUEUE_ONESHOT_HOST:-$(tailscale ip -4 | head -1)}"
else
  LAPTOP_HOST="${LAPTOP_QUEUE_ONESHOT_HOST:-$(hostname -I | awk '{print $1}')}"
fi

if [ -z "$LAPTOP_HOST" ]; then
  echo "FAIL: could not determine laptop host IP"
  exit 1
fi

BASE_URL="http://$LAPTOP_HOST:$PORT"
LOCAL_BASE_URL="http://127.0.0.1:$PORT"

echo "Using laptop queue smoke endpoint: $BASE_URL"

LOG_FILE="/tmp/ct101-laptop-queue-oneshot-smoke-$PORT.log"

export PAGER=cat
export PSQL_PAGER=cat

python -m uvicorn edge_controller:app --host 0.0.0.0 --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID="$!"

cleanup_synthetic() {
  if [ ! -f "$IDS_FILE" ]; then
    return 0
  fi

  TOKEN="$TOKEN" LOCAL_BASE_URL="$LOCAL_BASE_URL" IDS_FILE="$IDS_FILE" python3 - <<'PY' || true
import json
import os
import urllib.request

token = os.environ["TOKEN"]
base = os.environ["LOCAL_BASE_URL"].rstrip("/")
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
    print("OK: cleanup removed synthetic Stage 5E-10 rows")
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

python3 - <<PY
import json
import time
import urllib.error
import urllib.request

base = "$LOCAL_BASE_URL"
token = """$TOKEN"""

def request(method, path, payload=None, token_value=None):
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
    status, body = request("GET", "/internal/laptop-queue/summary", token_value=token)
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

cd /opt/ai-platform
python3 -m py_compile ops/smoke/laptop_queue_one_shot_worker.py
bash ops/smoke/check-laptop-queue-one-shot-worker-static.sh

echo "OK: CT101 one-shot worker script is present and valid"
REMOTE

TOKEN="$TOKEN" LOCAL_BASE_URL="$LOCAL_BASE_URL" IDS_FILE="$IDS_FILE" python3 - <<'PY'
import json
import os
import time
import urllib.error
import urllib.request

token = os.environ["TOKEN"]
base = os.environ["LOCAL_BASE_URL"].rstrip("/")
ids_file = os.environ["IDS_FILE"]

suffix = f"s5e10-{int(time.time())}-{os.getpid()}"

payload = {
    "suffix": suffix,
    "job_type": "ollama_chat",
    "requested_model": "stage-5e10-synthetic-model",
}

data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(
    base + "/internal/laptop-queue/synthetic/setup",
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
        parsed = json.loads(body)
except urllib.error.HTTPError as exc:
    body = exc.read().decode("utf-8")
    raise SystemExit(f"FAIL: synthetic setup HTTP {exc.code}: {body}") from exc

if parsed.get("ok") is not True:
    raise SystemExit(f"FAIL: synthetic setup failed: {parsed}")

ids = parsed["ids"]

with open(ids_file, "w", encoding="utf-8") as fh:
    json.dump(ids, fh)

print("OK: laptop API created synthetic jobs for one-shot worker")
PY

IDS_B64="$(base64 -w0 "$IDS_FILE")"

echo "Running CT101 one-shot worker success path"

ssh "$CT_SSH" "pct exec $CT_ID -- env LAPTOP_QUEUE_ENABLED='1' LAPTOP_QUEUE_SYNTHETIC_ONLY='1' LAPTOP_QUEUE_BASE_URL='$BASE_URL' LAPTOP_QUEUE_TOKEN_FILE='$CT_TOKEN_FILE' IDS_B64='$IDS_B64' bash -s" <<'REMOTE'
set -euo pipefail

IDS_JSON="$(printf '%s' "$IDS_B64" | base64 -d)"
WORKER_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["worker_id"])' <<<"$IDS_JSON")"

cd /opt/ai-platform

LAPTOP_QUEUE_WORKER_ID="$WORKER_ID" \
LAPTOP_QUEUE_JOB_TYPE="ollama_chat" \
LAPTOP_QUEUE_ONE_SHOT_RESULT="success" \
python3 ops/smoke/laptop_queue_one_shot_worker.py
REMOTE

echo "Running CT101 one-shot worker failure path"

ssh "$CT_SSH" "pct exec $CT_ID -- env LAPTOP_QUEUE_ENABLED='1' LAPTOP_QUEUE_SYNTHETIC_ONLY='1' LAPTOP_QUEUE_BASE_URL='$BASE_URL' LAPTOP_QUEUE_TOKEN_FILE='$CT_TOKEN_FILE' IDS_B64='$IDS_B64' bash -s" <<'REMOTE'
set -euo pipefail

IDS_JSON="$(printf '%s' "$IDS_B64" | base64 -d)"
WORKER_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["worker_id"])' <<<"$IDS_JSON")"

cd /opt/ai-platform

LAPTOP_QUEUE_WORKER_ID="$WORKER_ID" \
LAPTOP_QUEUE_JOB_TYPE="ollama_chat" \
LAPTOP_QUEUE_ONE_SHOT_RESULT="failure" \
python3 ops/smoke/laptop_queue_one_shot_worker.py
REMOTE

cleanup_synthetic
rm -f "$IDS_FILE"
trap - EXIT
cleanup_server

echo "PASS: CT101 laptop queue one-shot worker smoke passed"
