#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat route creation smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

PORT="${REAL_USER_QUEUED_CHAT_ROUTE_CREATION_PORT:-7118}"
BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f19-real-user-route-creation-$PORT.log"
IDS_FILE="/tmp/s5f19-real-user-route-creation-ids-$PORT.json"

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

require_file docs/real-user-queued-chat-route-creation.md
require_file edge_controller.py
require_file edge_modules/chat_queue_real_user_creation.py
require_file edge_modules/chat_queue_session_auth.py

require_fixed edge_controller.py "stage_5f19_real_user_route" "route source marker"
require_fixed edge_controller.py "real_user_queued_chat_creation_failed_stage_5f19" "creation failure marker"
require_fixed edge_controller.py "_s5f19_create_real_user_queued_chat_job" "creation helper wiring"
require_fixed docs/real-user-queued-chat-route-creation.md "does not call CT101" "no CT101"
require_fixed docs/real-user-queued-chat-route-creation.md "does not persist assistant messages" "no assistant persistence"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_real_user_creation.py \
  edge_modules/chat_queue_session_auth.py \
  edge_modules/chat_queue_persistence.py

python3 - <<'PY' > "$IDS_FILE"
import json
import os
import time

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

suffix = f"s5f19-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
session_id = f"{suffix}-session"
token = f"{suffix}-token"
existing_chat_id = f"{suffix}-chat"
other_chat_id = f"{suffix}-other-chat"

_psql_run(
    f"""
    BEGIN;

    DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
    DELETE FROM app_messages WHERE chat_id IN ({_sql_literal(existing_chat_id)}, {_sql_literal(other_chat_id)})
       OR chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id = {_sql_literal(session_id)};
    DELETE FROM app_chats WHERE id IN ({_sql_literal(existing_chat_id)}, {_sql_literal(other_chat_id)})
       OR id LIKE 's5f18-chat-%';
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
    VALUES (
      {_sql_literal(session_id)},
      {_sql_literal(user_id)},
      {_sql_literal(hash_session_token(token))},
      now(),
      now() + interval '1 hour',
      NULL
    );

    INSERT INTO app_chats (
      id,
      user_id,
      mode,
      title,
      model,
      created_at,
      updated_at
    )
    VALUES
      (
        {_sql_literal(existing_chat_id)},
        {_sql_literal(user_id)},
        'chat',
        'Stage 5F-19 Existing Chat',
        'synthetic',
        now(),
        now()
      ),
      (
        {_sql_literal(other_chat_id)},
        {_sql_literal(other_user_id)},
        'chat',
        'Stage 5F-19 Other Chat',
        'synthetic',
        now(),
        now()
      );

    COMMIT;
    """
)

print(json.dumps({
    "suffix": suffix,
    "user_id": user_id,
    "other_user_id": other_user_id,
    "session_id": session_id,
    "token": token,
    "existing_chat_id": existing_chat_id,
    "other_chat_id": other_chat_id,
}))
PY

SERVER_PID=""

cleanup_rows() {
  python3 - <<'PY' || true
import json
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path("/tmp/s5f19-real-user-route-creation-ids-current.json")
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    DELETE FROM app_messages WHERE chat_id IN ({_sql_literal(ids['existing_chat_id'])}, {_sql_literal(ids['other_chat_id'])})
       OR chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id = {_sql_literal(ids['session_id'])};
    DELETE FROM app_chats WHERE id IN ({_sql_literal(ids['existing_chat_id'])}, {_sql_literal(ids['other_chat_id'])})
       OR id LIKE 's5f18-chat-%';
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

cp "$IDS_FILE" /tmp/s5f19-real-user-route-creation-ids-current.json

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
OTHER_CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["other_chat_id"])' "$IDS_FILE")"
EXISTING_CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["existing_chat_id"])' "$IDS_FILE")"
USER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_id"])' "$IDS_FILE")"

missing_body="$(mktemp)"
missing_code="$(curl -s -o "$missing_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"missing token should fail"}')"

if [ "$missing_code" != "401" ]; then
  echo "FAIL: missing token expected 401, got $missing_code"
  cat "$missing_body"
  exit 1
fi

echo "OK: missing session token refused"

client_user_body="$(mktemp)"
client_user_code="$(curl -s -o "$client_user_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"client user should fail","user_id":"evil"}')"

if [ "$client_user_code" != "401" ]; then
  echo "FAIL: client user_id expected 401, got $client_user_code"
  cat "$client_user_body"
  exit 1
fi

echo "OK: client-provided user_id refused"

wrong_chat_body="$(mktemp)"
wrong_chat_code="$(curl -s -o "$wrong_chat_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d "{\"message\":\"wrong chat should fail\",\"chat_id\":\"$OTHER_CHAT_ID\"}")"

if [ "$wrong_chat_code" != "400" ]; then
  echo "FAIL: wrong-user chat expected 400, got $wrong_chat_code"
  cat "$wrong_chat_body"
  exit 1
fi

grep -q "real_user_queued_chat_creation_failed_stage_5f19" "$wrong_chat_body" || {
  echo "FAIL: wrong-user chat missing creation failure marker"
  cat "$wrong_chat_body"
  exit 1
}

echo "OK: wrong-user chat reuse refused"

new_body="$(mktemp)"
new_code="$(curl -s -o "$new_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"Stage 5F-19 route new chat","requested_model":"stage-5f19-model"}')"

if [ "$new_code" != "200" ]; then
  echo "FAIL: new chat route expected 200, got $new_code"
  cat "$new_body"
  exit 1
fi

grep -q '"stage":"5f19"' "$new_body" || {
  echo "FAIL: new chat route missing stage 5f19"
  cat "$new_body"
  exit 1
}

echo "OK: route created real-user queued job for new chat"

existing_body="$(mktemp)"
existing_code="$(curl -s -o "$existing_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d "{\"message\":\"Stage 5F-19 route existing chat\",\"chat_id\":\"$EXISTING_CHAT_ID\",\"requested_model\":\"stage-5f19-model\"}")"

if [ "$existing_code" != "200" ]; then
  echo "FAIL: existing chat route expected 200, got $existing_code"
  cat "$existing_body"
  exit 1
fi

echo "OK: route created real-user queued job for existing owned chat"

job_count="$(python3 - <<PY
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
print(_psql_at(f"SELECT COUNT(*) FROM app_jobs WHERE user_id = {_sql_literal('$USER_ID')} AND status = 'queued' AND job_type = 'ollama_chat';"))
PY
)"

if [ "$job_count" != "2" ]; then
  echo "FAIL: expected 2 queued real-user jobs, found $job_count"
  exit 1
fi

assistant_count="$(python3 - <<PY
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
print(_psql_at(f"SELECT COUNT(*) FROM app_messages m JOIN app_jobs j ON j.id = m.source_job_id WHERE j.user_id = {_sql_literal('$USER_ID')};"))
PY
)"

if [ "$assistant_count" != "0" ]; then
  echo "FAIL: expected no assistant messages, found $assistant_count"
  exit 1
fi

echo "OK: no assistant messages were created"

cleanup_all
trap - EXIT

echo "PASS: real-user queued chat route creation smoke passed"
