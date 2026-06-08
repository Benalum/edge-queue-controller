#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-12 live runtime CT101 queued bridge smoke ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CONTROLLER_BASE="${STAGE5G12_CONTROLLER_BASE:-http://127.0.0.1:7070}"
WRAPPER_BASE="${STAGE5G12_WRAPPER_BASE:-http://127.0.0.1:8787}"
IDS_FILE="/tmp/stage5g12-live-runtime-ids.json"

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

trap cleanup_rows EXIT

echo
echo "=== syntax and defaults ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED" frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G10_CT101_COMPAT_ASSISTANT_MESSAGE_V1" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== live process health ==="
curl -fsS "$CONTROLLER_BASE/health" >/dev/null
curl -fsS "$WRAPPER_BASE/" >/dev/null

echo "ok: controller and wrapper are reachable"

echo
echo "=== create live smoke real-user session/chat rows ==="
python3 - "$IDS_FILE" <<'PYIDS'
import json
import os
import sys
import time
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

ids_file = sys.argv[1]
suffix = f"s5g12-{int(time.time())}-{os.getpid()}"

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
      'Stage 5G-12 Live Runtime Bridge Chat',
      'stage-5g12-model',
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
echo "=== live CT101-shaped queued create through wrapper ==="
created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$WRAPPER_BASE/api/backend/chats/$CHAT_ID/messages/queued" \
  -H 'Content-Type: application/json' \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  -d '{"content":"Stage 5G-12 live runtime bridge request","model":"stage-5g12-model"}')"

cat "$created_body"
echo
echo "status=$created_code"

if [ "$created_code" != "200" ]; then
  echo "FAIL: live bridge create expected 200, got $created_code"
  exit 1
fi

python3 - "$created_body" "$CHAT_ID" <<'PYCHECK'
import json
import sys

body = json.load(open(sys.argv[1]))
chat_id = sys.argv[2]

if body.get("ok") is not True:
    raise SystemExit(f"create missing ok true: {body}")

if body.get("chat_id") != chat_id:
    raise SystemExit(f"create wrong chat_id: {body}")

if not body.get("job_id"):
    raise SystemExit(f"create missing job_id: {body}")

if body.get("status") != "queued":
    raise SystemExit(f"create expected queued status: {body}")

payload = body.get("payload_json") or {}
if payload.get("prompt") != "Stage 5G-12 live runtime bridge request":
    raise SystemExit(f"prompt was not bridged correctly: {payload}")

print("OK: live create path is bridged to laptop controller")
PYCHECK

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

echo
echo "=== live CT101-shaped queued status through wrapper ==="
status_body="$(mktemp)"
status_code="$(curl -s -o "$status_body" -w "%{http_code}" \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  "$WRAPPER_BASE/api/backend/chats/$CHAT_ID/messages/jobs/$JOB_ID")"

cat "$status_body"
echo
echo "status=$status_code"

if [ "$status_code" != "200" ]; then
  echo "FAIL: live bridge status expected 200, got $status_code"
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
    raise SystemExit(f"expected queued status: {body}")

if "assistant_message" not in body:
    raise SystemExit(f"status missing assistant_message compatibility key: {body}")

print("OK: live status path is CT101-compatible")
PYCHECK

echo
echo "=== mark job complete to verify live completed compatibility ==="
python3 - "$JOB_ID" <<'PYCOMPLETE'
import json
import sys

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

job_id = sys.argv[1]
result_json = json.dumps({
    "reply": "Stage 5G-12 live runtime completed assistant reply",
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

completed_body="$(mktemp)"
completed_code="$(curl -s -o "$completed_body" -w "%{http_code}" \
  -H "Cookie: edgeStudyToken=$TOKEN" \
  "$WRAPPER_BASE/api/backend/chats/$CHAT_ID/messages/jobs/$JOB_ID")"

cat "$completed_body"
echo
echo "status=$completed_code"

if [ "$completed_code" != "200" ]; then
  echo "FAIL: completed live bridge status expected 200, got $completed_code"
  exit 1
fi

python3 - "$completed_body" "$CHAT_ID" "$JOB_ID" <<'PYCHECK'
import json
import sys

body = json.load(open(sys.argv[1]))
chat_id = sys.argv[2]
job_id = sys.argv[3]

if body.get("status") != "complete":
    raise SystemExit(f"expected complete status: {body}")

msg = body.get("assistant_message")
if not isinstance(msg, dict):
    raise SystemExit(f"missing assistant_message: {body}")

if msg.get("role") != "assistant":
    raise SystemExit(f"assistant role mismatch: {msg}")

if msg.get("content") != "Stage 5G-12 live runtime completed assistant reply":
    raise SystemExit(f"assistant content mismatch: {msg}")

print("OK: live completed response is CT101-compatible")
PYCHECK

echo
echo "=== verify no assistant DB rows were created by wrapper ==="
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
  echo "FAIL: expected no assistant DB rows from wrapper, got $assistant_count"
  exit 1
fi

echo "ok: no assistant DB rows created by wrapper"

echo
echo "Stage 5G-12 live runtime CT101 queued bridge smoke passed."
