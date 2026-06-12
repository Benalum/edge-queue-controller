#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7U-4 smoke: live controller uses CT101 API health target ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7u4-live-controller-loads-ct101-api-health-target.md"

test -f "$DOC"
test -f edge_controller.py

grep -q "Stage 7U-4 Live Controller Loads CT101 API Health Target" "$DOC"
grep -q "host_online=true" "$DOC"
grep -q "100.88.245.33:8088/health" "$DOC"
grep -q "did not enable router dispatch" "$DOC"
grep -q "did not enable model calls" "$DOC"

echo
echo "=== verify controller service active ==="
systemctl is-active edge-queue-controller | grep -q '^active$'

echo
echo "=== verify CT101 API health directly ==="
api_code="$(curl -sS --max-time 10 -o /tmp/stage7u4-api-health.out -w "%{http_code}" http://100.88.245.33:8088/health || true)"
echo "ct101_api_health_code=$api_code"
cat /tmp/stage7u4-api-health.out || true
echo

if [ "$api_code" != "200" ]; then
  echo "FAIL: CT101 API health should return HTTP 200"
  exit 1
fi

echo
echo "=== verify live controller health uses 8088 and host_online true ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7u4-live-health.out -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "live_health_code=$health_code"
cat /tmp/stage7u4-live-health.out || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: live controller health should return HTTP 200"
  exit 1
fi

"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("/tmp/stage7u4-live-health.out").read_text())

assert data["ok"] is True, data
assert data["host_online"] is True, data
assert data["host_check_url"] == "http://100.88.245.33:8088/health", data
assert "HTTP 200" in data["host_detail"], data

print("OK: live controller health uses CT101 API target")
PY

echo
echo "=== verify router dry-run endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7u4-router.out \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7u4-router.out || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled by default"
  exit 1
fi

echo
echo "PASS: Stage 7U-4 live controller CT101 API health target smoke passed"
