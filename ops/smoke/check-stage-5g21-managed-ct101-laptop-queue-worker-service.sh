#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-21 managed CT101 laptop queue worker service verification ==="

source .venv/bin/activate 2>/dev/null || true

PROMPT_FILE="/tmp/stage5g21-live-browser-prompt.txt"

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
echo "=== verify CT101 managed service ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

systemctl is-active --quiet ai-platform-laptop-queue-worker.service

test -f /etc/systemd/system/ai-platform-laptop-queue-worker.service
test -f /etc/ai-platform/laptop-queue-worker.env
test -x /opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh

grep -n "ct101-stage5g21-managed-browser" /etc/ai-platform/laptop-queue-worker.env
grep -n "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /etc/ai-platform/laptop-queue-worker.env
grep -n "LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1" /etc/ai-platform/laptop-queue-worker.env

journalctl -u ai-platform-laptop-queue-worker.service --no-pager -n 80
REMOTE

echo
echo "=== verify saved Stage 5G-21 prompt exists ==="
test -f "$PROMPT_FILE"
PROMPT="$(cat "$PROMPT_FILE")"
echo "prompt=$PROMPT"

echo
echo "=== verify browser job completed by managed worker ==="
python3 - "$PROMPT" <<'PYVERIFY'
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
    raise SystemExit("FAIL: no Stage 5G-21 job found for prompt")

line = rows.splitlines()[0]
parts = line.split("\t")
while len(parts) < 7:
    parts.append("")

job_id, user_id, status, worker_id, requested_model, reply, error_text = parts[:7]

if status != "complete":
    raise SystemExit(f"FAIL: expected complete, got {status!r}")
if worker_id != "ct101-stage5g21-managed-browser":
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

print("ok: Stage 5G-21 managed worker completed browser job")
PYVERIFY

echo
echo "Stage 5G-21 managed CT101 laptop queue worker service verification passed."
