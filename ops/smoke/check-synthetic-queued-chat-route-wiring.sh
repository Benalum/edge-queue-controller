#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== synthetic queued chat route wiring smoke ==="

source .venv/bin/activate 2>/dev/null || true

PORT="${SYNTHETIC_QUEUED_CHAT_ROUTE_SMOKE_PORT:-7113}"
BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/synthetic-queued-chat-route-$PORT.log"

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_fixed() {
  local file="$1"
  local text="$2"
  local label="$3"

  if grep -F -n "$text" "$file" >/dev/null 2>&1; then
    echo "OK: $label"
  else
    echo "FAIL: missing $label"
    echo "  file: $file"
    echo "  text: $text"
    exit 1
  fi
}

require_file docs/synthetic-queued-chat-route-wiring.md
require_file edge_controller.py
require_file edge_modules/chat_queue_creation.py

require_fixed edge_controller.py "Stage 5F-9: synthetic-only queued chat route wiring" "route marker"
require_fixed edge_controller.py "LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY" "synthetic-only flag"
require_fixed edge_controller.py "X-Synthetic-User-Id" "synthetic user header"
require_fixed edge_controller.py "synthetic_only_required_stage_5f9" "synthetic-only guard"
require_fixed edge_controller.py "_s5f9_create_synthetic_queued_chat_job" "creation helper wiring"
require_fixed edge_controller.py "non_synthetic_job_refused" "non-synthetic job guard"
require_fixed docs/synthetic-queued-chat-route-wiring.md "does not change default production chat behavior" "no default production change"
require_fixed docs/synthetic-queued-chat-route-wiring.md "create real production chat jobs" "no real jobs"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_creation.py \
  edge_modules/chat_queue_persistence.py

SERVER_PID=""

stop_server() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}

start_server() {
  local mode="$1"

  stop_server

  if [ "$mode" = "disabled" ]; then
    env -u LAPTOP_CHAT_QUEUE_ENABLED -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
      python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &
  elif [ "$mode" = "enabled_only" ]; then
    LAPTOP_CHAT_QUEUE_ENABLED=1 env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
      python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &
  else
    LAPTOP_CHAT_QUEUE_ENABLED=1 LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1 \
      python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &
  fi

  SERVER_PID="$!"

  for _ in $(seq 1 40); do
    if curl -s "$BASE_URL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done

  echo "FAIL: temporary server did not start"
  cat "$LOG_FILE" || true
  exit 1
}

trap 'stop_server || true' EXIT

start_server disabled

disabled_body="$(mktemp)"
disabled_code="$(curl -s -o "$disabled_body" -w "%{http_code}" "$BASE_URL/api/chat/queued/smoke-job")"

if [ "$disabled_code" != "404" ]; then
  echo "FAIL: disabled GET expected 404, got $disabled_code"
  cat "$disabled_body"
  exit 1
fi

grep -q "feature_disabled" "$disabled_body" || {
  echo "FAIL: disabled route missing feature_disabled"
  cat "$disabled_body"
  exit 1
}

echo "OK: queued chat route remains disabled by default"

start_server enabled_only

enabled_only_body="$(mktemp)"
enabled_only_code="$(curl -s -o "$enabled_only_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"should not create production job"}')"

if [ "$enabled_only_code" != "501" ]; then
  echo "FAIL: enabled-only POST expected 501, got $enabled_only_code"
  cat "$enabled_only_body"
  exit 1
fi

grep -q "synthetic_only_required_stage_5f9" "$enabled_only_body" || {
  echo "FAIL: enabled-only POST missing synthetic_only_required_stage_5f9"
  cat "$enabled_only_body"
  exit 1
}

echo "OK: enabled route refuses non-synthetic mode"

start_server synthetic

python3 - <<'PY' > /tmp/s5f9-route-ids.json
import json
import os
import time

from edge_modules.chat_queue_creation import setup_synthetic_chat_queue_creation_rows

suffix = f"{int(time.time())}-{os.getpid()}"
ids = setup_synthetic_chat_queue_creation_rows(suffix=suffix)
ids["suffix"] = suffix
print(json.dumps(ids))
PY

SYNTHETIC_USER_ID="$(python3 -c 'import json; print(json.load(open("/tmp/s5f9-route-ids.json"))["user_id"])')"

created_body="$(mktemp)"
created_code="$(curl -s -o "$created_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -H "X-Synthetic-User-Id: $SYNTHETIC_USER_ID" \
  -d '{"message":"Stage 5F-9 route-created queued chat","requested_model":"stage-5f9-synthetic-model"}')"

if [ "$created_code" != "200" ]; then
  echo "FAIL: synthetic POST expected 200, got $created_code"
  cat "$created_body"
  exit 1
fi

grep -q '"ok":true' "$created_body" || {
  echo "FAIL: synthetic POST missing ok true"
  cat "$created_body"
  exit 1
}

JOB_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["job_id"])' "$created_body")"

status_body="$(mktemp)"
status_code="$(curl -s -o "$status_body" -w "%{http_code}" "$BASE_URL/api/chat/queued/$JOB_ID")"

if [ "$status_code" != "200" ]; then
  echo "FAIL: synthetic GET expected 200, got $status_code"
  cat "$status_body"
  exit 1
fi

grep -q '"status":"queued"' "$status_body" || {
  echo "FAIL: synthetic GET missing queued status"
  cat "$status_body"
  exit 1
}

python3 - <<'PY'
import json

from edge_modules.chat_queue_creation import cleanup_synthetic_chat_queue_creation_rows
from edge_modules.chat_queue_persistence import _psql_at

ids = json.load(open("/tmp/s5f9-route-ids.json"))
cleanup_synthetic_chat_queue_creation_rows(suffix=ids["suffix"])

leftover = _psql_at("SELECT COUNT(*) FROM app_users WHERE id LIKE 's5f8-user-%';")
assert leftover == "0", leftover
PY

echo "OK: synthetic queued chat route created and read queued job"

stop_server
trap - EXIT

echo "PASS: synthetic queued chat route wiring smoke passed"
