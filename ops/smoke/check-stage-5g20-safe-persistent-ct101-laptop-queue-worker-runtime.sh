#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-20 safe persistent CT101 laptop queue worker runtime verification ==="

source .venv/bin/activate 2>/dev/null || true

PROMPT_FILE="/tmp/stage5g20-live-browser-prompt.txt"

echo
echo "=== syntax and safety ==="
python3 -m py_compile edge_controller.py
python3 -m py_compile edge_modules/chat_queue_real_user_creation.py
python3 -m py_compile frontend/wrapper-ui/dev_server.py
node --check frontend/wrapper-ui/app.js
node --check frontend/wrapper-ui/queued_chat_config.js

grep -n "STAGE_5G18_DEFAULT_MODEL_ALIAS_RESOLVER_V1" edge_modules/chat_queue_real_user_creation.py
grep -n "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" frontend/wrapper-ui/queued_chat_config.js

if grep -RInE 'user_id|authenticated_user_id|X-Synthetic-User-Id' frontend/wrapper-ui/app.js; then
  echo "FAILED: forbidden identity reference found in wrapper app.js" >&2
  exit 1
fi

echo "ok: wrapper app.js identity safety"

echo
echo "=== verify CT101 Stage 5G-20 worker is running ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

PID_FILE="/tmp/stage5g20-ct101-laptop-queue-worker.pid"
LOG_FILE="/tmp/stage5g20-ct101-laptop-queue-worker.log"

test -f "$PID_FILE"
test -f "$LOG_FILE"

pid="$(cat "$PID_FILE")"
kill -0 "$pid"

echo "worker_pid=$pid"
grep -n "ct101-stage5g20-persistent-browser" "$LOG_FILE" | tail -n 5 || true
tail -n 60 "$LOG_FILE"
REMOTE

echo
echo "=== verify saved Stage 5G-20 prompt exists ==="
test -f "$PROMPT_FILE"
PROMPT="$(cat "$PROMPT_FILE")"
echo "prompt=$PROMPT"

echo
echo "=== verify browser job completed by persistent worker ==="
python3 - "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

prompt = sys.argv[1]

rows = _psql_at(f"""
SELECT
  id || E'\t' ||
  COALESCE(user_id, '') || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(assigned_worker_id, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  LEFT(COALESCE(result_json->>'reply', ''), 180) || E'\t' ||
  COALESCE(error_text, '')
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')}
ORDER BY created_at DESC
LIMIT 5;
""").strip()

print(rows)

if not rows:
    raise SystemExit("FAIL: no Stage 5G-20 job found for prompt")

line = rows.splitlines()[0]
parts = line.split("\t")
while len(parts) < 7:
    parts.append("")

job_id, user_id, status, worker_id, requested_model, reply, error_text = parts[:7]

if status != "complete":
    raise SystemExit(f"FAIL: expected complete, got {status!r}")
if worker_id != "ct101-stage5g20-persistent-browser":
    raise SystemExit(f"FAIL: unexpected worker_id {worker_id!r}")
if requested_model == "default" or not requested_model:
    raise SystemExit("FAIL: requested_model was not resolved")
if not reply:
    raise SystemExit("FAIL: missing reply")
if error_text:
    raise SystemExit(f"FAIL: unexpected error_text {error_text!r}")

count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

print("exact_prompt_job_count=" + count)

if count != "1":
    raise SystemExit(f"FAIL: expected exactly one matching job, got {count}")

print("ok: Stage 5G-20 persistent worker completed browser job")
PY

echo
echo "Stage 5G-20 safe persistent CT101 laptop queue worker runtime verification passed."
