#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-6 wrapper-to-controller real-user queued-chat route ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CTRL_PORT="${STAGE5G6_CTRL_PORT:-17260}"
WRAP_PORT="${STAGE5G6_WRAP_PORT:-17261}"
CTRL_BASE="http://127.0.0.1:${CTRL_PORT}"
WRAP_BASE="http://127.0.0.1:${WRAP_PORT}"
CTRL_LOG="/tmp/stage5g6-controller-${CTRL_PORT}.log"
WRAP_LOG="/tmp/stage5g6-wrapper-${WRAP_PORT}.log"
IDS_FILE="/tmp/stage5g6-wrapper-real-user-ids-${WRAP_PORT}.json"

CTRL_PID=""
WRAP_PID=""

cleanup_rows() {
  python3 - "$IDS_FILE" <<'PYCLEAN' || true
import json
import sys
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path(sys.argv[1])
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    DELETE FROM app_messages WHERE chat_id IN ({_sql_literal(ids['existing_chat_id'])}, {_sql_literal(ids['other_chat_id'])})
       OR chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id IN ({_sql_literal(ids['session_id'])}, {_sql_literal(ids['other_session_id'])});
    DELETE FROM app_chats WHERE id IN ({_sql_literal(ids['existing_chat_id'])}, {_sql_literal(ids['other_chat_id'])})
       OR id LIKE 's5f18-chat-%';
    DELETE FROM app_users WHERE id IN ({_sql_literal(ids['user_id'])}, {_sql_literal(ids['other_user_id'])});
    COMMIT;
    """
)

p.unlink(missing_ok=True)
PYCLEAN
}

stop_servers() {
  if [ -n "${WRAP_PID:-}" ]; then
    kill "$WRAP_PID" >/dev/null 2>&1 || true
    wait "$WRAP_PID" >/dev/null 2>&1 || true
  fi
  if [ -n "${CTRL_PID:-}" ]; then
    kill "$CTRL_PID" >/dev/null 2>&1 || true
    wait "$CTRL_PID" >/dev/null 2>&1 || true
  fi
}

cleanup_all() {
  stop_servers || true
  cleanup_rows || true
}

trap cleanup_all EXIT

echo
echo "=== syntax and route ownership markers ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
grep -n "STAGE_5G2_LAPTOP_QUEUED_CHAT_CONTROLLER_OWNER_V1" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi
echo "ok: app.js identity safety"

echo
echo "=== verify wrapper has POST handler ==="
grep -n "def do_POST" frontend/wrapper-ui/dev_server.py >/dev/null || {
  echo "FAIL: wrapper dev_server.py has no do_POST handler, so POST /api/chat/queued cannot proxy yet" >&2
  exit 1
}

echo
echo "=== create real-user smoke rows ==="
python3 - "$IDS_FILE" <<'PYIDS'
import json
import os
import sys
import time

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

ids_file = sys.argv[1]
suffix = f"s5g6-{int(time.time())}-{os.getpid()}"

user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
session_id = f"{suffix}-session"
other_session_id = f"{suffix}-other-session"
token = f"{suffix}-token"
other_token = f"{suffix}-other-token"
existing_chat_id = f"{suffix}-chat"
other_chat_id = f"{suffix}-other-chat"

_psql_run(
    f"""
    BEGIN;

    DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
    DELETE FROM app_messages WHERE chat_id IN ({_sql_literal(existing_chat_id)}, {_sql_literal(other_chat_id)})
       OR chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id IN ({_sql_literal(session_id)}, {_sql_literal(other_session_id)});
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
        'Stage 5G-6 Existing Chat',
        'stage-5g6-model',
        now(),
        now()
      ),
      (
        {_sql_literal(other_chat_id)},
        {_sql_literal(other_user_id)},
        'chat',
        'Stage 5G-6 Other Chat',
        'stage-5g6-model',
        now(),
        now()
      );

    COMMIT;
    """
)

Path = __import__("pathlib").Path
Path(ids_file).write_text(json.dumps({
    "suffix": suffix,
    "user_id": user_id,
    "other_user_id": other_user_id,
    "session_id": session_id,
    "other_session_id": other_session_id,
    "token": token,
    "other_token": other_token,
    "existing_chat_id": existing_chat_id,
    "other_chat_id": other_chat_id,
}))
PYIDS

TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"
OTHER_TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["other_token"])' "$IDS_FILE")"
EXISTING_CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["existing_chat_id"])' "$IDS_FILE")"
OTHER_CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["other_chat_id"])' "$IDS_FILE")"

echo
echo "=== start temporary controller ==="
rm -f "$CTRL_LOG" "$WRAP_LOG"

LAPTOP_CHAT_QUEUE_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1 \
env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$CTRL_PORT" >"$CTRL_LOG" 2>&1 &

CTRL_PID="$!"

for _ in $(seq 1 60); do
  if curl -fsS "$CTRL_BASE/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

curl -fsS "$CTRL_BASE/health" >/dev/null || {
  echo "FAIL: controller did not start"
  cat "$CTRL_LOG" || true
  exit 1
}

echo "ok: controller listening on $CTRL_BASE"

echo
echo "=== start temporary wrapper ==="
EDGE_CONTROLLER_URL="$CTRL_BASE" \
EDGE_PUBLIC_GATEWAY_URL="http://127.0.0.1:17999" \
CT101_API="http://127.0.0.1:17998" \
CT101_FRONTEND="http://127.0.0.1:17997" \
WRAPPER_UI_PORT="$WRAP_PORT" \
  python frontend/wrapper-ui/dev_server.py >"$WRAP_LOG" 2>&1 &

WRAP_PID="$!"

for _ in $(seq 1 60); do
  if curl -s "$WRAP_BASE/api/chat/queued/smoke-startup" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

echo "ok: wrapper attempted startup on $WRAP_BASE"

echo
echo "=== wrapper GET disabled/auth behavior reaches controller ==="
startup_body="$(mktemp)"
startup_code="$(curl -s -o "$startup_body" -w "%{http_code}" "$WRAP_BASE/api/chat/queued/smoke-startup")"
cat "$startup_body"
echo
echo "status=$startup_code"

if ! grep -Eq 'queued_chat_status_session_auth_failed_stage_5f20|queued_chat_session_auth_failed_stage_5f17|feature_disabled|session' "$startup_body"; then
  echo "FAIL: wrapper GET did not appear to reach controller queued route"
  echo "--- wrapper log ---"
  cat "$WRAP_LOG" || true
  echo "--- controller log ---"
  cat "$CTRL_LOG" || true
  exit 1
fi

echo
echo "=== wrapper POST missing token refused ==="
missing_body="$(mktemp)"
missing_code="$(curl -s -o "$missing_body" -w "%{http_code}" \
  -X POST "$WRAP_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"missing token should fail through wrapper"}')"
cat "$missing_body"
echo
echo "status=$missing_code"

if [ "$missing_code" != "401" ]; then
  echo "FAIL: missing token through wrapper expected 401, got $missing_code"
  exit 1
fi

grep -q "queued_chat_session_auth_failed_stage_5f17" "$missing_body" || {
  echo "FAIL: missing-token wrapper response missing auth marker"
  exit 1
}

echo "ok: missing token refused through wrapper"

echo
echo "=== wrapper POST client-provided user_id refused ==="
client_user_body="$(mktemp)"
client_user_code="$(curl -s -o "$client_user_body" -w "%{http_code}" \
  -X POST "$WRAP_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d '{"message":"client id should fail through wrapper","user_id":"attacker"}')"
cat "$client_user_body"
echo
echo "status=$client_user_code"

if [ "$client_user_code" != "401" ]; then
  echo "FAIL: client user_id through wrapper expected 401, got $client_user_code"
  exit 1
fi

grep -q "client-provided user_id is refused" "$client_user_body" || {
  echo "FAIL: client-user-id wrapper response missing refusal marker"
  exit 1
}

echo "ok: client-provided user_id refused through wrapper"

echo
echo "=== wrapper POST wrong-user chat reuse refused ==="
wrong_chat_body="$(mktemp)"
wrong_chat_code="$(curl -s -o "$wrong_chat_body" -w "%{http_code}" \
  -X POST "$WRAP_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d "{\"message\":\"wrong chat should fail through wrapper\",\"chat_id\":\"$OTHER_CHAT_ID\"}")"
cat "$wrong_chat_body"
echo
echo "status=$wrong_chat_code"

if [ "$wrong_chat_code" != "400" ]; then
  echo "FAIL: wrong chat through wrapper expected 400, got $wrong_chat_code"
  exit 1
fi

grep -q "chat does not belong to authenticated user" "$wrong_chat_body" || {
  echo "FAIL: wrong-chat wrapper response missing ownership marker"
  exit 1
}

echo "ok: wrong-user chat reuse refused through wrapper"

echo
echo "=== wrapper POST creates real-user queued job ==="
created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$WRAP_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d "{\"message\":\"Stage 5G-6 wrapper real-user queued chat\",\"chat_id\":\"$EXISTING_CHAT_ID\",\"requested_model\":\"stage-5g6-model\"}")"
cat "$created_body"
echo
echo "status=$created_code"

if [ "$created_code" != "200" ]; then
  echo "FAIL: wrapper create expected 200, got $created_code"
  exit 1
fi

grep -q '"ok":true' "$created_body" || {
  echo "FAIL: wrapper create missing ok true"
  exit 1
}

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

echo "ok: wrapper created job $JOB_ID"

echo
echo "=== wrapper GET wrong-user status refused ==="
wrong_status_body="$(mktemp)"
wrong_status_code="$(curl -s -o "$wrong_status_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $OTHER_TOKEN" \
  "$WRAP_BASE/api/chat/queued/$JOB_ID")"
cat "$wrong_status_body"
echo
echo "status=$wrong_status_code"

if [ "$wrong_status_code" != "403" ]; then
  echo "FAIL: wrong-user wrapper status expected 403, got $wrong_status_code"
  exit 1
fi

grep -q "queued_chat_status_ownership_failed_stage_5f20" "$wrong_status_body" || {
  echo "FAIL: wrong-user wrapper status missing ownership marker"
  exit 1
}

echo "ok: wrong-user status refused through wrapper"

echo
echo "=== wrapper GET owned status succeeds ==="
owned_status_body="$(mktemp)"
owned_status_code="$(curl -s -o "$owned_status_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  "$WRAP_BASE/api/chat/queued/$JOB_ID")"
cat "$owned_status_body"
echo
echo "status=$owned_status_code"

if [ "$owned_status_code" != "200" ]; then
  echo "FAIL: owned wrapper status expected 200, got $owned_status_code"
  exit 1
fi

grep -q '"status":"queued"' "$owned_status_body" || {
  echo "FAIL: owned wrapper status missing queued status"
  exit 1
}

echo
echo "=== verify no assistant messages created ==="
assistant_count="$(python3 - "$EXISTING_CHAT_ID" <<'PYCOUNT'
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
chat_id = sys.argv[1]
print(_psql_at(
    f"""
    SELECT COUNT(*)
    FROM app_messages
    WHERE chat_id = {_sql_literal(chat_id)}
      AND role = 'assistant';
    """
))
PYCOUNT
)"

if [ "$assistant_count" != "0" ]; then
  echo "FAIL: expected no assistant messages, got $assistant_count"
  exit 1
fi

echo "ok: no assistant messages created"

echo
echo "Stage 5G-6 wrapper-to-controller real-user queued-chat route passed."
