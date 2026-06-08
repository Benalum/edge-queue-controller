#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-10 CT101-compatible completed queued assistant message ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CTRL_PORT="${STAGE5G10_CTRL_PORT:-17510}"
WRAP_PORT="${STAGE5G10_WRAP_PORT:-17511}"
CTRL_BASE="http://127.0.0.1:${CTRL_PORT}"
WRAP_BASE="http://127.0.0.1:${WRAP_PORT}"
CTRL_LOG="/tmp/stage5g10-controller-${CTRL_PORT}.log"
WRAP_LOG="/tmp/stage5g10-wrapper-${WRAP_PORT}.log"
IDS_FILE="/tmp/stage5g10-ids-${WRAP_PORT}.json"

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
echo "=== syntax and safety markers ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED" frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G9_CT101_QUEUED_CHAT_BRIDGE_V1" frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G10_CT101_COMPAT_ASSISTANT_MESSAGE_V1" frontend/wrapper-ui/dev_server.py
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
suffix = f"s5g10-{int(time.time())}-{os.getpid()}"

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
      'Stage 5G-10 Completed Bridge Chat',
      'stage-5g10-model',
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
  -d '{"content":"Stage 5G-10 CT101-shaped completed request","model":"stage-5g10-model"}')"

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

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

echo
echo "=== mark laptop job complete with worker-style result_json ==="
python3 - "$JOB_ID" <<'PYCOMPLETE'
import json
import sys

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

job_id = sys.argv[1]
result_json = json.dumps({
    "reply": "Stage 5G-10 completed assistant reply",
})

_psql_run(
    f"""
    UPDATE app_jobs
    SET status = 'complete',
        result_json = {_sql_literal(result_json)},
        error_text = NULL,
        updated_at = now(),
        finished_at = now()
    WHERE id = {_sql_literal(job_id)};
    """
)
PYCOMPLETE

echo "ok: marked $JOB_ID complete"

echo
echo "=== first CT101-shaped completed status through wrapper ==="
status_body_1="$(mktemp)"
status_code_1="$(curl -s -o "$status_body_1" -w "%{http_code}" \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  "$WRAP_BASE/api/backend/chats/$CHAT_ID/messages/jobs/$JOB_ID")"

cat "$status_body_1"
echo
echo "status=$status_code_1"

if [ "$status_code_1" != "200" ]; then
  echo "FAIL: completed status expected 200, got $status_code_1"
  exit 1
fi

echo
echo "=== second CT101-shaped completed status through wrapper ==="
status_body_2="$(mktemp)"
status_code_2="$(curl -s -o "$status_body_2" -w "%{http_code}" \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  "$WRAP_BASE/api/backend/chats/$CHAT_ID/messages/jobs/$JOB_ID")"

cat "$status_body_2"
echo
echo "status=$status_code_2"

if [ "$status_code_2" != "200" ]; then
  echo "FAIL: second completed status expected 200, got $status_code_2"
  exit 1
fi

python3 - "$status_body_1" "$status_body_2" "$CHAT_ID" "$JOB_ID" <<'PYCHECK'
import json
import sys

first = json.load(open(sys.argv[1]))
second = json.load(open(sys.argv[2]))
chat_id = sys.argv[3]
job_id = sys.argv[4]

for label, body in [("first", first), ("second", second)]:
    if body.get("ok") is not True:
        raise SystemExit(f"{label} missing ok true: {body}")

    if body.get("mode") != "queued":
        raise SystemExit(f"{label} missing queued mode: {body}")

    if body.get("chat_id") != chat_id:
        raise SystemExit(f"{label} wrong chat_id: {body}")

    if body.get("job_id") != job_id:
        raise SystemExit(f"{label} wrong job_id: {body}")

    if body.get("status") != "complete":
        raise SystemExit(f"{label} expected complete status: {body}")

    msg = body.get("assistant_message")
    if not isinstance(msg, dict):
        raise SystemExit(f"{label} missing assistant_message object: {body}")

    if msg.get("role") != "assistant":
        raise SystemExit(f"{label} assistant role mismatch: {msg}")

    if msg.get("content") != "Stage 5G-10 completed assistant reply":
        raise SystemExit(f"{label} assistant content mismatch: {msg}")

    if msg.get("risk_level") != 0:
        raise SystemExit(f"{label} assistant risk_level mismatch: {msg}")

    if not msg.get("id"):
        raise SystemExit(f"{label} assistant message id missing: {msg}")

if first["assistant_message"]["id"] != second["assistant_message"]["id"]:
    raise SystemExit("assistant_message id changed between polls")

print("OK: completed status is CT101-compatible and idempotent")
PYCHECK

echo
echo "=== verify wrapper did not materialize assistant rows ==="
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

echo "ok: wrapper did not create assistant message rows"

echo
echo "=== previous CT101 queued bridge smoke ==="
bash ops/smoke/check-stage-5g9-ct101-queued-bridge-to-laptop-controller.sh

echo
echo "Stage 5G-10 CT101-compatible completed queued assistant message passed."
