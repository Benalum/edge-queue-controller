#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat route guard placeholder smoke ==="

source .venv/bin/activate 2>/dev/null || true

PORT="${REAL_USER_QUEUED_CHAT_GUARD_PLACEHOLDER_PORT:-7115}"
BASE_URL="http://127.0.0.1:$PORT"
LOG_FILE="/tmp/s5f14-real-user-route-guard-$PORT.log"

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

require_file docs/real-user-queued-chat-route-guard-placeholder.md
require_file edge_controller.py
require_file edge_modules/chat_queue_real_user_guard.py

require_fixed edge_controller.py "session_auth_not_wired_stage_5f14" "real-user placeholder marker"
require_fixed edge_controller.py "LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED" "real-user route flag"
require_fixed docs/real-user-queued-chat-route-guard-placeholder.md "does not enable real-user queued chat" "does not enable real users"
require_fixed docs/real-user-queued-chat-route-guard-placeholder.md "no real jobs are created" "no real jobs"

python3 -m py_compile \
  edge_controller.py \
  edge_modules/chat_queue_real_user_guard.py

SERVER_PID=""

stop_server() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}

trap 'stop_server || true' EXIT

LAPTOP_CHAT_QUEUE_ENABLED=1 LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 \
  env -u LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY \
  python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG_FILE" 2>&1 &

SERVER_PID="$!"

for _ in $(seq 1 40); do
  if curl -s "$BASE_URL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

post_body="$(mktemp)"
post_code="$(curl -s -o "$post_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"real user should not be wired yet"}')"

if [ "$post_code" != "501" ]; then
  echo "FAIL: real-user placeholder POST expected 501, got $post_code"
  cat "$post_body"
  exit 1
fi

grep -q "session_auth_not_wired_stage_5f14" "$post_body" || {
  echo "FAIL: POST missing session_auth_not_wired_stage_5f14"
  cat "$post_body"
  exit 1
}

get_body="$(mktemp)"
get_code="$(curl -s -o "$get_body" -w "%{http_code}" "$BASE_URL/api/chat/queued/not-a-real-job")"

if [ "$get_code" != "501" ]; then
  echo "FAIL: real-user placeholder GET expected 501, got $get_code"
  cat "$get_body"
  exit 1
fi

grep -q "session_auth_not_wired_stage_5f14" "$get_body" || {
  echo "FAIL: GET missing session_auth_not_wired_stage_5f14"
  cat "$get_body"
  exit 1
}

echo "OK: real-user queued chat route refuses until session auth is wired"

stop_server
trap - EXIT

echo "PASS: real-user queued chat route guard placeholder smoke passed"
