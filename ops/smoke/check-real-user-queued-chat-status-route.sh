#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat status route smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

PORT="${REAL_USER_QUEUED_CHAT_STATUS_ROUTE_PORT:-7119}"
BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f20-real-user-status-route-$PORT.log"
IDS_FILE="/tmp/s5f20-real-user-status-route-ids-$PORT.json"

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

require_file docs/real-user-queued-chat-status-route.md
require_file edge_controller.py
require_file edge_modules/chat_queue_real_user_creation.py
require_file edge_modules/chat_queue_session_auth.py
require_file edge_modules/chat_queue_real_user_guard.py

require_fixed edge_controller.py "stage_5f20_real_user_status_route" "status route source marker"
require_fixed edge_controller.py "queued_chat_status_session_auth_failed_stage_5f20" "status auth failure marker"
require_fixed edge_controller.py "queued_chat_status_ownership_failed_stage_5f20" "status ownership failure marker"
require_fixed docs/real-user-queued-chat-status-route.md "does not call CT101" "no CT101"
require_fixed docs/real-user-queued-chat-status-route.md "does not persist assistant messages" "no assistant persistence"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_real_user_creation.py \
  edge_modules/chat_queue_session_auth.py \
  edge_modules/chat_queue_real_user_guard.py \
  edge_modules/chat_queue_persistence.py

python3 - <<'PY' > "$IDS_FILE"
import json
import os
import time

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

suffix = f"s5f20-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
session_id = f"{suffix}-session"
other_session_id = f"{suffix}-other-session"
token = f"{suffix}-token"
other_token = f"{suffix}-other-token"

_psql_run(
    f"""
    BEGIN;

    DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
    DELETE FROM app_messages WHERE chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id IN ({_sql_literal(session_id)}, {_sql_literal(other_session_id)});
    DELETE FROM app_chats WHERE id LIKE 's5f18-chat-%';
    DELETE FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});

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
}))
PY

SERVER_PID=""

cleanup_rows() {
  python3 - <<'PY' || true
import json
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path("/tmp/s5f20-real-user-status-route-ids-current.json")
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    DELETE FROM app_messages WHERE chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id IN ({_sql_literal(ids['session_id'])}, {_sql_literal(ids['other_session_id'])});
    DELETE FROM app_chats WHERE id LIKE 's5f18-chat-%';
    DELETE FROM app_users WHERE id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    COMMIT;
    """
)
p.unlink(missing_ok=True)
PY
}

stop_server() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}

cleanup_all() {
  stop_server || true
  cleanup_rows || true
}

trap cleanup_all EXIT

cp "$IDS_FILE" /tmp/s5f20-real-user-status-route-ids-current.json

LAPTOP_CHAT_QUEUE_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1 \
env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &

SERVER_PID="$!"

for _ in $(seq 1 40); do
  if curl -s "$BASE_URL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"
OTHER_TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["other_token"])' "$IDS_FILE")"
USER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_id"])' "$IDS_FILE")"

created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"Stage 5F-20 status route job","requested_model":"stage-5f20-model"}')"

if [ "$created_code" != "200" ]; then
  echo "FAIL: route creation expected 200, got $created_code"
  cat "$created_body"
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

echo "OK: route created real-user queued job $JOB_ID"

missing_body="$(mktemp)"
missing_code="$(curl -s -o "$missing_body" -w "%{http_code}" "$BASE_URL/api/chat/queued/$JOB_ID")"

if [ "$missing_code" != "401" ]; then
  echo "FAIL: missing token status expected 401, got $missing_code"
  cat "$missing_body"
  exit 1
fi

grep -q "queued_chat_status_session_auth_failed_stage_5f20" "$missing_body" || {
  echo "FAIL: missing token status response missing auth failure marker"
  cat "$missing_body"
  exit 1
}

echo "OK: missing session token refused for status"

wrong_body="$(mktemp)"
wrong_code="$(curl -s -o "$wrong_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $OTHER_TOKEN" \
  "$BASE_URL/api/chat/queued/$JOB_ID")"

if [ "$wrong_code" != "403" ]; then
  echo "FAIL: wrong-user status expected 403, got $wrong_code"
  cat "$wrong_body"
  exit 1
fi

grep -q "queued_chat_status_ownership_failed_stage_5f20" "$wrong_body" || {
  echo "FAIL: wrong-user status response missing ownership failure marker"
  cat "$wrong_body"
  exit 1
}

echo "OK: wrong-user status lookup refused"

owned_body="$(mktemp)"
owned_code="$(curl -s -o "$owned_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  "$BASE_URL/api/chat/queued/$JOB_ID")"

if [ "$owned_code" != "200" ]; then
  echo "FAIL: owned status expected 200, got $owned_code"
  cat "$owned_body"
  exit 1
fi

grep -q '"stage":"5f20"' "$owned_body" || {
  echo "FAIL: owned status missing stage 5f20"
  cat "$owned_body"
  exit 1
}

grep -q '"status":"queued"' "$owned_body" || {
  echo "FAIL: owned status missing queued status"
  cat "$owned_body"
  exit 1
}

grep -q "$USER_ID" "$owned_body" || {
  echo "FAIL: owned status missing authenticated user id"
  cat "$owned_body"
  exit 1
}

echo "OK: owned real-user queued job status returned"

assistant_count="$(python3 - <<PY
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
print(_psql_at(f"SELECT COUNT(*) FROM app_messages m JOIN app_jobs j ON j.id = m.source_job_id WHERE j.id = {_sql_literal('$JOB_ID')};"))
PY
)"

if [ "$assistant_count" != "0" ]; then
  echo "FAIL: expected no assistant messages, found $assistant_count"
  exit 1
fi

echo "OK: no assistant messages were created"

cleanup_all
trap - EXIT

echo "PASS: real-user queued chat status route smoke passed"
