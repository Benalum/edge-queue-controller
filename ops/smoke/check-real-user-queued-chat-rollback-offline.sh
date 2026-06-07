#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat rollback/offline smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

PORT="${REAL_USER_QUEUED_CHAT_ROLLBACK_OFFLINE_PORT:-7121}"
BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f25-rollback-offline-$PORT.log"
IDS_FILE="/tmp/s5f25-rollback-offline-ids-$PORT.json"

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

require_file docs/real-user-queued-chat-rollback-offline.md
require_file docs/real-user-route-ct101-bounded-lifecycle.md
require_file edge_controller.py
require_file edge_modules/chat_queue_real_user_creation.py
require_file edge_modules/chat_queue_session_auth.py
require_file edge_modules/chat_queue_persistence.py

require_fixed docs/real-user-queued-chat-rollback-offline.md "queued chat disabled by default returns feature_disabled" "disabled behavior"
require_fixed docs/real-user-queued-chat-rollback-offline.md "CT101 is not called." "no CT101"
require_fixed docs/real-user-queued-chat-rollback-offline.md "The job remains queued." "offline queued"
require_fixed docs/real-user-queued-chat-rollback-offline.md "No assistant message is created until a worker completes the job." "no early assistant"
require_fixed docs/real-user-queued-chat-rollback-offline.md "Stage 5F-26 should add frontend queued-chat polling/status UI planning" "next stage"

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

suffix = f"s5f25-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
session_id = f"{suffix}-session"
other_session_id = f"{suffix}-other-session"
token = f"{suffix}-token"
other_token = f"{suffix}-other-token"

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

stop_server() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
    SERVER_PID=""
  fi
}

cleanup_rows() {
  python3 - <<PY || true
import json
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path("$IDS_FILE")
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_messages
    WHERE chat_id IN (
      SELECT id FROM app_chats
      WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])})
    )
       OR source_job_id IN (
      SELECT id FROM app_jobs
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
    COMMIT;
    """
)
PY
}

cleanup_all() {
  stop_server || true
  cleanup_rows || true
}

trap cleanup_all EXIT

start_server() {
  stop_server || true

  : > "$LOG_FILE"

  "$@" python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &
  SERVER_PID="$!"

  for _ in $(seq 1 40); do
    if curl -s "$BASE_URL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done

  echo "FAIL: temporary API did not start"
  cat "$LOG_FILE"
  exit 1
}

TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"
OTHER_TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["other_token"])' "$IDS_FILE")"
USER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_id"])' "$IDS_FILE")"

echo "=== disabled-by-default rollback check ==="

start_server env \
  -u LAPTOP_CHAT_QUEUE_ENABLED \
  -u LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED \
  -u LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED \
  -u LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED \
  -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY

disabled_body="$(mktemp)"
disabled_code="$(curl -s -o "$disabled_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"disabled should not create job"}')"

if [ "$disabled_code" != "404" ]; then
  echo "FAIL: disabled route expected 404, got $disabled_code"
  cat "$disabled_body"
  exit 1
fi

grep -q "feature_disabled" "$disabled_body" || {
  echo "FAIL: disabled route missing feature_disabled"
  cat "$disabled_body"
  exit 1
}

disabled_job_count="$(python3 - <<PY
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
print(_psql_at(f"SELECT COUNT(*) FROM app_jobs WHERE user_id = {_sql_literal('$USER_ID')};"))
PY
)"

if [ "$disabled_job_count" != "0" ]; then
  echo "FAIL: disabled route created jobs: $disabled_job_count"
  exit 1
fi

echo "OK: disabled mode refused and created no jobs"

echo "=== creation-helper rollback check ==="

start_server env \
  -u LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED \
  -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  LAPTOP_CHAT_QUEUE_ENABLED=1 \
  LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
  LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1

rollback_body="$(mktemp)"
rollback_code="$(curl -s -o "$rollback_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"creation helper disabled should not create job"}')"

if [ "$rollback_code" != "501" ]; then
  echo "FAIL: creation-helper rollback expected 501, got $rollback_code"
  cat "$rollback_body"
  exit 1
fi

grep -q "real_user_job_creation_not_wired_stage_5f17" "$rollback_body" || {
  echo "FAIL: rollback response missing not-wired marker"
  cat "$rollback_body"
  exit 1
}

rollback_job_count="$(python3 - <<PY
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
print(_psql_at(f"SELECT COUNT(*) FROM app_jobs WHERE user_id = {_sql_literal('$USER_ID')};"))
PY
)"

if [ "$rollback_job_count" != "0" ]; then
  echo "FAIL: creation-helper rollback created jobs: $rollback_job_count"
  exit 1
fi

echo "OK: creation-helper rollback refused and created no jobs"

echo "=== offline queue behavior check ==="

start_server env \
  -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  LAPTOP_CHAT_QUEUE_ENABLED=1 \
  LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
  LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1 \
  LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1

created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"Stage 5F-25 offline queued chat","requested_model":"stage-5f25-model"}')"

if [ "$created_code" != "200" ]; then
  echo "FAIL: offline POST expected 200, got $created_code"
  cat "$created_body"
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

echo "OK: offline mode created queued job $JOB_ID"

queued_body="$(mktemp)"
queued_code="$(curl -s -o "$queued_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  "$BASE_URL/api/chat/queued/$JOB_ID")"

if [ "$queued_code" != "200" ]; then
  echo "FAIL: owner queued status expected 200, got $queued_code"
  cat "$queued_body"
  exit 1
fi

grep -q '"status":"queued"' "$queued_body" || {
  echo "FAIL: owner status missing queued state"
  cat "$queued_body"
  exit 1
}

echo "OK: owner can read queued status while CT101 is offline/not running"

wrong_body="$(mktemp)"
wrong_code="$(curl -s -o "$wrong_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $OTHER_TOKEN" \
  "$BASE_URL/api/chat/queued/$JOB_ID")"

if [ "$wrong_code" != "403" ]; then
  echo "FAIL: wrong-user queued status expected 403, got $wrong_code"
  cat "$wrong_body"
  exit 1
fi

echo "OK: wrong-user queued status refused"

assistant_count="$(python3 - <<PY
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
print(_psql_at(f"SELECT COUNT(*) FROM app_messages WHERE source_job_id = {_sql_literal('$JOB_ID')};"))
PY
)"

if [ "$assistant_count" != "0" ]; then
  echo "FAIL: expected no assistant message before completion, got $assistant_count"
  exit 1
fi

echo "OK: no assistant message exists before job completion"

cleanup_all
trap - EXIT

echo "PASS: real-user queued chat rollback/offline smoke passed"
