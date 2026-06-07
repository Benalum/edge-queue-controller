#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== queued chat route session-auth guard smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

PORT="${QUEUED_CHAT_ROUTE_SESSION_AUTH_GUARD_PORT:-7116}"
BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f17-route-session-auth-$PORT.log"

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

require_file docs/queued-chat-route-session-auth-guard.md
require_file edge_controller.py
require_file edge_modules/chat_queue_session_auth.py

require_fixed edge_controller.py "real_user_job_creation_not_wired_stage_5f17" "POST real-user not wired marker"
require_fixed edge_controller.py "queued_chat_session_auth_failed_stage_5f17" "auth failure marker"
require_fixed edge_controller.py "X-Queued-Chat-Session-Token" "session token header"
require_fixed docs/queued-chat-route-session-auth-guard.md "does not create real production queued chat jobs" "no real jobs"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_session_auth.py \
  edge_modules/chat_queue_persistence.py

python3 - <<'PY' > /tmp/s5f17-session-auth-ids.json
import json
import os
import time

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

suffix = f"s5f17-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
session_id = f"{suffix}-session"
token = f"{suffix}-token"

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_sessions WHERE id = {_sql_literal(session_id)};
    DELETE FROM app_users WHERE id = {_sql_literal(user_id)};

    INSERT INTO app_users (
      id,
      email,
      password_hash,
      is_active,
      is_admin,
      created_at,
      updated_at
    )
    VALUES (
      {_sql_literal(user_id)},
      {_sql_literal(user_id + '@example.invalid')},
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

    COMMIT;
    """
)

print(json.dumps({"suffix": suffix, "user_id": user_id, "session_id": session_id, "token": token}))
PY

SERVER_PID=""

cleanup_rows() {
  python3 - <<'PY' || true
import json
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path("/tmp/s5f17-session-auth-ids.json")
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())
_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_sessions WHERE id = {_sql_literal(ids['session_id'])};
    DELETE FROM app_users WHERE id = {_sql_literal(ids['user_id'])};
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

LAPTOP_CHAT_QUEUE_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1 \
env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &

SERVER_PID="$!"

for _ in $(seq 1 40); do
  if curl -s "$BASE_URL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

missing_body="$(mktemp)"
missing_code="$(curl -s -o "$missing_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"missing token should fail"}')"

if [ "$missing_code" != "401" ]; then
  echo "FAIL: missing session expected 401, got $missing_code"
  cat "$missing_body"
  exit 1
fi

grep -q "queued_chat_session_auth_failed_stage_5f17" "$missing_body" || {
  echo "FAIL: missing session response missing auth failure marker"
  cat "$missing_body"
  exit 1
}

echo "OK: missing session token refused"

TOKEN="$(python3 -c 'import json; print(json.load(open("/tmp/s5f17-session-auth-ids.json"))["token"])')"

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

grep -q "queued_chat_session_auth_failed_stage_5f17" "$client_user_body" || {
  echo "FAIL: client user response missing auth failure marker"
  cat "$client_user_body"
  exit 1
}

echo "OK: client-provided user_id refused at route"

valid_body="$(mktemp)"
valid_code="$(curl -s -o "$valid_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"valid auth should resolve but not create job"}')"

if [ "$valid_code" != "501" ]; then
  echo "FAIL: valid auth expected 501 not wired, got $valid_code"
  cat "$valid_body"
  exit 1
fi

grep -q "real_user_job_creation_not_wired_stage_5f17" "$valid_body" || {
  echo "FAIL: valid auth response missing not-wired marker"
  cat "$valid_body"
  exit 1
}

USER_ID="$(python3 -c 'import json; print(json.load(open("/tmp/s5f17-session-auth-ids.json"))["user_id"])')"

grep -q "$USER_ID" "$valid_body" || {
  echo "FAIL: valid auth response missing authenticated user id"
  cat "$valid_body"
  exit 1
}

echo "OK: valid session resolved user but created no job"

job_count="$(python3 - <<'PY'
import json
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

ids = json.load(open("/tmp/s5f17-session-auth-ids.json"))
print(_psql_at(f"SELECT COUNT(*) FROM app_jobs WHERE user_id = {_sql_literal(ids['user_id'])};"))
PY
)"

if [ "$job_count" != "0" ]; then
  echo "FAIL: expected no real-user jobs, found $job_count"
  exit 1
fi

echo "OK: no real-user queued jobs were created"

cleanup_all
trap - EXIT

echo "PASS: queued chat route session-auth guard smoke passed"
