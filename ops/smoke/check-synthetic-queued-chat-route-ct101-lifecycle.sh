#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== synthetic queued chat route to CT101 lifecycle smoke ==="

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"
CT_TOKEN_FILE="${CT101_LAPTOP_QUEUE_TOKEN_FILE:-/opt/ai-platform/.secrets/laptop-queue.env}"
CT101_OLLAMA_BASE_URL="${CT101_OLLAMA_BASE_URL:-http://172.20.0.2:11434}"

PORT="${SYNTHETIC_QUEUED_CHAT_LIFECYCLE_PORT:-7114}"
BASE_URL_LOCAL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f10-route-ct101-lifecycle-$PORT.log"
IDS_FILE="/tmp/s5f10-route-ct101-lifecycle-ids-$PORT.json"

if [ ! -f "$LAPTOP_TOKEN_FILE" ]; then
  echo "FAIL: missing laptop queue token file: $LAPTOP_TOKEN_FILE"
  exit 1
fi

TOKEN="$(awk -F= '/^LAPTOP_QUEUE_INTERNAL_TOKEN=/{print $2}' "$LAPTOP_TOKEN_FILE" | tail -1)"

if [ -z "$TOKEN" ]; then
  echo "FAIL: LAPTOP_QUEUE_INTERNAL_TOKEN missing from $LAPTOP_TOKEN_FILE"
  exit 1
fi

if command -v tailscale >/dev/null 2>&1; then
  LAPTOP_HOST="${S5F10_LAPTOP_HOST:-$(tailscale ip -4 | head -1)}"
else
  LAPTOP_HOST="${S5F10_LAPTOP_HOST:-$(hostname -I | awk '{print $1}')}"
fi

if [ -z "$LAPTOP_HOST" ]; then
  echo "FAIL: could not determine laptop host IP"
  exit 1
fi

BASE_URL_CT101="http://$LAPTOP_HOST:$PORT"

echo "Using laptop route endpoint locally: $BASE_URL_LOCAL"
echo "Using laptop route endpoint from CT101: $BASE_URL_CT101"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_creation.py \
  edge_modules/chat_queue_persistence.py

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_fixed() {
  local file="$1"
  local text="$2"
  local label="$3"

  if grep -F -n "$text" "$file" >/dev/null 2>&1; then
    echo "OK: $label"
  else
    echo "FAIL: missing $label"
    echo "  file: $file"
    echo "  text: $text"
    exit 1
  fi
}

require_file docs/synthetic-queued-chat-route-ct101-lifecycle.md
require_file edge_modules/chat_queue_creation.py
require_file edge_modules/chat_queue_persistence.py
require_file ops/smoke/check-synthetic-queued-chat-route-wiring.sh

require_fixed docs/synthetic-queued-chat-route-ct101-lifecycle.md "POST /api/chat/queued creates a queued app_jobs row" "route creates job"
require_fixed docs/synthetic-queued-chat-route-ct101-lifecycle.md "CT101 bounded Ollama poller claims the queued job" "CT101 claim"
require_fixed docs/synthetic-queued-chat-route-ct101-lifecycle.md "laptop persists one assistant message" "assistant persistence"
require_fixed docs/synthetic-queued-chat-route-ct101-lifecycle.md "duplicate persistence returns the same assistant message" "duplicate idempotency"
require_fixed docs/synthetic-queued-chat-route-ct101-lifecycle.md "does not change default production chat behavior" "no production default change"

SERVER_PID=""

stop_server() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}

cleanup_rows() {
  if [ -f "$IDS_FILE" ]; then
    python3 - <<'PY' || true
import json
from pathlib import Path

from edge_modules.chat_queue_creation import cleanup_synthetic_chat_queue_creation_rows
from edge_modules.chat_queue_persistence import _psql_run

ids_path = Path("/tmp/s5f10-route-ct101-lifecycle-ids-current.json")
if not ids_path.exists():
    raise SystemExit(0)

ids = json.loads(ids_path.read_text())
suffix = ids.get("suffix")
if suffix:
    cleanup_synthetic_chat_queue_creation_rows(suffix=suffix)

worker_id = ids.get("worker_id", "")
node_id = ids.get("node_id", "")

if worker_id or node_id:
    _psql_run(
        f"""
        BEGIN;
        DELETE FROM app_workers WHERE id = '{worker_id.replace("'", "''")}';
        DELETE FROM app_worker_nodes WHERE id = '{node_id.replace("'", "''")}';
        COMMIT;
        """
    )
PY
    rm -f "$IDS_FILE" /tmp/s5f10-route-ct101-lifecycle-ids-current.json
  fi
}

cleanup_all() {
  cleanup_rows || true
  stop_server || true
}

trap cleanup_all EXIT

LAPTOP_CHAT_QUEUE_ENABLED=1 LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1 \
  python -m uvicorn edge_controller:app --host 0.0.0.0 --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID="$!"

for _ in $(seq 1 40); do
  if curl -s "$BASE_URL_LOCAL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

echo "OK: temporary laptop/controller API started"

OLLAMA_MODEL="$(ssh "$CT_SSH" "pct exec $CT_ID -- env CT101_OLLAMA_BASE_URL='$CT101_OLLAMA_BASE_URL' python3 - <<'PY'
import json
import os
import urllib.request

base_url = os.environ.get('CT101_OLLAMA_BASE_URL', 'http://172.20.0.2:11434').rstrip('/')

try:
    with urllib.request.urlopen(base_url + '/api/tags', timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
except Exception as exc:
    raise SystemExit(f'FAIL: could not query Ollama tags at {base_url}: {exc}')

models = data.get('models') or []
if not models:
    raise SystemExit(f'FAIL: no Ollama models available at {base_url}')

print(models[0].get('name') or models[0].get('model') or '')
PY
")"

if [ -z "$OLLAMA_MODEL" ]; then
  echo "FAIL: could not determine CT101 Ollama model"
  exit 1
fi

echo "Using CT101 Ollama model: $OLLAMA_MODEL"

python3 - <<'PY' > "$IDS_FILE"
import json
import os
import time

from edge_modules.chat_queue_creation import setup_synthetic_chat_queue_creation_rows

suffix = f"s5f10-{int(time.time())}-{os.getpid()}"
ids = setup_synthetic_chat_queue_creation_rows(suffix=suffix)
ids["suffix"] = suffix
ids["worker_id"] = f"s5f10-worker-{suffix}"
ids["node_id"] = f"s5f10-node-{suffix}"
print(json.dumps(ids))
PY

cp "$IDS_FILE" /tmp/s5f10-route-ct101-lifecycle-ids-current.json

SYNTHETIC_USER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_id"])' "$IDS_FILE")"
WORKER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["worker_id"])' "$IDS_FILE")"
NODE_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node_id"])' "$IDS_FILE")"

created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$BASE_URL_LOCAL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Synthetic-User-Id: $SYNTHETIC_USER_ID" \
  -d "{\"message\":\"Reply with exactly: OK\",\"requested_model\":\"$OLLAMA_MODEL\"}")"

if [ "$created_code" != "200" ]; then
  echo "FAIL: queued route POST expected 200, got $created_code"
  cat "$created_body"
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"
CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chat_id"])' "$created_body")"
USER_MESSAGE_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_message_id"])' "$created_body")"

echo "OK: route created queued job $JOB_ID"

python3 - <<PY
import json
from pathlib import Path

ids = json.loads(Path("$IDS_FILE").read_text())
ids["job_id"] = "$JOB_ID"
ids["chat_id"] = "$CHAT_ID"
ids["user_message_id"] = "$USER_MESSAGE_ID"
Path("$IDS_FILE").write_text(json.dumps(ids))
Path("/tmp/s5f10-route-ct101-lifecycle-ids-current.json").write_text(json.dumps(ids))
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

cd /opt/ai-platform
export PYTHONPATH="/opt/ai-platform/backend${PYTHONPATH:+:$PYTHONPATH}"

python3 -m py_compile \
  backend/app/worker/laptop_queue_client.py \
  ops/smoke/laptop_queue_bounded_synthetic_poller.py

bash ops/smoke/check-laptop-queue-bounded-ollama-poller-static.sh

echo "OK: CT101 bounded Ollama poller is ready"
REMOTE

echo "Running CT101 bounded Ollama poller for route-created job"

ssh "$CT_SSH" "pct exec $CT_ID -- env LAPTOP_QUEUE_ENABLED='1' LAPTOP_QUEUE_SYNTHETIC_ONLY='1' LAPTOP_QUEUE_SYNTHETIC_PREFIXES='s5e,synthetic,s5f8-job-' LAPTOP_QUEUE_POLL_MODE='bounded' LAPTOP_QUEUE_EXECUTION_MODE='ollama' LAPTOP_QUEUE_BASE_URL='$BASE_URL_CT101' LAPTOP_QUEUE_TOKEN_FILE='$CT_TOKEN_FILE' LAPTOP_QUEUE_OLLAMA_BASE_URL='$CT101_OLLAMA_BASE_URL' LAPTOP_QUEUE_OLLAMA_TIMEOUT_SECONDS='240' LAPTOP_QUEUE_OLLAMA_NUM_PREDICT='8' LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK='$OLLAMA_MODEL' IDS_B64='$IDS_B64' bash -s" <<'REMOTE'
set -euo pipefail

IDS_JSON="$(printf '%s' "$IDS_B64" | base64 -d)"
WORKER_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["worker_id"])' <<<"$IDS_JSON")"
NODE_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["node_id"])' <<<"$IDS_JSON")"

cd /opt/ai-platform
export PYTHONPATH="/opt/ai-platform/backend${PYTHONPATH:+:$PYTHONPATH}"

LAPTOP_QUEUE_WORKER_ID="$WORKER_ID" \
LAPTOP_QUEUE_WORKER_NODE_ID="$NODE_ID" \
LAPTOP_QUEUE_WORKER_NAME="Stage 5F-10 Route Lifecycle Worker" \
LAPTOP_QUEUE_WORKER_NODE_NAME="Stage 5F-10 Route Lifecycle Node" \
LAPTOP_QUEUE_JOB_TYPES="ollama_chat" \
LAPTOP_QUEUE_MAX_JOBS_PER_RUN="1" \
LAPTOP_QUEUE_POLL_INTERVAL_SECONDS="1" \
LAPTOP_QUEUE_MAX_IDLE_POLLS="1" \
python3 ops/smoke/laptop_queue_bounded_synthetic_poller.py
REMOTE

python3 - <<PY
import json
from pathlib import Path

from edge_modules.chat_queue_persistence import (
    _psql_at,
    persist_assistant_message_for_completed_job,
)

ids = json.loads(Path("$IDS_FILE").read_text())
job_id = ids["job_id"]
user_id = ids["user_id"]

raw = _psql_at(
    f"""
    SELECT row_to_json(j)::text
    FROM (
      SELECT id, status, result_json, error_text
      FROM app_jobs
      WHERE id = '{job_id.replace("'", "''")}'
    ) j;
    """
)

if not raw:
    raise SystemExit("FAIL: route-created job missing after CT101 poller")

job = json.loads(raw)

if job["status"] != "complete":
    raise SystemExit(f"FAIL: route-created job did not complete: {job}")

result = job.get("result_json") or {}

if result.get("source") != "ct101_bounded_ollama_poller":
    raise SystemExit(f"FAIL: unexpected result source: {result}")

if not str(result.get("reply") or "").strip():
    raise SystemExit(f"FAIL: empty Ollama reply: {result}")

print("OK: CT101 completed route-created queued job")

first = persist_assistant_message_for_completed_job(
    job_id=job_id,
    authenticated_user_id=user_id,
)

second = persist_assistant_message_for_completed_job(
    job_id=job_id,
    authenticated_user_id=user_id,
)

if first.id != second.id:
    raise SystemExit(f"FAIL: duplicate persistence created different messages: {first} {second}")

count = _psql_at(
    f"SELECT COUNT(*) FROM app_messages WHERE source_job_id = '{job_id.replace("'", "''")}';"
)

if count != "1":
    raise SystemExit(f"FAIL: expected one assistant message, got {count}")

print("OK: assistant message persisted exactly once")
PY

status_body="$(mktemp)"
status_code="$(curl -s -o "$status_body" -w "%{http_code}" "$BASE_URL_LOCAL/api/chat/queued/$JOB_ID")"

if [ "$status_code" != "200" ]; then
  echo "FAIL: queued route GET expected 200, got $status_code"
  cat "$status_body"
  exit 1
fi

grep -q '"status":"complete"' "$status_body" || {
  echo "FAIL: queued route GET missing complete status"
  cat "$status_body"
  exit 1
}

echo "OK: route status reports completed job"

cleanup_all
trap - EXIT

echo "PASS: synthetic queued chat route to CT101 lifecycle smoke passed"
