#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-9 CT101 queued bridge to laptop controller ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CTRL_PORT="${STAGE5G9_CTRL_PORT:-17490}"
WRAP_PORT="${STAGE5G9_WRAP_PORT:-17491}"
CTRL_BASE="http://127.0.0.1:${CTRL_PORT}"
WRAP_BASE="http://127.0.0.1:${WRAP_PORT}"
CTRL_LOG="/tmp/stage5g9-controller-${CTRL_PORT}.log"
WRAP_LOG="/tmp/stage5g9-wrapper-${WRAP_PORT}.log"
IDS_FILE="/tmp/stage5g9-ids-${WRAP_PORT}.json"

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
    DELETE FROM app_jobs WHERE user_id = {_sql_literal(ids['user_id'])};
    DELETE FROM app_messages WHERE chat_id = {_sql_literal(ids['chat_id'])}
       OR chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id = {_sql_literal(ids['session_id'])};
    DELETE FROM app_chats WHERE id = {_sql_literal(ids['chat_id'])}
       OR id LIKE 's5f18-chat-%';
    DELETE FROM app_users WHERE id = {_sql_literal(ids['user_id'])};
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
echo "=== syntax and bridge markers ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED" frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G9_CT101_QUEUED_CHAT_BRIDGE_V1" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== create real-user session/chat rows ==="
python3 - "$IDS_FILE" <<'PYIDS'
import json
import os
import sys
import time
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

ids_file = sys.argv[1]
suffix = f"s5g9-{int(time.time())}-{os.getpid()}"

user_id = f"{suffix}-user"
session_id = f"{suffix}-session"
token = f"{suffix}-token"
chat_id = f"{suffix}-chat"

_psql_run(
    f"""
    BEGIN;

    DELETE FROM app_jobs WHERE user_id = {_sql_literal(user_id)};
    DELETE FROM app_messages WHERE chat_id = {_sql_literal(chat_id)}
       OR chat_id LIKE 's5f18-chat-%';
    DELETE FROM app_sessions WHERE id = {_sql_literal(session_id)};
    DELETE FROM app_chats WHERE id = {_sql_literal(chat_id)}
       OR id LIKE 's5f18-chat-%';
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

    INSERT INTO app_chats (
      id,
      user_id,
      mode,
      title,
      model,
      created_at,
      updated_at
    )
    VALUES (
      {_sql_literal(chat_id)},
      {_sql_literal(user_id)},
      'chat',
      'Stage 5G-9 CT101 Bridge Chat',
      'stage-5g9-model',
      now(),
      now()
    );

    COMMIT;
    """
)

Path(ids_file).write_text(json.dumps({
    "suffix": suffix,
    "user_id": user_id,
    "session_id": session_id,
    "token": token,
    "chat_id": chat_id,
}))
PYIDS

TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"
CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chat_id"])' "$IDS_FILE")"

echo
echo "=== start temporary laptop controller ==="
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
echo "=== start temporary wrapper with bridge enabled ==="
EDGE_CONTROLLER_URL="$CTRL_BASE" \
EDGE_PUBLIC_GATEWAY_URL="http://127.0.0.1:17999" \
CT101_API="http://127.0.0.1:17998" \
CT101_FRONTEND="http://127.0.0.1:17997" \
WRAPPER_UI_PORT="$WRAP_PORT" \
WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1 \
  python frontend/wrapper-ui/dev_server.py >"$WRAP_LOG" 2>&1 &

WRAP_PID="$!"

for _ in $(seq 1 60); do
  if curl -s "$WRAP_BASE/api/backend/chats/$CHAT_ID/messages/jobs/smoke-startup" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

echo "ok: wrapper attempted startup on $WRAP_BASE"

echo
echo "=== CT101-shaped queued create through wrapper ==="
created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$WRAP_BASE/api/backend/chats/$CHAT_ID/messages/queued" \
  -H 'Content-Type: application/json' \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  -d '{"content":"Stage 5G-9 CT101-shaped queued request","model":"stage-5g9-model"}')"

cat "$created_body"
echo
echo "status=$created_code"

if [ "$created_code" != "200" ]; then
  echo "FAIL: CT101-shaped create expected 200, got $created_code"
  echo "--- wrapper log ---"
  cat "$WRAP_LOG" || true
  echo "--- controller log ---"
  cat "$CTRL_LOG" || true
  exit 1
fi

python3 - "$created_body" "$CHAT_ID" <<'PYCHECK'
import json
import sys

body = json.load(open(sys.argv[1]))
chat_id = sys.argv[2]

if body.get("ok") is not True:
    raise SystemExit(f"create missing ok true: {body}")

if not body.get("job_id"):
    raise SystemExit(f"create missing job_id: {body}")

if body.get("chat_id") != chat_id:
    raise SystemExit(f"create wrong chat_id: {body}")

if body.get("status") != "queued":
    raise SystemExit(f"create expected top-level queued status: {body}")

payload = body.get("payload_json") or {}
if payload.get("prompt") != "Stage 5G-9 CT101-shaped queued request":
    raise SystemExit(f"laptop payload did not receive transformed prompt: {payload}")

if payload.get("requested_model") != "stage-5g9-model":
    raise SystemExit(f"laptop payload did not receive transformed model: {payload}")

print("OK: create response compatible with CT101 ChatPage")
PYCHECK

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

echo
echo "=== CT101-shaped queued status through wrapper ==="
status_body="$(mktemp)"
status_code="$(curl -s -o "$status_body" -w "%{http_code}" \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  "$WRAP_BASE/api/backend/chats/$CHAT_ID/messages/jobs/$JOB_ID")"

cat "$status_body"
echo
echo "status=$status_code"

if [ "$status_code" != "200" ]; then
  echo "FAIL: CT101-shaped status expected 200, got $status_code"
  exit 1
fi

python3 - "$status_body" "$CHAT_ID" "$JOB_ID" <<'PYCHECK'
import json
import sys

body = json.load(open(sys.argv[1]))
chat_id = sys.argv[2]
job_id = sys.argv[3]

if body.get("ok") is not True:
    raise SystemExit(f"status missing ok true: {body}")

if body.get("chat_id") != chat_id:
    raise SystemExit(f"status wrong chat_id: {body}")

if body.get("job_id") != job_id:
    raise SystemExit(f"status wrong job_id: {body}")

if body.get("status") != "queued":
    raise SystemExit(f"status expected top-level queued status: {body}")

if "assistant_message" not in body:
    raise SystemExit(f"status missing assistant_message compatibility key: {body}")

print("OK: status response compatible with CT101 ChatPage queued polling")
PYCHECK

echo
echo "=== verify no assistant messages created ==="
assistant_count="$(python3 - "$CHAT_ID" <<'PYCOUNT'
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
echo "=== previous active ownership smoke ==="
bash ops/smoke/check-stage-5g8-active-chat-ownership-and-queued-route-shape.sh

echo
echo "Stage 5G-9 CT101 queued bridge to laptop controller passed."
