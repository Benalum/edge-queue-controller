#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 bounded synthetic poller smoke ==="

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"
CT_TOKEN_FILE="${CT101_LAPTOP_QUEUE_TOKEN_FILE:-/opt/ai-platform/.secrets/laptop-queue.env}"
PORT="${LAPTOP_QUEUE_CT101_BOUNDED_POLLER_SMOKE_PORT:-7109}"
IDS_FILE="/tmp/ct101-laptop-queue-s5e19-ids-$PORT.json"

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
  LAPTOP_HOST="${LAPTOP_QUEUE_BOUNDED_POLLER_HOST:-$(tailscale ip -4 | head -1)}"
else
  LAPTOP_HOST="${LAPTOP_QUEUE_BOUNDED_POLLER_HOST:-$(hostname -I | awk '{print $1}')}"
fi

if [ -z "$LAPTOP_HOST" ]; then
  echo "FAIL: could not determine laptop host IP"
  exit 1
fi

BASE_URL="http://$LAPTOP_HOST:$PORT"
LOCAL_BASE_URL="http://127.0.0.1:$PORT"

echo "Using laptop queue smoke endpoint: $BASE_URL"

LOG_FILE="/tmp/ct101-bounded-poller-smoke-$PORT.log"

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
    print("OK: cleanup removed synthetic Stage 5E-19 rows")
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

TOKEN="$TOKEN" LOCAL_BASE_URL="$LOCAL_BASE_URL" IDS_FILE="$IDS_FILE" python3 - <<'PY'
import json
import os
import time
import urllib.error
import urllib.request

token = os.environ["TOKEN"]
base = os.environ["LOCAL_BASE_URL"].rstrip("/")
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
print("OK: laptop temporary queue API is ready locally")

suffix = f"s5e19-{int(time.time())}-{os.getpid()}"

status, setup = call(
    "POST",
    "/internal/laptop-queue/synthetic/setup",
    {
        "suffix": suffix,
        "job_type": "ollama_chat",
        "requested_model": "stage-5e19-synthetic-model",
    },
    token_value=token,
)

assert setup.get("ok") is True, setup
ids = setup["ids"]

with open(ids_file, "w", encoding="utf-8") as fh:
    json.dump(ids, fh)

print("OK: laptop API created synthetic jobs for bounded poller")
PY

TOKEN_B64="$(printf '%s' "$TOKEN" | base64 -w0)"
IDS_B64="$(base64 -w0 "$IDS_FILE")"

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
export PYTHONPATH="/opt/ai-platform/backend${PYTHONPATH:+:$PYTHONPATH}"

python3 -m py_compile \
  backend/app/worker/laptop_queue_client.py \
  ops/smoke/laptop_queue_bounded_synthetic_poller.py

bash ops/smoke/check-laptop-queue-bounded-synthetic-poller-static.sh

echo "OK: CT101 bounded synthetic poller script is present and valid"
REMOTE

echo "Running CT101 bounded synthetic poller"

ssh "$CT_SSH" "pct exec $CT_ID -- env LAPTOP_QUEUE_ENABLED='1' LAPTOP_QUEUE_SYNTHETIC_ONLY='1' LAPTOP_QUEUE_POLL_MODE='bounded' LAPTOP_QUEUE_BASE_URL='$BASE_URL' LAPTOP_QUEUE_TOKEN_FILE='$CT_TOKEN_FILE' IDS_B64='$IDS_B64' bash -s" <<'REMOTE'
set -euo pipefail

IDS_JSON="$(printf '%s' "$IDS_B64" | base64 -d)"
WORKER_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["worker_id"])' <<<"$IDS_JSON")"
NODE_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["node_id"])' <<<"$IDS_JSON")"

cd /opt/ai-platform
export PYTHONPATH="/opt/ai-platform/backend${PYTHONPATH:+:$PYTHONPATH}"

LAPTOP_QUEUE_WORKER_ID="$WORKER_ID" \
LAPTOP_QUEUE_WORKER_NODE_ID="$NODE_ID" \
LAPTOP_QUEUE_WORKER_NAME="Stage 5E-19 Bounded Synthetic Poller" \
LAPTOP_QUEUE_WORKER_NODE_NAME="Stage 5E-19 Synthetic Node" \
LAPTOP_QUEUE_JOB_TYPES="ollama_chat" \
LAPTOP_QUEUE_MAX_JOBS_PER_RUN="2" \
LAPTOP_QUEUE_POLL_INTERVAL_SECONDS="1" \
LAPTOP_QUEUE_MAX_IDLE_POLLS="1" \
python3 ops/smoke/laptop_queue_bounded_synthetic_poller.py
REMOTE

TOKEN="$TOKEN" LOCAL_BASE_URL="$LOCAL_BASE_URL" IDS_FILE="$IDS_FILE" python3 - <<'PY'
import json
import os

from edge_modules.laptop_queue import LaptopQueueClient

ids_file = os.environ["IDS_FILE"]

with open(ids_file, "r", encoding="utf-8") as fh:
    ids = json.load(fh)

worker_id = ids["worker_id"]
job_ids = ids["job_ids"]

client = LaptopQueueClient()

job_rows = client.psql_at(
    f"""
    SELECT string_agg(id || ':' || status || ':' || COALESCE(result_json->>'mode', ''), ',' ORDER BY id)
    FROM app_jobs
    WHERE id IN ({",".join("'" + job_id.replace("'", "''") + "'" for job_id in job_ids)});
    """
)

worker_state = client.psql_at(
    f"""
    SELECT status || '|' || COALESCE(current_job_id, '')
    FROM app_workers
    WHERE id = '{worker_id.replace("'", "''")}';
    """
)

if not job_rows:
    raise SystemExit("FAIL: no job rows found after bounded poller")

parts = job_rows.split(",")
if len(parts) != 2:
    raise SystemExit(f"FAIL: expected 2 job rows, got {job_rows}")

for part in parts:
    if ":complete:bounded_synthetic_poller" not in part:
        raise SystemExit(f"FAIL: bounded poller did not complete all jobs correctly: {job_rows}")

if worker_state != "idle|":
    raise SystemExit(f"FAIL: worker did not return idle: {worker_state}")

print("OK: bounded poller completed both synthetic jobs and returned worker idle")
PY

cleanup_synthetic
rm -f "$IDS_FILE"
trap - EXIT
cleanup_server

echo "PASS: CT101 bounded synthetic poller smoke passed"
