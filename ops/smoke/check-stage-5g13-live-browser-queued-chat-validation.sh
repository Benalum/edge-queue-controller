#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-13 live browser queued-chat validation ==="

source .venv/bin/activate 2>/dev/null || true

export PAGER=cat
export PSQL_PAGER=cat

CONTROLLER_BASE="${STAGE5G13_CONTROLLER_BASE:-http://127.0.0.1:7070}"
WRAPPER_BASE="${STAGE5G13_WRAPPER_BASE:-http://127.0.0.1:8787}"
WAIT_SECONDS="${STAGE5G13_WAIT_SECONDS:-300}"
PROMPT="${STAGE5G13_PROMPT:-Stage 5G-13 live browser queued validation $(date +%s) reply exactly OK}"
PROMPT_FILE="/tmp/stage5g13-live-browser-prompt.txt"
FOUND_FILE="/tmp/stage5g13-live-browser-found-job.json"

printf '%s\n' "$PROMPT" > "$PROMPT_FILE"
rm -f "$FOUND_FILE"

echo
echo "=== syntax and runtime safety ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED" frontend/wrapper-ui/dev_server.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== live health ==="
curl -fsS "$CONTROLLER_BASE/health" >/dev/null
curl -fsS "$WRAPPER_BASE/" >/dev/null
echo "ok: controller and wrapper reachable"

echo
echo "=== live process env checks ==="
CTRL_PID="$(pgrep -f 'uvicorn edge_controller:app.*--port 7070' | head -1 || true)"
WRAP_PID="$(fuser -n tcp 8787 2>/dev/null | awk '{print $1}' || true)"

echo "CTRL_PID=$CTRL_PID"
echo "WRAP_PID=$WRAP_PID"

if [ -z "$CTRL_PID" ]; then
  echo "FAIL: could not find live controller pid" >&2
  exit 1
fi

if [ -z "$WRAP_PID" ]; then
  echo "FAIL: could not find live wrapper pid" >&2
  exit 1
fi

tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^LAPTOP_CHAT_QUEUE_ENABLED=1$' || {
  echo "FAIL: live controller missing LAPTOP_CHAT_QUEUE_ENABLED=1" >&2
  exit 1
}

tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1$' || {
  echo "FAIL: live controller missing LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1" >&2
  exit 1
}

tr '\0' '\n' < "/proc/$WRAP_PID/environ" | grep -q '^WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1$' || {
  echo "FAIL: live wrapper missing WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1" >&2
  exit 1
}

echo "ok: live runtime flags are present"

echo
echo "=== baseline queued jobs ==="
baseline_queued="$(python3 - <<'PYCOUNT'
from edge_modules.chat_queue_persistence import _psql_at
print(_psql_at(
    """
    SELECT COUNT(*)
    FROM app_jobs
    WHERE job_type = 'ollama_chat'
      AND status = 'queued';
    """
))
PYCOUNT
)"

echo "baseline_queued=$baseline_queued"

if [ "$baseline_queued" != "0" ] && [ "${STAGE5G13_ALLOW_EXISTING_QUEUED:-0}" != "1" ]; then
  echo "FAIL: existing queued ollama_chat jobs found. Clear them or rerun with STAGE5G13_ALLOW_EXISTING_QUEUED=1" >&2
  exit 1
fi

echo
echo "============================================================"
echo "MANUAL BROWSER STEP"
echo "============================================================"
echo "First verify CT101 backend auth bridge for the active /chat app:"
echo
echo "  $WRAPPER_BASE/login"
echo
echo "In browser DevTools Console, run:"
echo
echo "  fetch('/api/backend/auth/me', { credentials: 'include' }).then(async r => ({ status: r.status, body: await r.text() })).then(console.log)"
echo "  fetch('/api/backend/models', { credentials: 'include' }).then(async r => ({ status: r.status, body: await r.text() })).then(console.log)"
echo
echo "Only continue when both return status 200."
echo
echo "Note: /api/me may return 401 because that is the laptop controller session route,"
echo "but the active /chat UI is CT101-owned and uses /api/backend/* auth."
echo
echo "Then open the live chat page through the laptop wrapper:"
echo
echo "  $WRAPPER_BASE/chat"
echo
echo "Then:"
echo "  1. Select/create a normal chat."
echo "  2. Turn queued chat ON in the CT101 ChatPage UI."
echo "  3. Send this exact prompt:"
echo
echo "  $PROMPT"
echo
echo "The prompt is also saved at:"
echo "  $PROMPT_FILE"
echo
echo "Waiting up to ${WAIT_SECONDS}s for the laptop queued job..."
echo "============================================================"
echo

deadline=$((SECONDS + WAIT_SECONDS))
found=""

while [ "$SECONDS" -lt "$deadline" ]; do
  set +e
  python3 - "$PROMPT" "$FOUND_FILE" <<'PYFIND'
import json
import sys
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

prompt = sys.argv[1]
out_file = Path(sys.argv[2])

needle = "%" + prompt.replace("%", "\\%").replace("_", "\\_") + "%"

row = _psql_at(
    f"""
    SELECT
      id || E'\t' ||
      COALESCE(user_id, '') || E'\t' ||
      COALESCE(status, '') || E'\t' ||
      COALESCE(requested_model, '') || E'\t' ||
      COALESCE(payload_json->>'chat_id', '') || E'\t' ||
      COALESCE(payload_json->>'user_message_id', '')
    FROM app_jobs
    WHERE job_type = 'ollama_chat'
      AND payload_json::text LIKE {_sql_literal(needle)} ESCAPE '\\'
    ORDER BY created_at DESC
    LIMIT 1;
    """
).strip()

if not row:
    raise SystemExit(1)

parts = row.split("\t")
while len(parts) < 6:
    parts.append("")

out_file.write_text(json.dumps({
    "job_id": parts[0],
    "user_id": parts[1],
    "status": parts[2],
    "requested_model": parts[3],
    "chat_id": parts[4],
    "user_message_id": parts[5],
}, indent=2))

print(row)
PYFIND
  rc=$?
  set -e

  if [ "$rc" = "0" ] && [ -f "$FOUND_FILE" ]; then
    found="1"
    break
  fi

  sleep 2
done

if [ -z "$found" ]; then
  echo "FAIL: no laptop queued job found for browser prompt within ${WAIT_SECONDS}s"
  echo
  echo "Recent wrapper log:"
  tail -n 120 /tmp/wrapper-ui-8787.log || true
  echo
  echo "Recent controller log:"
  tail -n 120 /tmp/edge-controller-7070.log || true
  exit 1
fi

echo
echo "=== found browser-created laptop job ==="
cat "$FOUND_FILE"
echo

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$FOUND_FILE")"
CHAT_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chat_id"])' "$FOUND_FILE")"
USER_MESSAGE_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["user_message_id"])' "$FOUND_FILE")"

echo
echo "=== verify exactly one job for prompt ==="
job_count="$(python3 - "$PROMPT" <<'PYCOUNT'
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
prompt = sys.argv[1]
needle = "%" + prompt.replace("%", "\\%").replace("_", "\\_") + "%"
print(_psql_at(
    f"""
    SELECT COUNT(*)
    FROM app_jobs
    WHERE job_type = 'ollama_chat'
      AND payload_json::text LIKE {_sql_literal(needle)} ESCAPE '\\';
    """
))
PYCOUNT
)"

echo "job_count=$job_count"

if [ "$job_count" != "1" ]; then
  echo "FAIL: expected exactly one laptop job for prompt, got $job_count"
  exit 1
fi

echo
echo "=== verify one browser user message row ==="
user_msg_count="$(python3 - "$CHAT_ID" "$PROMPT" <<'PYCOUNT'
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
chat_id = sys.argv[1]
prompt = sys.argv[2]
print(_psql_at(
    f"""
    SELECT COUNT(*)
    FROM app_messages
    WHERE chat_id = {_sql_literal(chat_id)}
      AND role = 'user'
      AND content = {_sql_literal(prompt)};
    """
))
PYCOUNT
)"

echo "user_msg_count=$user_msg_count"

if [ "$user_msg_count" != "1" ]; then
  echo "FAIL: expected exactly one user message row, got $user_msg_count"
  exit 1
fi

echo
echo "=== verify wrapper has not created assistant rows ==="
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

echo "assistant_count=$assistant_count"

if [ "$assistant_count" != "0" ]; then
  echo "FAIL: expected no assistant rows before worker completion, got $assistant_count"
  exit 1
fi

echo
echo "=== browser queued create validation passed ==="
echo "job_id=$JOB_ID"
echo "chat_id=$CHAT_ID"
echo "user_message_id=$USER_MESSAGE_ID"

echo
echo "Stage 5G-13 live browser queued-chat validation passed."
