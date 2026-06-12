#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 6AH smoke: temporary enabled router HTTP process ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-6ah-universal-intent-router-temporary-enabled-http-smoke.md"
PORT="${STAGE6AH_PORT:-7071}"
BASE_URL="http://127.0.0.1:${PORT}"
LOG="/tmp/stage6ah-router-http-${PORT}.log"

test -f "$DOC"
test -f edge_controller.py
test -f edge_intent_router.py
test -f edge_router_lookup.py
test -f edge_queue.sqlite3

grep -q "Stage 6AH Universal Intent Router Temporary Enabled HTTP Smoke" "$DOC"
grep -q "does not restart the live controller" "$DOC"
grep -q "does not dispatch" "$DOC"
grep -q "does not call models" "$DOC"

echo
echo "=== verify live controller remains active before test ==="
systemctl is-active edge-queue-controller | grep -q '^active$'

echo
echo "=== verify live controller router endpoint is disabled before test ==="
live_code="$(curl -sS --max-time 10 -o /tmp/stage6ah-live-before.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "live_router_code_before=$live_code"
if [ "$live_code" != "404" ]; then
  echo "FAIL: live router endpoint should be disabled before temporary test"
  cat /tmp/stage6ah-live-before.out || true
  exit 1
fi

echo
echo "=== verify temporary port is free ==="
if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: port ${PORT} is already in use"
  ss -ltnp | grep ":${PORT}" || true
  exit 1
fi

echo
echo "=== compile modules ==="
"$PYTHON_BIN" -m py_compile \
  edge_controller.py \
  edge_intent_router.py \
  edge_router_lookup.py \
  edge_router_schema.py \
  edge_router_seed.py

echo
echo "=== start temporary enabled controller on ${BASE_URL} ==="
rm -f "$LOG"

EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 \
EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3 \
"$PYTHON_BIN" -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG" 2>&1 &
pid="$!"

cleanup() {
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
    wait "$pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "temporary_pid=$pid"
echo "temporary_log=$LOG"

echo
echo "=== wait for temporary controller health ==="
ready=0
for i in $(seq 1 40); do
  code="$(curl -sS --max-time 2 -o /tmp/stage6ah-temp-health.out -w "%{http_code}" "${BASE_URL}/health" || true)"
  if [ "$code" = "200" ]; then
    ready=1
    break
  fi
  sleep 0.25
done

if [ "$ready" != "1" ]; then
  echo "FAIL: temporary controller did not become healthy"
  echo "--- temporary log ---"
  sed -n '1,220p' "$LOG" || true
  exit 1
fi

echo "temporary_health_code=200"
cat /tmp/stage6ah-temp-health.out || true
echo

echo
echo "=== call enabled temporary /api/router/dry-run ==="
curl -sS --max-time 10 -o /tmp/stage6ah-router-next.json \
  -w "temp_router_code=%{http_code}\n" \
  -X POST "${BASE_URL}/api/router/dry-run" \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study","profile_language":"en","role":"user"},"router_options":{"dry_run":true,"allow_dispatch":false,"allow_model_call":false}}'

echo
echo "=== validate temporary router response ==="
"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("/tmp/stage6ah-router-next.json").read_text())

assert data["ok"] is True, data
assert data["dry_run"] is True, data
assert data["dispatch_performed"] is False, data
assert data["model_routing"]["model_call_required"] is False, data
assert data["safety"]["allowed_to_dispatch"] is False, data
assert data["confirmation_policy"]["eligible_for_dispatch"] is False, data

lookup = data["router_lookup"]["sqlite_phrase_lookup"]
assert data["router_lookup"]["stage"] == "6AF", data["router_lookup"]
assert lookup["matched"] is True, lookup
assert lookup["intent_key"] == "study.card.next", lookup
assert lookup["dispatch_performed"] is False, lookup
assert lookup["model_call_required"] is False, lookup

assert data["intent"]["name"] == "study.next", data["intent"]
assert data["decision_trace"][0]["step"] == "normalize_input", data["decision_trace"]
assert any(step["step"] == "sqlite_phrase_lookup" for step in data["decision_trace"]), data["decision_trace"]
assert data["decision_trace"][-1]["step"] == "rule_result", data["decision_trace"]

print("OK: temporary enabled HTTP dry-run response has DB-backed lookup and safe flags")
PY

echo
echo "=== verify blocked admin over temporary HTTP ==="
curl -sS --max-time 10 -o /tmp/stage6ah-router-admin.json \
  -w "temp_admin_router_code=%{http_code}\n" \
  -X POST "${BASE_URL}/api/router/dry-run" \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"admin","surface":"admin"},"context":{"active_page":"admin","role":"admin"},"router_options":{"dry_run":true,"allow_dispatch":false,"allow_model_call":false}}'

"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("/tmp/stage6ah-router-admin.json").read_text())

assert data["ok"] is True, data
assert data["dry_run"] is True, data
assert data["source_surface_policy"]["allowed"] is False, data
assert data["dispatch_performed"] is False, data
assert data["model_routing"]["model_call_required"] is False, data
assert data["safety"]["allowed_to_dispatch"] is False, data

lookup = data["router_lookup"]["sqlite_phrase_lookup"]
assert lookup["matched"] is False, lookup
assert lookup["error_code"] == "source_surface_policy_blocked", lookup
assert lookup["dispatch_performed"] is False, lookup
assert lookup["model_call_required"] is False, lookup

print("OK: temporary enabled HTTP admin source remains blocked")
PY

echo
echo "=== stop temporary controller ==="
cleanup
trap - EXIT

if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: temporary port ${PORT} is still listening after cleanup"
  ss -ltnp | grep ":${PORT}" || true
  exit 1
fi

echo
echo "=== verify live controller still active and dry-run endpoint still disabled ==="
systemctl is-active edge-queue-controller | grep -q '^active$'

live_code_after="$(curl -sS --max-time 10 -o /tmp/stage6ah-live-after.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "live_router_code_after=$live_code_after"
cat /tmp/stage6ah-live-after.out || true
echo

if [ "$live_code_after" != "404" ]; then
  echo "FAIL: live router endpoint should remain disabled after temporary test"
  exit 1
fi

echo
echo "PASS: Stage 6AH temporary enabled router HTTP smoke passed"
