#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7U-2 smoke: temporary controller validates CT101 API health target ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7u2-temporary-controller-validates-ct101-api-health-target.md"
PORT="${STAGE7U2_PORT:-7072}"
BASE_URL="http://127.0.0.1:${PORT}"
LOG="/tmp/stage7u2-temp-controller-${PORT}.log"

test -f "$DOC"
test -f edge_controller.py

grep -q "Stage 7U-2 Temporary Controller Validates CT101 API Health Target" "$DOC"
grep -q "does not restart the live controller" "$DOC"
grep -q "host_online=true" "$DOC"
grep -q "100.88.245.33:8088/health" "$DOC"

echo
echo "=== verify CT101 API health target directly ==="
api_code="$(curl -sS --max-time 10 -o /tmp/stage7u2-api-health.out -w "%{http_code}" http://100.88.245.33:8088/health || true)"
echo "ct101_api_health_code=$api_code"
cat /tmp/stage7u2-api-health.out || true
echo
if [ "$api_code" != "200" ]; then
  echo "FAIL: CT101 API health should return HTTP 200"
  exit 1
fi

echo
echo "=== verify live controller is active ==="
systemctl is-active edge-queue-controller | grep -q '^active$'

echo
echo "=== verify temporary port is free ==="
if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: temporary port ${PORT} is already in use"
  ss -ltnp | grep ":${PORT}" || true
  exit 1
fi

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile edge_controller.py

echo
echo "=== start temporary controller with corrected CT101 API target ==="
rm -f "$LOG"

HOST_CHECK_URL=http://100.88.245.33:8088/health \
AI_PLATFORM_BASE_URL=http://100.88.245.33:8088 \
AI_PLATFORM_EDGE_INGEST_URL=http://100.88.245.33:8088/api/backend/internal/edge/jobs \
"$PYTHON_BIN" -m uvicorn edge_controller:app --host 127.0.0.1 --port "$PORT" >"$LOG" 2>&1 &
pid="$!"

cleanup() {
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
    wait "$pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

ready=0
for i in $(seq 1 40); do
  code="$(curl -sS --max-time 2 -o /tmp/stage7u2-temp-health.out -w "%{http_code}" "${BASE_URL}/health" || true)"
  if [ "$code" = "200" ]; then
    ready=1
    break
  fi
  sleep 0.25
done

if [ "$ready" != "1" ]; then
  echo "FAIL: temporary controller did not become healthy"
  sed -n '1,220p' "$LOG" || true
  exit 1
fi

echo
echo "=== validate temporary health response ==="
"$PYTHON_BIN" - <<'PY'
import json
from pathlib import Path

data = json.loads(Path("/tmp/stage7u2-temp-health.out").read_text())

print(data)

assert data["ok"] is True, data
assert data["host_online"] is True, data
assert data["host_check_url"] == "http://100.88.245.33:8088/health", data
assert "HTTP 200" in data["host_detail"], data

print("OK: temporary controller validates corrected CT101 API health target")
PY

echo
echo "=== stop temporary controller ==="
cleanup
trap - EXIT

echo
echo "=== verify temporary port stopped ==="
if ss -ltn | awk '{print $4}' | grep -q ":${PORT}$"; then
  echo "FAIL: temporary port ${PORT} still listening"
  ss -ltnp | grep ":${PORT}" || true
  exit 1
fi

echo
echo "=== verify live controller still active ==="
systemctl is-active edge-queue-controller | grep -q '^active$'

echo
echo "PASS: Stage 7U-2 temporary controller validation smoke passed"
