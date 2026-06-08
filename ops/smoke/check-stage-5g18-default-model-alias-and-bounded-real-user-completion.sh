#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== Stage 5G-18 default model alias and bounded real-user completion ==="

source .venv/bin/activate 2>/dev/null || true

DEFAULT_MODEL="${AI_PLATFORM_DEFAULT_CHAT_MODEL:-gemma4:e4b}"
EDGE_SECRET="$(grep '^EDGE_TRUSTED_PROXY_SECRET=' "$HOME/.config/ai-platform-controller/runtime/wrapper.env" | sed 's/^EDGE_TRUSTED_PROXY_SECRET=//')"

if [ -z "$EDGE_SECRET" ]; then
  echo "FAIL: EDGE_TRUSTED_PROXY_SECRET missing from wrapper.env" >&2
  exit 1
fi

echo
echo "=== syntax and markers ==="
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
echo "=== live controller env check ==="
CTRL_PID="$(pgrep -f 'uvicorn edge_controller:app.*--port 7070' | head -1 || true)"
if [ -z "$CTRL_PID" ]; then
  echo "FAIL: live controller is not running" >&2
  exit 1
fi

tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^AI_PLATFORM_DEFAULT_CHAT_MODEL='
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -qx 'LAPTOP_CHAT_QUEUE_ENABLED=1'
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -qx 'LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1'
tr '\0' '\n' < "/proc/$CTRL_PID/environ" | grep -q '^EDGE_TRUSTED_PROXY_SECRET='

echo "ok: controller model/queue env is present"

echo
echo "=== create trusted CT101 real-user queued job with requested_model=default ==="
IDS_FILE="/tmp/stage5g18-ids.json"
BODY_FILE="/tmp/stage5g18-create-body.json"

python3 - "$IDS_FILE" <<'PY'
from pathlib import Path
import json
import os
import time

suffix = f"s5g18-{int(time.time())}-{os.getpid()}"
Path("/tmp/stage5g18-ids.json").write_text(json.dumps({
    "raw_user_id": suffix + "-ct101-user",
    "email": suffix + "@example.invalid",
    "chat_id": suffix + "-chat",
    "token": suffix + "-token",
    "prompt": "Stage 5G-18 default model alias real-user bounded completion reply exactly OK",
}, indent=2))
PY

RAW_USER_ID="$(python3 -c 'import json; print(json.load(open("/tmp/stage5g18-ids.json"))["raw_user_id"])')"
EMAIL="$(python3 -c 'import json; print(json.load(open("/tmp/stage5g18-ids.json"))["email"])')"
CHAT_ID="$(python3 -c 'import json; print(json.load(open("/tmp/stage5g18-ids.json"))["chat_id"])')"
TOKEN="$(python3 -c 'import json; print(json.load(open("/tmp/stage5g18-ids.json"))["token"])')"
PROMPT="$(python3 -c 'import json; print(json.load(open("/tmp/stage5g18-ids.json"))["prompt"])')"

CODE="$(curl -s -o "$BODY_FILE" -w "%{http_code}" \
  -X POST "http://127.0.0.1:7070/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Queued-Chat-Session-Token: $TOKEN" \
  -H "X-Edge-Auth-Secret: $EDGE_SECRET" \
  -H "X-Edge-User-Id: $RAW_USER_ID" \
  -H "X-Edge-User-Email: $EMAIL" \
  -H "X-Edge-User-Is-Admin: false" \
  -d "{\"message\":\"$PROMPT\",\"chat_id\":\"$CHAT_ID\",\"requested_model\":\"default\"}")"

cat "$BODY_FILE"
echo
echo "status=$CODE"

if [ "$CODE" != "200" ]; then
  echo "FAIL: create queued job expected HTTP 200" >&2
  exit 1
fi

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$BODY_FILE")"
echo "JOB_ID=$JOB_ID"

echo
echo "=== verify model alias was resolved before storage ==="
python3 - "$JOB_ID" "$DEFAULT_MODEL" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

job_id = sys.argv[1]
expected = sys.argv[2]

row = _psql_at(f"""
SELECT
  COALESCE(requested_model, '') || E'\t' ||
  COALESCE(payload_json->>'requested_model', '')
FROM app_jobs
WHERE id = {_sql_literal(job_id)};
""").strip()

print("model_row=" + row)

parts = row.split("\t")
while len(parts) < 2:
    parts.append("")

requested_model, payload_model = parts[:2]

if requested_model != expected:
    raise SystemExit(f"requested_model expected {expected!r}, got {requested_model!r}")
if payload_model != expected:
    raise SystemExit(f"payload requested_model expected {expected!r}, got {payload_model!r}")
if requested_model == "default" or payload_model == "default":
    raise SystemExit("default alias leaked into stored job")
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
export LAPTOP_QUEUE_WORKER_ID="ct101-stage5g18-bounded-real-user"
export LAPTOP_QUEUE_WORKER_NODE_ID="ct101-stage5g18-bounded-real-user-node"
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
echo "=== verify bounded real-user completion ==="
python3 - "$JOB_ID" <<'PY'
from edge_modules.chat_queue_persistence import _psql_at, _sql_literal
import sys

job_id = sys.argv[1]

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
if worker_id != "ct101-stage5g18-bounded-real-user":
    raise SystemExit(f"unexpected worker_id {worker_id!r}")
if requested_model == "default":
    raise SystemExit("requested_model stayed default")
if not reply:
    raise SystemExit("missing result_json reply")
if error_text:
    raise SystemExit(f"unexpected error_text {error_text!r}")

print("ok: Stage 5G-18 bounded real-user job completed")
PY

echo
echo "Stage 5G-18 default model alias and bounded real-user completion passed."
