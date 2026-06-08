#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-14 trusted CT101 identity bridge for laptop queued chat ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CTRL_PORT="${STAGE5G14_CTRL_PORT:-17640}"
WRAP_PORT="${STAGE5G14_WRAP_PORT:-17641}"
CTRL_BASE="http://127.0.0.1:${CTRL_PORT}"
WRAP_BASE="http://127.0.0.1:${WRAP_PORT}"
CTRL_LOG="/tmp/stage5g14-controller-${CTRL_PORT}.log"
WRAP_LOG="/tmp/stage5g14-wrapper-${WRAP_PORT}.log"
IDS_FILE="/tmp/stage5g14-ids-${WRAP_PORT}.json"

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
raw_user_id = ids["user_id"]
user_id = "ct101:" + raw_user_id
chat_id = ids["chat_id"]

_psql_run(
    f"""
    BEGIN;
    DELETE FROM app_jobs WHERE user_id = {_sql_literal(user_id)};
    DELETE FROM app_messages WHERE chat_id = {_sql_literal(chat_id)}
       OR chat_id = {_sql_literal('ct101-status-session-refresh-' + user_id)};
    DELETE FROM app_chats WHERE id = {_sql_literal(chat_id)}
       OR id = {_sql_literal('ct101-status-session-refresh-' + user_id)};
    DELETE FROM app_sessions WHERE user_id = {_sql_literal(user_id)};
    DELETE FROM app_users WHERE id = {_sql_literal(user_id)};
    COMMIT;
    """
)
p.unlink(missing_ok=True)
PYCLEAN
}

stop_servers() {
  if [ -n "${WRAP_PID:-}" ]; then kill "$WRAP_PID" >/dev/null 2>&1 || true; fi
  if [ -n "${CTRL_PID:-}" ]; then kill "$CTRL_PID" >/dev/null 2>&1 || true; fi
}

cleanup_all() {
  stop_servers || true
  cleanup_rows || true
}
trap cleanup_all EXIT

echo
echo "=== syntax and markers ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G14_TRUSTED_CT101_IDENTITY_BRIDGE_V1" edge_controller.py
grep -n "STAGE_5G14_FORWARD_TRUSTED_CT101_IDENTITY_TO_CONTROLLER_V1" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== get CT101 trusted proxy secret from wrapper env ==="
EDGE_SECRET="$(grep '^EDGE_TRUSTED_PROXY_SECRET=' "$HOME/.config/ai-platform-controller/runtime/wrapper.env" | sed 's/^EDGE_TRUSTED_PROXY_SECRET=//')"
if [ -z "$EDGE_SECRET" ]; then
  echo "FAIL: missing EDGE_TRUSTED_PROXY_SECRET in wrapper runtime env" >&2
  exit 1
fi
echo "ok: trusted proxy secret loaded, length=${#EDGE_SECRET}"

echo
echo "=== create CT101-like test identity ==="
python3 - "$IDS_FILE" <<'PYIDS'
import json
import os
import time
from pathlib import Path
import sys

suffix = f"s5g14-{int(time.time())}-{os.getpid()}"
Path(sys.argv[1]).write_text(json.dumps({
    "user_id": f"{suffix}-ct101-user",
    "email": f"{suffix}@example.invalid",
    "chat_id": f"{suffix}-ct101-chat",
    "token": f"{suffix}-ct101-token",
}))
PYIDS

USER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_id"])' "$IDS_FILE")"
MIRRORED_USER_ID="ct101:${USER_ID}"
EMAIL="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["email"])' "$IDS_FILE")"
CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chat_id"])' "$IDS_FILE")"
TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"

echo
echo "=== start temporary laptop controller with trusted secret ==="
rm -f "$CTRL_LOG" "$WRAP_LOG"

EDGE_TRUSTED_PROXY_SECRET="$EDGE_SECRET" \
LAPTOP_CHAT_QUEUE_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1 \
LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1 \
env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$CTRL_PORT" >"$CTRL_LOG" 2>&1 &

CTRL_PID="$!"

for _ in $(seq 1 60); do
  if curl -fsS "$CTRL_BASE/health" >/dev/null 2>&1; then break; fi
  sleep 0.25
done
curl -fsS "$CTRL_BASE/health" >/dev/null || { cat "$CTRL_LOG"; exit 1; }

echo "ok: controller listening on $CTRL_BASE"

echo
echo "=== direct controller without trusted edge must fail ==="
fail_body="$(mktemp)"
fail_code="$(curl -s -o "$fail_body" -w "%{http_code}" \
  -X POST "$CTRL_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -d "{\"message\":\"Stage 5G-14 untrusted should fail\",\"chat_id\":\"$CHAT_ID\",\"requested_model\":\"gemma4:e4b\"}")"

cat "$fail_body"
echo
echo "status=$fail_code"

if [ "$fail_code" != "401" ]; then
  echo "FAIL: untrusted direct controller request should be 401, got $fail_code"
  exit 1
fi

echo
echo "=== direct controller with trusted edge creates queued job ==="
create_body="$(mktemp)"
create_code="$(curl -s -o "$create_body" -w "%{http_code}" \
  -X POST "$CTRL_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -H "X-Edge-Auth-Secret: $EDGE_SECRET" \
  -H "X-Edge-User-Id: $USER_ID" \
  -H "X-Edge-User-Email: $EMAIL" \
  -H "X-Edge-User-Is-Admin: true" \
  -d "{\"message\":\"Stage 5G-14 trusted edge direct create\",\"chat_id\":\"$CHAT_ID\",\"requested_model\":\"gemma4:e4b\"}")"

cat "$create_body"
echo
echo "status=$create_code"

if [ "$create_code" != "200" ]; then
  echo "FAIL: trusted direct controller create expected 200, got $create_code"
  cat "$CTRL_LOG" || true
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$create_body")"

echo
echo "=== trusted status succeeds ==="
status_body="$(mktemp)"
status_code="$(curl -s -o "$status_body" -w "%{http_code}" \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -H "X-Edge-Auth-Secret: $EDGE_SECRET" \
  -H "X-Edge-User-Id: $USER_ID" \
  -H "X-Edge-User-Email: $EMAIL" \
  -H "X-Edge-User-Is-Admin: true" \
  "$CTRL_BASE/api/chat/queued/$JOB_ID")"

cat "$status_body"
echo
echo "status=$status_code"

if [ "$status_code" != "200" ]; then
  echo "FAIL: trusted status expected 200, got $status_code"
  exit 1
fi

echo
echo "=== verify mirrored rows and exactly one job ==="
python3 - "$MIRRORED_USER_ID" "$CHAT_ID" "$JOB_ID" <<'PYCHECK'
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

user_id, chat_id, job_id = sys.argv[1:4]

checks = {
    "user_count": f"SELECT COUNT(*) FROM app_users WHERE id = {_sql_literal(user_id)};",
    "session_count": f"SELECT COUNT(*) FROM app_sessions WHERE user_id = {_sql_literal(user_id)};",
    "chat_count": f"SELECT COUNT(*) FROM app_chats WHERE id = {_sql_literal(chat_id)} AND user_id = {_sql_literal(user_id)};",
    "job_count": f"SELECT COUNT(*) FROM app_jobs WHERE id = {_sql_literal(job_id)} AND user_id = {_sql_literal(user_id)};",
}

for name, sql in checks.items():
    value = _psql_at(sql).strip()
    print(f"{name}={value}")
    if value != "1":
        raise SystemExit(f"{name} expected 1, got {value}")
PYCHECK

echo
echo "Stage 5G-14 trusted CT101 identity bridge passed."
