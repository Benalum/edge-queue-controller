#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== queued chat route skeleton smoke ==="

source .venv/bin/activate 2>/dev/null || true

PORT="${QUEUED_CHAT_ROUTE_SKELETON_SMOKE_PORT:-7112}"
BASE_URL="http://127.0.0.1:$PORT"

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

require_file docs/queued-chat-route-skeleton.md
require_file edge_controller.py

require_fixed edge_controller.py "Stage 5F-7: disabled-by-default queued chat route skeleton" "route marker"
require_fixed edge_controller.py '@app.post("/api/chat/queued")' "POST route"
require_fixed edge_controller.py '@app.get("/api/chat/queued/{job_id}")' "GET route"
require_fixed edge_controller.py "LAPTOP_CHAT_QUEUE_ENABLED" "feature flag"
require_fixed edge_controller.py "feature_disabled" "disabled marker"
require_fixed edge_controller.py "not_implemented_stage_5f7" "enabled skeleton marker"
require_fixed docs/queued-chat-route-skeleton.md "does not change production chat behavior" "no production behavior change"
require_fixed docs/queued-chat-route-skeleton.md "create real production chat jobs" "no real jobs"

python3 -m py_compile edge_controller.py

start_server() {
  local enabled_value="$1"
  local log_file="$2"

  if [ "$enabled_value" = "enabled" ]; then
    LAPTOP_CHAT_QUEUE_ENABLED=1 python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$log_file" 2>&1 &
  else
    env -u LAPTOP_CHAT_QUEUE_ENABLED python -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$log_file" 2>&1 &
  fi

  SERVER_PID="$!"

  for _ in $(seq 1 40); do
    if curl -fsS "$BASE_URL/health" >/dev/null 2>&1 || curl -s "$BASE_URL/api/chat/queued/smoke-job" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done

  echo "FAIL: temporary server did not start"
  cat "$log_file" || true
  exit 1
}

stop_server() {
  kill "$SERVER_PID" >/dev/null 2>&1 || true
  wait "$SERVER_PID" >/dev/null 2>&1 || true
}

LOG_DISABLED="/tmp/queued-chat-route-disabled-$PORT.log"
LOG_ENABLED="/tmp/queued-chat-route-enabled-$PORT.log"

SERVER_PID=""
trap 'stop_server || true' EXIT

start_server disabled "$LOG_DISABLED"

disabled_get_body="$(mktemp)"
disabled_get_code="$(curl -s -o "$disabled_get_body" -w "%{http_code}" "$BASE_URL/api/chat/queued/smoke-job")"

if [ "$disabled_get_code" != "404" ]; then
  echo "FAIL: disabled GET expected 404, got $disabled_get_code"
  cat "$disabled_get_body"
  exit 1
fi

grep -q "feature_disabled" "$disabled_get_body" || {
  echo "FAIL: disabled GET missing feature_disabled"
  cat "$disabled_get_body"
  exit 1
}

disabled_post_body="$(mktemp)"
disabled_post_code="$(curl -s -o "$disabled_post_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"hello from disabled smoke"}')"

if [ "$disabled_post_code" != "404" ]; then
  echo "FAIL: disabled POST expected 404, got $disabled_post_code"
  cat "$disabled_post_body"
  exit 1
fi

grep -q "feature_disabled" "$disabled_post_body" || {
  echo "FAIL: disabled POST missing feature_disabled"
  cat "$disabled_post_body"
  exit 1
}

echo "OK: queued chat routes are disabled by default"

stop_server
trap 'stop_server || true' EXIT

start_server enabled "$LOG_ENABLED"

enabled_get_body="$(mktemp)"
enabled_get_code="$(curl -s -o "$enabled_get_body" -w "%{http_code}" "$BASE_URL/api/chat/queued/smoke-job")"

if [ "$enabled_get_code" != "501" ]; then
  echo "FAIL: enabled GET expected 501, got $enabled_get_code"
  cat "$enabled_get_body"
  exit 1
fi

grep -q "not_implemented_stage_5f7" "$enabled_get_body" || {
  echo "FAIL: enabled GET missing not_implemented_stage_5f7"
  cat "$enabled_get_body"
  exit 1
}

enabled_post_body="$(mktemp)"
enabled_post_code="$(curl -s -o "$enabled_post_body" -w "%{http_code}" \
  -X POST "$BASE_URL/api/chat/queued" \
  -H 'Content-Type: application/json' \
  -d '{"message":"hello from enabled smoke","requested_model":"synthetic"}')"

if [ "$enabled_post_code" != "501" ]; then
  echo "FAIL: enabled POST expected 501, got $enabled_post_code"
  cat "$enabled_post_body"
  exit 1
fi

grep -q "not_implemented_stage_5f7" "$enabled_post_body" || {
  echo "FAIL: enabled POST missing not_implemented_stage_5f7"
  cat "$enabled_post_body"
  exit 1
}

echo "OK: queued chat routes return enabled skeleton response"

stop_server
trap - EXIT

echo "PASS: queued chat route skeleton smoke passed"
