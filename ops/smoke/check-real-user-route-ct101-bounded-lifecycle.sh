#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user route to CT101 bounded lifecycle smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

LAPTOP_TOKEN_FILE="${AI_PLATFORM_CONTROLLER_QUEUE_TOKEN_ENV:-$HOME/.config/ai-platform-controller/internal-queue.env}"
CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"
CT_TOKEN_FILE="${CT101_LAPTOP_QUEUE_TOKEN_FILE:-/opt/ai-platform/.secrets/laptop-queue.env}"
CT101_OLLAMA_BASE_URL="${CT101_OLLAMA_BASE_URL:-http://172.20.0.2:11434}"

PORT="${REAL_USER_ROUTE_CT101_LIFECYCLE_PORT:-7120}"
BASE_URL_LOCAL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f24-real-user-route-ct101-$PORT.log"
IDS_FILE="/tmp/s5f24-real-user-route-ct101-ids-$PORT.json"
IDS_CURRENT="/tmp/s5f24-real-user-route-ct101-ids-current.json"

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
  LAPTOP_HOST="${S5F24_LAPTOP_HOST:-$(tailscale ip -4 | head -1)}"
else
  LAPTOP_HOST="${S5F24_LAPTOP_HOST:-$(hostname -I | awk '{print $1}')}"
fi

if [ -z "$LAPTOP_HOST" ]; then
  echo "FAIL: could not determine laptop host IP"
  exit 1
fi

BASE_URL_CT101="http://$LAPTOP_HOST:$PORT"

echo "Using laptop route endpoint locally: $BASE_URL_LOCAL"
echo "Using laptop route endpoint from CT101: $BASE_URL_CT101"

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

require_file docs/real-user-route-ct101-bounded-lifecycle.md
require_file docs/ct101-bounded-real-user-poller-tracking.md
require_file edge_controller.py
require_file edge_modules/chat_queue_real_user_creation.py
require_file edge_modules/chat_queue_session_auth.py
require_file edge_modules/chat_queue_persistence.py

require_fixed docs/real-user-route-ct101-bounded-lifecycle.md "CT101 bounded one-shot poller claims the real-user-shaped queued job" "CT101 claim"
require_fixed docs/real-user-route-ct101-bounded-lifecycle.md "duplicate persistence returns the same assistant message" "idempotent persistence"
require_fixed docs/real-user-route-ct101-bounded-lifecycle.md "Persistent workers are not enabled." "no persistent workers"
require_fixed docs/real-user-route-ct101-bounded-lifecycle.md "Real-user queued chat remains disabled by default." "default disabled"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_real_user_creation.py \
  edge_modules/chat_queue_session_auth.py \
  edge_modules/chat_queue_real_user_guard.py \
  edge_modules/chat_queue_persistence.py

SERVER_PID=""

stop_server() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}

cleanup_rows() {
  python3 - <<PY || true
import json
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path("$IDS_CURRENT")
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_messages
    WHERE source_job_id IN (
      SELECT id FROM app_jobs
      WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])})
    )
       OR chat_id IN (
      SELECT id FROM app_chats
      WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])})
    );
    DELETE FROM app_jobs
    WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    DELETE FROM app_sessions
    WHERE id IN ({_sql_literal(ids['session_id'])}, {_sql_literal(ids['other_session_id'])});
    DELETE FROM app_chats
    WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    DELETE FROM app_users
    WHERE id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    DELETE FROM app_workers
    WHERE id = {_sql_literal(ids.get('worker_id', ''))};
    DELETE FROM app_worker_nodes
    WHERE id = {_sql_literal(ids.get('node_id', ''))};
    COMMIT;
    """
)

p.unlink(missing_ok=True)
PY
}

cleanup_all() {
  stop_server || true
  cleanup_rows || true
}

trap cleanup_all EXIT

python3 - <<'PY' > "$IDS_FILE"
import json
import os
import time

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

suffix = f"s5f24-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
session_id = f"{suffix}-session"
other_session_id = f"{suffix}-other-session"
token = f"{suffix}-token"
other_token = f"{suffix}-other-token"
worker_id = f"{suffix}-worker"
node_id = f"{suffix}-node"

_psql_run(
    f"""
    BEGIN;

    DELETE FROM app_messages
    WHERE chat_id IN (
      SELECT id FROM app_chats
      WHERE user_id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)})
    );
    DELETE FROM app_jobs
    WHERE user_id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
    DELETE FROM app_sessions
    WHERE id IN ({_sql_literal(session_id)}, {_sql_literal(other_session_id)});
    DELETE FROM app_chats
    WHERE user_id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
    DELETE FROM app_users
    WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
    DELETE FROM app_workers WHERE id = {_sql_literal(worker_id)};
    DELETE FROM app_worker_nodes WHERE id = {_sql_literal(node_id)};

    INSERT INTO app_users (
      id,
      email,
      password_hash,
      is_active,
      is_admin,
      created_at,
      updated_at
    )
    VALUES
      (
        {_sql_literal(user_id)},
        {_sql_literal(user_id + '@example.invalid')},
        'synthetic-smoke-password-hash',
        TRUE,
        FALSE,
        now(),
        now()
      ),
      (
        {_sql_literal(other_user_id)},
        {_sql_literal(other_user_id + '@example.invalid')},
        'synthetic-smoke-password-hash',
        TRUE,
        FALSE,
        now(),
        now()
      );

    INSERT INTO app_sessions (
      id,
      user_id,
      token_hash,
      created_at,
      expires_at,
      revoked_at
    )
    VALUES
      (
        {_sql_literal(session_id)},
        {_sql_literal(user_id)},
        {_sql_literal(hash_session_token(token))},
        now(),
        now() + interval '1 hour',
        NULL
      ),
      (
        {_sql_literal(other_session_id)},
        {_sql_literal(other_user_id)},
        {_sql_literal(hash_session_token(other_token))},
        now(),
        now() + interval '1 hour',
        NULL
      );

    COMMIT;
    """
)

print(json.dumps({
    "suffix": suffix,
    "user_id": user_id,
    "other_user_id": other_user_id,
    "session_id": session_id,
    "other_session_id": other_session_id,
    "token": token,
    "other_token": other_token,
    "worker_id": worker_id,
    "node_id": node_id,
}))
PY

cp "$IDS_FILE" "$IDS_CURRENT"

LAPTOP_CHAT_QUEUE_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1 \
env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
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

TOKEN_HEADER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"
OTHER_TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["other_token"])' "$IDS_FILE")"

created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$BASE_URL_LOCAL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN_HEADER" \
  -d "{\"message\":\"Reply with exactly: OK\",\"requested_model\":\"$OLLAMA_MODEL\"}")"

if [ "$created_code" != "200" ]; then
  echo "FAIL: queued route POST expected 200, got $created_code"
  cat "$created_body"
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"
CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chat_id"])' "$created_body")"
USER_MESSAGE_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_message_id"])' "$created_body")"

python3 - <<PY
import json
from pathlib import Path

p = Path("$IDS_FILE")
ids = json.loads(p.read_text())
ids["job_id"] = "$JOB_ID"
ids["chat_id"] = "$CHAT_ID"
ids["user_message_id"] = "$USER_MESSAGE_ID"
p.write_text(json.dumps(ids))
Path("$IDS_CURRENT").write_text(json.dumps(ids))
PY

echo "OK: route created real-user queued job $JOB_ID"

queued_body="$(mktemp)"
queued_code="$(curl -s -o "$queued_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $TOKEN_HEADER" \
  "$BASE_URL_LOCAL/api/chat/queued/$JOB_ID")"

if [ "$queued_code" != "200" ]; then
  echo "FAIL: queued status expected 200, got $queued_code"
  cat "$queued_body"
  exit 1
fi

grep -q '"status":"queued"' "$queued_body" || {
  echo "FAIL: queued status missing queued state"
  cat "$queued_body"
  exit 1
}

echo "OK: route status reports queued job"

wrong_status_body="$(mktemp)"
wrong_status_code="$(curl -s -o "$wrong_status_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $OTHER_TOKEN" \
  "$BASE_URL_LOCAL/api/chat/queued/$JOB_ID")"

if [ "$wrong_status_code" != "403" ]; then
  echo "FAIL: wrong-user status expected 403, got $wrong_status_code"
  cat "$wrong_status_body"
  exit 1
fi

echo "OK: wrong-user status lookup refused"

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

bash ops/smoke/check-laptop-queue-real-user-execution-guard.sh
bash ops/smoke/check-laptop-queue-bounded-real-user-poller-static.sh

echo "OK: CT101 bounded real-user poller is ready"
REMOTE

echo "Running CT101 bounded real-user Ollama poller"

ssh "$CT_SSH" "pct exec $CT_ID -- env LAPTOP_QUEUE_ENABLED='1' LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED='1' LAPTOP_QUEUE_POLL_MODE='bounded' LAPTOP_QUEUE_EXECUTION_MODE='ollama' LAPTOP_QUEUE_BASE_URL='$BASE_URL_CT101' LAPTOP_QUEUE_TOKEN_FILE='$CT_TOKEN_FILE' LAPTOP_QUEUE_OLLAMA_BASE_URL='$CT101_OLLAMA_BASE_URL' LAPTOP_QUEUE_OLLAMA_TIMEOUT_SECONDS='240' LAPTOP_QUEUE_OLLAMA_NUM_PREDICT='16' LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK='$OLLAMA_MODEL' IDS_B64='$IDS_B64' bash -s" <<'REMOTE'
set -euo pipefail

IDS_JSON="$(printf '%s' "$IDS_B64" | base64 -d)"
WORKER_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["worker_id"])' <<<"$IDS_JSON")"
NODE_ID="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["node_id"])' <<<"$IDS_JSON")"

cd /opt/ai-platform
export PYTHONPATH="/opt/ai-platform/backend${PYTHONPATH:+:$PYTHONPATH}"

env -u LAPTOP_QUEUE_SYNTHETIC_ONLY \
LAPTOP_QUEUE_WORKER_ID="$WORKER_ID" \
LAPTOP_QUEUE_WORKER_NODE_ID="$NODE_ID" \
LAPTOP_QUEUE_WORKER_NAME="Stage 5F-24 Real User Bounded Worker" \
LAPTOP_QUEUE_WORKER_NODE_NAME="Stage 5F-24 Real User Bounded Node" \
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
    _sql_literal,
    persist_assistant_message_for_completed_job,
)

ids = json.loads(Path("$IDS_FILE").read_text())
job_id = ids["job_id"]
user_id = ids["user_id"]

raw = _psql_at(
    f"""
    SELECT row_to_json(j)::text
    FROM (
      SELECT id, user_id, status, result_json, error_text
      FROM app_jobs
      WHERE id = {_sql_literal(job_id)}
        AND user_id = {_sql_literal(user_id)}
    ) j;
    """
)

if not raw:
    raise SystemExit("FAIL: real-user job missing after CT101 poller")

job = json.loads(raw)

if job["status"] != "complete":
    raise SystemExit(f"FAIL: real-user job did not complete: {job}")

result = job.get("result_json") or {}

if result.get("source") != "ct101_bounded_ollama_poller":
    raise SystemExit(f"FAIL: unexpected result source: {result}")

if not str(result.get("reply") or "").strip():
    raise SystemExit(f"FAIL: empty Ollama reply: {result}")

print("OK: CT101 completed real-user queued job")

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
    f"SELECT COUNT(*) FROM app_messages WHERE source_job_id = {_sql_literal(job_id)};"
)

if count != "1":
    raise SystemExit(f"FAIL: expected one assistant message, got {count}")

print("OK: assistant message persisted exactly once")
PY

complete_body="$(mktemp)"
complete_code="$(curl -s -o "$complete_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $TOKEN_HEADER" \
  "$BASE_URL_LOCAL/api/chat/queued/$JOB_ID")"

if [ "$complete_code" != "200" ]; then
  echo "FAIL: complete status expected 200, got $complete_code"
  cat "$complete_body"
  exit 1
fi

grep -q '"status":"complete"' "$complete_body" || {
  echo "FAIL: complete status missing complete state"
  cat "$complete_body"
  exit 1
}

echo "OK: route status reports completed real-user job"

cleanup_all
trap - EXIT

echo "PASS: real-user route to CT101 bounded lifecycle smoke passed"
