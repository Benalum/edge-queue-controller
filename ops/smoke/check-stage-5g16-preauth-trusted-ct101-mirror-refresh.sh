#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-16 pre-auth trusted CT101 mirror refresh ==="

source .venv/bin/activate 2>/dev/null || true

CTRL_PORT="${STAGE5G16_CTRL_PORT:-17660}"
CTRL_BASE="http://127.0.0.1:${CTRL_PORT}"
CTRL_LOG="/tmp/stage5g16-controller-${CTRL_PORT}.log"
IDS_FILE="/tmp/stage5g16-ids-${CTRL_PORT}.json"
CTRL_PID=""

cleanup() {
  if [ -n "${CTRL_PID:-}" ]; then
    kill "$CTRL_PID" >/dev/null 2>&1 || true
  fi

  python3 - "$IDS_FILE" <<'PYCLEAN' || true
import json
import sys
from pathlib import Path
from edge_modules.chat_queue_persistence import _psql_run, _sql_literal

p = Path(sys.argv[1])
if not p.exists():
    raise SystemExit(0)

ids = json.loads(p.read_text())
chat_id = ids["chat_id"]
old_user = ids["old_user"]
new_user = ids["new_user"]

_psql_run(f"""
BEGIN;
DELETE FROM app_jobs WHERE user_id IN ({_sql_literal(old_user)}, {_sql_literal(new_user)});
DELETE FROM app_messages WHERE chat_id = {_sql_literal(chat_id)};
DELETE FROM app_chats WHERE id = {_sql_literal(chat_id)};
DELETE FROM app_sessions WHERE user_id IN ({_sql_literal(old_user)}, {_sql_literal(new_user)});
DELETE FROM app_users WHERE id IN ({_sql_literal(old_user)}, {_sql_literal(new_user)});
COMMIT;
""")
p.unlink(missing_ok=True)
PYCLEAN
}
trap cleanup EXIT

echo
echo "=== syntax and markers ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js

grep -n "STAGE_5G16_PREAUTH_TRUSTED_CT101_REFRESH_V1" edge_controller.py
grep -n "STAGE_5G16_PREAUTH_TRUSTED_CT101_STATUS_REFRESH_V1" edge_controller.py
grep -n "STAGE_5G14_TRUSTED_CT101_IDENTITY_BRIDGE_V1" edge_controller.py
grep -n "STAGE_5G14_FORWARD_TRUSTED_CT101_IDENTITY_TO_CONTROLLER_V1" frontend/wrapper-ui/dev_server.py

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi

echo "ok: app.js identity safety"

EDGE_SECRET="$(grep '^EDGE_TRUSTED_PROXY_SECRET=' "$HOME/.config/ai-platform-controller/runtime/wrapper.env" | sed 's/^EDGE_TRUSTED_PROXY_SECRET=//')"
if [ -z "$EDGE_SECRET" ]; then
  echo "FAIL: missing EDGE_TRUSTED_PROXY_SECRET in wrapper.env" >&2
  exit 1
fi

echo
echo "=== create stale mirror fixture ==="
python3 - "$IDS_FILE" <<'PYFIX'
import json
import os
import time
from pathlib import Path
import sys

suffix = f"s5g16-{int(time.time())}-{os.getpid()}"
Path(sys.argv[1]).write_text(json.dumps({
    "chat_id": f"{suffix}-chat",
    "old_raw": f"{suffix}-old",
    "new_raw": f"{suffix}-new",
    "old_user": f"ct101:{suffix}-old",
    "new_user": f"ct101:{suffix}-new",
    "old_email": f"{suffix}-old@example.invalid",
    "new_email": f"{suffix}-new@example.invalid",
    "token": f"{suffix}-shared-token",
}))
PYFIX

CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chat_id"])' "$IDS_FILE")"
OLD_RAW="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["old_raw"])' "$IDS_FILE")"
NEW_RAW="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["new_raw"])' "$IDS_FILE")"
OLD_USER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["old_user"])' "$IDS_FILE")"
NEW_USER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["new_user"])' "$IDS_FILE")"
OLD_EMAIL="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["old_email"])' "$IDS_FILE")"
NEW_EMAIL="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["new_email"])' "$IDS_FILE")"
TOKEN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["token"])' "$IDS_FILE")"

python3 - "$CHAT_ID" "$OLD_USER" "$OLD_EMAIL" "$TOKEN" <<'PYSTALE'
import sys
from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

chat_id, old_user, old_email, token = sys.argv[1:5]
session_id = "ct101-edge-session-stale-stage5g16"
token_hash = hash_session_token(token)

_psql_run(f"""
BEGIN;

INSERT INTO app_users (id, email, display_name, password_hash, is_active, is_admin, created_at, updated_at)
VALUES ({_sql_literal(old_user)}, {_sql_literal(old_email)}, 'old', NULL, TRUE, FALSE, now(), now())
ON CONFLICT (id) DO UPDATE SET updated_at = now();

INSERT INTO app_sessions (id, user_id, token_hash, created_at, expires_at, revoked_at)
VALUES ({_sql_literal(session_id)}, {_sql_literal(old_user)}, {_sql_literal(token_hash)}, now(), now() + interval '12 hours', NULL)
ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id, token_hash = EXCLUDED.token_hash, expires_at = EXCLUDED.expires_at, revoked_at = NULL;

INSERT INTO app_chats (id, user_id, mode, title, model, created_at, updated_at, deleted_at)
VALUES ({_sql_literal(chat_id)}, {_sql_literal(old_user)}, 'chat', 'stale chat', 'gemma4:e4b', now(), now(), NULL)
ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id, updated_at = now(), deleted_at = NULL;

COMMIT;
""")
PYSTALE

echo "stale fixture created: chat=$CHAT_ID old_user=$OLD_USER new_user=$NEW_USER"

echo
echo "=== start temporary controller ==="
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

echo "ok: controller listening"

echo
echo "=== trusted create should refresh stale ownership and succeed ==="
body="$(mktemp)"
code="$(curl -s -o "$body" -w "%{http_code}" \
  -X POST "$CTRL_BASE/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -H "X-Edge-Auth-Secret: $EDGE_SECRET" \
  -H "X-Edge-User-Id: $NEW_RAW" \
  -H "X-Edge-User-Email: $NEW_EMAIL" \
  -H "X-Edge-User-Is-Admin: false" \
  -d "{\"message\":\"Stage 5G-16 stale mirror refresh create\",\"chat_id\":\"$CHAT_ID\",\"requested_model\":\"gemma4:e4b\"}")"

cat "$body"
echo
echo "status=$code"

if [ "$code" != "200" ]; then
  echo "FAIL: expected trusted create to succeed after refresh"
  cat "$CTRL_LOG" || true
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$body")"

echo
echo "=== verify refreshed ownership ==="
python3 - "$CHAT_ID" "$OLD_USER" "$NEW_USER" "$JOB_ID" <<'PYCHECK'
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

chat_id, old_user, new_user, job_id = sys.argv[1:5]

values = {
    "chat_new_owner": _psql_at(f"SELECT COUNT(*) FROM app_chats WHERE id = {_sql_literal(chat_id)} AND user_id = {_sql_literal(new_user)};").strip(),
    "job_new_owner": _psql_at(f"SELECT COUNT(*) FROM app_jobs WHERE id = {_sql_literal(job_id)} AND user_id = {_sql_literal(new_user)};").strip(),
    "chat_old_owner": _psql_at(f"SELECT COUNT(*) FROM app_chats WHERE id = {_sql_literal(chat_id)} AND user_id = {_sql_literal(old_user)};").strip(),
}

for k, v in values.items():
    print(f"{k}={v}")

if values["chat_new_owner"] != "1":
    raise SystemExit("chat did not refresh to new owner")
if values["job_new_owner"] != "1":
    raise SystemExit("job was not created under new owner")
if values["chat_old_owner"] != "0":
    raise SystemExit("chat still belongs to stale owner")
PYCHECK

echo
echo "Stage 5G-16 pre-auth trusted CT101 mirror refresh passed."
