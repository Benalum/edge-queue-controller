#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-15 active CT101 queued-mode browser validation ==="

source .venv/bin/activate 2>/dev/null || true

PROMPT="${STAGE5G15_PROMPT:-Stage 5G-15 active CT101 queued browser validation $(date +%s) reply exactly OK}"
WAIT_SECONDS="${STAGE5G15_WAIT_SECONDS:-300}"
FOUND_FILE="/tmp/stage5g15-found-job.json"

rm -f "$FOUND_FILE"
printf '%s\n' "$PROMPT" > /tmp/stage5g15-prompt.txt

echo
echo "=== syntax and runtime safety ==="
python3 -m py_compile edge_controller.py frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED" frontend/wrapper-ui/dev_server.py
grep -n "STAGE_5G14_TRUSTED_CT101_IDENTITY_BRIDGE_V1" edge_controller.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== live runtime flags ==="
CTRL_PID="$(pgrep -f 'uvicorn edge_controller:app.*--port 7070' | head -1 || true)"
WRAP_PID="$(fuser -n tcp 8787 2>/dev/null | awk '{print $1}' || true)"

if [ -z "$CTRL_PID" ] || [ -z "$WRAP_PID" ]; then
  echo "FAIL: missing live controller or wrapper process" >&2
  exit 1
fi

tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -qx 'LAPTOP_CHAT_QUEUE_ENABLED=1'
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -qx 'LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1'
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^EDGE_TRUSTED_PROXY_SECRET='

tr '\0' '\n' < "/proc/$WRAP_PID/environ" | grep -qx 'WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1'
tr '\0' '\n' < "/proc/$WRAP_PID/environ" | grep -qx 'EDGE_CONTROLLER_URL=http://127.0.0.1:7070'
tr '\0' '\n' < "/proc/$WRAP_PID/environ" | grep -q '^EDGE_TRUSTED_PROXY_SECRET='

echo "ok: live controller/wrapper flags present"

echo
echo "=== baseline exact prompt count ==="
python3 - "$PROMPT" <<'PYCHECK'
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

prompt = sys.argv[1]
count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

print("existing_exact_prompt_jobs=" + count)

if count != "0":
    raise SystemExit("prompt already exists in app_jobs")
PYCHECK

echo
echo "============================================================"
echo "MANUAL BROWSER STEP"
echo "============================================================"
echo "Open:"
echo
echo "  http://127.0.0.1:8787/chat?mode=chat"
echo
echo "In DevTools Console run:"
echo
echo '  localStorage.setItem("ai_chat_use_queued", "true");'
echo '  location.href = "/chat?mode=chat";'
echo
echo "After reload, confirm:"
echo
echo '  localStorage.getItem("ai_chat_use_queued")'
echo
echo "Then send this exact prompt:"
echo
echo "  $PROMPT"
echo
echo "Network must show:"
echo
echo "  POST /api/backend/chats/.../messages/queued"
echo
echo "Waiting ${WAIT_SECONDS}s for laptop app_jobs row..."
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

row = _psql_at(f"""
SELECT
  id || E'\t' ||
  COALESCE(user_id, '') || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(payload_json->>'chat_id', '') || E'\t' ||
  COALESCE(requested_model, '')
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')}
ORDER BY created_at DESC
LIMIT 1;
""").strip()

if not row:
    raise SystemExit(1)

parts = row.split("\t")
while len(parts) < 5:
    parts.append("")

out_file.write_text(json.dumps({
    "job_id": parts[0],
    "user_id": parts[1],
    "status": parts[2],
    "chat_id": parts[3],
    "requested_model": parts[4],
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
  echo "FAIL: no laptop queued job found for prompt"
  echo
  echo "Recent wrapper queued/legacy submit lines:"
  grep -E '/api/backend/chats/.*/messages' /tmp/wrapper-ui-8787.log | tail -n 40 || true
  exit 1
fi

echo
echo "=== found laptop queued job ==="
cat "$FOUND_FILE"
echo

echo
echo "=== verify exactly one job and one user message ==="
python3 - "$PROMPT" "$FOUND_FILE" <<'PYCHECK'
import json
import sys
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal

prompt = sys.argv[1]
found = json.load(open(sys.argv[2]))
chat_id = found["chat_id"]

job_count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

user_count = _psql_at(f"""
SELECT COUNT(*)
FROM app_messages
WHERE chat_id = {_sql_literal(chat_id)}
  AND role = 'user'
  AND content = {_sql_literal(prompt)};
""").strip()

assistant_count = _psql_at(f"""
SELECT COUNT(*)
FROM app_messages
WHERE chat_id = {_sql_literal(chat_id)}
  AND role = 'assistant'
  AND content LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

print("job_count=" + job_count)
print("user_count=" + user_count)
print("assistant_count_matching_prompt=" + assistant_count)

if job_count != "1":
    raise SystemExit("expected exactly one job")
if user_count != "1":
    raise SystemExit("expected exactly one user message")
PYCHECK

echo
echo "Stage 5G-15 active CT101 queued-mode browser validation passed."
