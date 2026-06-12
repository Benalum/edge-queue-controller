#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7V-1 smoke: current worker queue system status endpoints ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7v1-current-worker-queue-system-status-endpoints.md"

test -f "$DOC"
test -f edge_controller.py

grep -q "Stage 7V-1 Current Worker Queue System Status Endpoints" "$DOC"
grep -q "GET /system/status" "$DOC"
grep -q "GET /api/system/status" "$DOC"
grep -q "X-Laptop-Queue-Token" "$DOC"
grep -q "does not restart the controller" "$DOC"

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile edge_controller.py

echo
echo "=== verify controller health ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7v1-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7v1-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: /health should return HTTP 200"
  exit 1
fi

echo
echo "=== verify /api/system/status remains absent ==="
api_system_code="$(curl -sS --max-time 10 -o /tmp/stage7v1-api-system-status.json -w "%{http_code}" http://127.0.0.1:7070/api/system/status || true)"
echo "api_system_status_code=$api_system_code"
cat /tmp/stage7v1-api-system-status.json || true
echo

if [ "$api_system_code" != "404" ]; then
  echo "FAIL: /api/system/status should be absent and return 404"
  exit 1
fi

echo
echo "=== verify /system/status is the correct status endpoint ==="
system_code="$(curl -sS --max-time 15 -o /tmp/stage7v1-system-status.json -w "%{http_code}" http://127.0.0.1:7070/system/status || true)"
echo "system_status_code=$system_code"
cat /tmp/stage7v1-system-status.json | jq '.overall_state, .nodes[].id, .services[].id' || true
echo

if [ "$system_code" != "200" ]; then
  echo "FAIL: /system/status should return HTTP 200"
  exit 1
fi

"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("/tmp/stage7v1-system-status.json").read_text())

assert data["ok"] is True, data
assert data["overall_state"] == "online", data

node_states = {node["id"]: node["state"] for node in data["nodes"]}
assert node_states["master-laptop"] == "online", node_states
assert node_states["pveso"] == "online", node_states
assert node_states["ct-101"] == "online", node_states

service_by_id = {svc["id"]: svc for svc in data["services"]}
worker = service_by_id["ct101-laptop-queue-worker"]

assert worker["state"] == "online", worker
assert worker["service_active"] is True, worker
assert worker["paused"] is False, worker
assert worker["preflight_ok"] is True, worker
assert worker["queue"]["queued"] >= 0, worker
assert worker["queue"]["running"] >= 0, worker
assert worker["model"], worker

print("OK: /system/status reports controller, pveso, CT101, and worker online")
print("worker_detail:", worker["detail"])
PY

echo
echo "=== verify internal queue summary is protected without token ==="
internal_code="$(curl -sS --max-time 10 -o /tmp/stage7v1-internal-queue-summary.json -w "%{http_code}" http://127.0.0.1:7070/internal/laptop-queue/summary || true)"
echo "internal_queue_summary_code=$internal_code"
cat /tmp/stage7v1-internal-queue-summary.json || true
echo

if [ "$internal_code" != "401" ]; then
  echo "FAIL: internal queue summary should require token and return 401 without it"
  exit 1
fi

echo
echo "=== verify chat queue status endpoint is auth-gated without bearer token ==="
chat_queue_code="$(curl -sS --max-time 10 -o /tmp/stage7v1-chat-queue-status.json -w "%{http_code}" http://127.0.0.1:7070/api/chat/queue/status || true)"
echo "chat_queue_status_code=$chat_queue_code"
cat /tmp/stage7v1-chat-queue-status.json || true
echo

if [ "$chat_queue_code" != "401" ]; then
  echo "FAIL: /api/chat/queue/status should require bearer auth and return HTTP 401 without token"
  exit 1
fi

echo
echo "=== verify router endpoint remains disabled by default ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7v1-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7v1-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7V-1 current worker queue system status endpoints smoke passed"
