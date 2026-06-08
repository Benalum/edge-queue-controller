#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-19 live browser bounded worker completion ==="

source .venv/bin/activate 2>/dev/null || true

PROMPT="${STAGE5G19_PROMPT:-Stage 5G-19 live browser bounded worker completion $(date +%s) reply exactly OK}"
PROMPT_FILE="/tmp/stage5g19-live-browser-prompt.txt"
FOUND_FILE="/tmp/stage5g19-found-job.json"

printf "%s" "$PROMPT" > "$PROMPT_FILE"
rm -f "$FOUND_FILE"

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
echo "=== live runtime checks ==="
curl -fsS http://127.0.0.1:7070/health >/dev/null
curl -fsS http://127.0.0.1:8787/ >/dev/null

CTRL_PID="$(fuser -n tcp 7070 2>/dev/null | awk '{print $1}' | head -1)"
WRAP_PID="$(fuser -n tcp 8787 2>/dev/null | awk '{print $1}' | head -1)"

if [ -z "$CTRL_PID" ] || [ -z "$WRAP_PID" ]; then
  echo "FAIL: controller or wrapper is not running" >&2
  exit 1
fi

tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -qx 'LAPTOP_CHAT_QUEUE_ENABLED=1'
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -qx 'LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1'
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^AI_PLATFORM_DEFAULT_CHAT_MODEL='
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^EDGE_TRUSTED_PROXY_SECRET='
tr '\0' '\n' < "/proc/$WRAP_PID/environ" | grep -qx 'WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1'
tr '\0' '\n' < "/proc/$WRAP_PID/environ" | grep -q '^EDGE_TRUSTED_PROXY_SECRET='

echo "ok: live controller/wrapper runtime flags present"

echo
echo "=== baseline exact prompt count ==="
python3 - "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

prompt = sys.argv[1]
count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()
print("existing_exact_prompt_jobs=" + count)
if count != "0":
    raise SystemExit("FAIL: exact Stage 5G-19 prompt already exists")
PY

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
echo "The prompt is saved at:"
echo "  $PROMPT_FILE"
echo
echo "Waiting up to 300s for laptop app_jobs row..."
echo "============================================================"
echo

deadline=$((SECONDS + 300))

while [ "$SECONDS" -lt "$deadline" ]; do
  set +e
  python3 - "$PROMPT" "$FOUND_FILE" <<'PYFIND'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import json
import sys
from pathlib import Path

prompt = sys.argv[1]
out = Path(sys.argv[2])

rows = _psql_at(f"""
SELECT
  id || E'\t' ||
  COALESCE(user_id, '') || E'\t' ||
  COALESCE(status, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  COALESCE(payload_json->>'chat_id', '')
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')}
ORDER BY created_at DESC
LIMIT 5;
""").strip()

if not rows:
    raise SystemExit(1)

print(rows)
line = rows.splitlines()[0]
parts = line.split("\t")
while len(parts) < 5:
    parts.append("")

job_id, user_id, status, requested_model, chat_id = parts[:5]
out.write_text(json.dumps({
    "job_id": job_id,
    "user_id": user_id,
    "status": status,
    "requested_model": requested_model,
    "chat_id": chat_id,
}, indent=2))
PYFIND
  rc=$?
  set -e

  if [ "$rc" = "0" ] && [ -f "$FOUND_FILE" ]; then
    break
  fi

  sleep 2
done

if [ ! -f "$FOUND_FILE" ]; then
  echo "FAIL: no laptop queued job found for Stage 5G-19 prompt within 300s" >&2
  echo
  echo "Recent wrapper log:"
  tail -n 160 /tmp/wrapper-ui-8787.log || true
  exit 1
fi

echo
echo "=== found browser-created laptop job ==="
cat "$FOUND_FILE"
echo

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$FOUND_FILE")"

echo
echo "=== verify browser-created job stored resolved model ==="
python3 - "$JOB_ID" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

job_id = sys.argv[1]

row = _psql_at(f"""
SELECT
  COALESCE(status, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  COALESCE(payload_json->>'requested_model', '')
FROM app_jobs
WHERE id = {_sql_literal(job_id)};
""").strip()

print("job_model_row=" + row)

parts = row.split("\t")
while len(parts) < 3:
    parts.append("")

status, requested_model, payload_model = parts[:3]

if status != "queued":
    raise SystemExit(f"expected queued before worker run, got {status!r}")
if requested_model == "default" or payload_model == "default":
    raise SystemExit("default alias leaked into browser-created job")
if not requested_model or not payload_model:
    raise SystemExit("missing resolved model")
PY

echo
echo "=== run CT101 bounded real-user Ollama poller ==="
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

cd /opt/ai-platform

set -a
[ -f .secrets/laptop-queue.env ] && source .secrets/laptop-queue.env
[ -f .env ] && source .env
set +a

export PYTHONPATH=/opt/ai-platform/backend
export LAPTOP_QUEUE_ENABLED=1
export LAPTOP_QUEUE_SYNTHETIC_ONLY=0
export LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1
export LAPTOP_QUEUE_BASE_URL="${LAPTOP_QUEUE_BASE_URL:-http://100.108.171.94:7070}"
export LAPTOP_QUEUE_TOKEN_FILE="${LAPTOP_QUEUE_TOKEN_FILE:-/opt/ai-platform/.secrets/laptop-queue.env}"
export LAPTOP_QUEUE_WORKER_ID="ct101-stage5g19-bounded-browser"
export LAPTOP_QUEUE_WORKER_NODE_ID="ct101-stage5g19-bounded-browser-node"
export LAPTOP_QUEUE_JOB_TYPES=ollama_chat
export LAPTOP_QUEUE_POLL_MODE=bounded
export LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1
export LAPTOP_QUEUE_MAX_IDLE_POLLS=1
export LAPTOP_QUEUE_POLL_INTERVAL_SECONDS=1
export LAPTOP_QUEUE_EXECUTION_MODE=ollama
export LAPTOP_QUEUE_OLLAMA_BASE_URL="${LAPTOP_QUEUE_OLLAMA_BASE_URL:-http://100.88.245.33:11434}"
export LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK=gemma4:e4b
export LAPTOP_QUEUE_OLLAMA_TIMEOUT_SECONDS=120
export LAPTOP_QUEUE_OLLAMA_NUM_PREDICT=64

python3 ops/smoke/laptop_queue_bounded_synthetic_poller.py
REMOTE

echo
echo "=== verify browser job completed ==="
python3 - "$JOB_ID" "$PROMPT" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

job_id = sys.argv[1]
prompt = sys.argv[2]

row = _psql_at(f"""
SELECT
  COALESCE(status, '') || E'\t' ||
  COALESCE(assigned_worker_id, '') || E'\t' ||
  COALESCE(requested_model, '') || E'\t' ||
  LEFT(COALESCE(result_json->>'reply', ''), 220) || E'\t' ||
  COALESCE(error_text, '')
FROM app_jobs
WHERE id = {_sql_literal(job_id)};
""").strip()

print("job_result=" + row)

parts = row.split("\t")
while len(parts) < 5:
    parts.append("")

status, worker_id, requested_model, reply, error_text = parts[:5]

if status != "complete":
    raise SystemExit(f"expected complete, got {status!r}")
if worker_id != "ct101-stage5g19-bounded-browser":
    raise SystemExit(f"unexpected worker_id {worker_id!r}")
if requested_model == "default":
    raise SystemExit("requested_model stayed default")
if not reply:
    raise SystemExit("missing result_json reply")
if error_text:
    raise SystemExit(f"unexpected error_text {error_text!r}")

count = _psql_at(f"""
SELECT COUNT(*)
FROM app_jobs
WHERE job_type = 'ollama_chat'
  AND payload_json::text LIKE {_sql_literal('%' + prompt + '%')};
""").strip()

print("exact_prompt_job_count=" + count)

if count != "1":
    raise SystemExit(f"expected exactly one matching job, got {count}")

print("ok: Stage 5G-19 browser-created job completed")
PY

echo
echo "Stage 5G-19 live browser bounded worker completion passed."
