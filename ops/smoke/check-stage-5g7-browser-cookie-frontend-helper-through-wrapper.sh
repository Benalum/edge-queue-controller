#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-7 browser-cookie frontend helper through wrapper ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CTRL_PORT="${STAGE5G7_CTRL_PORT:-17370}"
WRAP_PORT="${STAGE5G7_WRAP_PORT:-17371}"
CTRL_BASE="http://127.0.0.1:${CTRL_PORT}"
WRAP_BASE="http://127.0.0.1:${WRAP_PORT}"
CTRL_LOG="/tmp/stage5g7-controller-${CTRL_PORT}.log"
WRAP_LOG="/tmp/stage5g7-wrapper-${WRAP_PORT}.log"
IDS_FILE="/tmp/stage5g7-frontend-helper-ids-${WRAP_PORT}.json"

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
node --check frontend/wrapper-ui/queued_chat_status.js

grep -n "STAGE_5G7_QUEUED_CHAT_COOKIE_TO_SESSION_HEADER_V1" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js
grep -n "credentials: \"include\"" frontend/wrapper-ui/app.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in app.js" >&2
  exit 1
fi

if grep -RIn 'X-Queued-Chat-Session-Token' frontend/wrapper-ui/app.js; then
  echo "FAILED: app.js must not send X-Queued-Chat-Session-Token" >&2
  exit 1
fi

echo "ok: app.js identity/session-token safety"

echo
echo "=== create real-user session rows ==="
python3 - "$IDS_FILE" <<'PYIDS'
import json
import os
import sys
import time
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

ids_file = sys.argv[1]
suffix = f"s5g7-{int(time.time())}-{os.getpid()}"

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
      'Stage 5G-7 Frontend Helper Chat',
      'stage-5g7-model',
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
echo "=== run frontend helper blocks through wrapper with browser cookie ==="
WRAP_BASE="$WRAP_BASE" TOKEN="$TOKEN" CHAT_ID="$CHAT_ID" node - <<'NODE'
const fs = require("fs");
const vm = require("vm");
const statusHelper = require("./frontend/wrapper-ui/queued_chat_status.js");

const source = fs.readFileSync("frontend/wrapper-ui/app.js", "utf8");
const endMarker = "})(typeof window !== \"undefined\" ? window : globalThis);";

function extractBlock(marker) {
  const start = source.indexOf(marker);
  if (start < 0) {
    throw new Error(`missing block marker ${marker}`);
  }

  const end = source.indexOf(endMarker, start);
  if (end < 0) {
    throw new Error(`missing end marker for ${marker}`);
  }

  return source.slice(start, end + endMarker.length);
}

const sendBlock = extractBlock("(function stage5f32QueuedChatSendBranch(root)");
const pollBlock = extractBlock("(function stage5f35QueuedChatStatusPollBranch(root)");

const nativeFetch = fetch;
const calls = [];

const context = {
  console,
  encodeURIComponent,
  QueuedChatStatusHelper: statusHelper,
  AI_PLATFORM_QUEUED_CHAT_ENABLED: true,
  fetch: async (url, options = {}) => {
    const helperHeaders = Object.assign({}, options.headers || {});
    const helperHeaderNames = Object.keys(helperHeaders).map((x) => x.toLowerCase());

    if (helperHeaderNames.includes("x-queued-chat-session-token")) {
      throw new Error("frontend helper must not send X-Queued-Chat-Session-Token");
    }

    if (helperHeaderNames.includes("x-synthetic-user-id")) {
      throw new Error("frontend helper must not send X-Synthetic-User-Id");
    }

    if (helperHeaderNames.includes("user_id") || helperHeaderNames.includes("authenticated_user_id")) {
      throw new Error("frontend helper must not send identity headers");
    }

    let bodyObject = null;
    if (options.body) {
      bodyObject = JSON.parse(options.body);
      if (Object.prototype.hasOwnProperty.call(bodyObject, "user_id")) {
        throw new Error("frontend helper body must not contain user_id");
      }
      if (Object.prototype.hasOwnProperty.call(bodyObject, "authenticated_user_id")) {
        throw new Error("frontend helper body must not contain authenticated_user_id");
      }
      if (Object.prototype.hasOwnProperty.call(bodyObject, "X-Synthetic-User-Id")) {
        throw new Error("frontend helper body must not contain X-Synthetic-User-Id");
      }
    }

    calls.push({
      url,
      method: options.method || "GET",
      credentials: options.credentials,
      helperHeaders,
      bodyObject,
    });

    const upstreamUrl = url.startsWith("http")
      ? url
      : `${process.env.WRAP_BASE}${url}`;

    const headers = Object.assign({}, helperHeaders, {
      Cookie: `edgeStudyToken=${process.env.TOKEN}`,
    });

    return nativeFetch(upstreamUrl, {
      ...options,
      headers,
    });
  },
};

vm.createContext(context);
vm.runInContext(sendBlock, context);
vm.runInContext(pollBlock, context);

(async () => {
  const sendBranch = context.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH;
  const pollBranch = context.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;

  if (!sendBranch || typeof sendBranch.sendQueuedChat !== "function") {
    throw new Error("sendQueuedChat helper missing");
  }

  if (!pollBranch || typeof pollBranch.pollQueuedChatStatus !== "function") {
    throw new Error("pollQueuedChatStatus helper missing");
  }

  if (sendBranch.wiredToSubmit !== false) {
    throw new Error("send helper must remain unwired");
  }

  if (pollBranch.pollerWired !== false) {
    throw new Error("poll helper must remain unwired");
  }

  const created = await sendBranch.sendQueuedChat({
    message: "Stage 5G-7 frontend helper queued chat",
    chat_id: process.env.CHAT_ID,
    requested_model: "stage-5g7-model",
    user_id: "must-not-send",
    authenticated_user_id: "must-not-send",
    "X-Synthetic-User-Id": "must-not-send",
    extra: "must-not-send",
  });

  if (!created || created.ok !== true || !created.job_id) {
    throw new Error("frontend helper create failed: " + JSON.stringify(created));
  }

  const status = await pollBranch.pollQueuedChatStatus(created.job_id, { elapsedMs: 1000 });

  if (!status || status.ok !== true || !status.job) {
    throw new Error("frontend helper status failed: " + JSON.stringify(status));
  }

  if (status.job.status !== "queued") {
    throw new Error("expected queued status, got " + JSON.stringify(status.job));
  }

  if (calls.length !== 2) {
    throw new Error("expected exactly 2 helper fetch calls, got " + calls.length);
  }

  const createCall = calls[0];
  const statusCall = calls[1];

  if (createCall.url !== "/api/chat/queued" || createCall.method !== "POST") {
    throw new Error("unexpected create call: " + JSON.stringify(createCall));
  }

  if (statusCall.url !== `/api/chat/queued/${encodeURIComponent(created.job_id)}` || statusCall.method !== "GET") {
    throw new Error("unexpected status call: " + JSON.stringify(statusCall));
  }

  if (createCall.credentials !== "include" || statusCall.credentials !== "include") {
    throw new Error("frontend helper must use credentials include");
  }

  console.log("OK: frontend helper created and read queued job through wrapper using browser cookie");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE

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
echo "=== previous wrapper route smoke ==="
bash ops/smoke/check-stage-5g6-wrapper-to-controller-real-user-queued-chat-route.sh

echo
echo "Stage 5G-7 browser-cookie frontend helper through wrapper passed."
