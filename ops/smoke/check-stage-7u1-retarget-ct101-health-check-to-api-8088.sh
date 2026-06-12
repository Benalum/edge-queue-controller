#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7U-1 smoke: CT101 health target retargeted to API 8088 ==="

PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PYTHON_BIN" ]; then
  PYTHON_BIN="python3"
fi
echo "Using Python: $PYTHON_BIN"

DOC="docs/stage-7u1-retarget-ct101-health-check-to-api-8088.md"

test -f "$DOC"
test -f .env
test -f edge_controller.py

grep -q "Stage 7U-1 Retarget CT101 Health Check To API 8088" "$DOC"
grep -q "does not restart the live controller" "$DOC"
grep -q "HOST_CHECK_URL=http://100.88.245.33:8088/health" "$DOC"

echo
echo "=== verify .env non-secret URL targets ==="
grep -q '^HOST_CHECK_URL=http://100.88.245.33:8088/health$' .env
grep -q '^AI_PLATFORM_BASE_URL=http://100.88.245.33:8088$' .env
grep -q '^AI_PLATFORM_EDGE_INGEST_URL=http://100.88.245.33:8088/api/backend/internal/edge/jobs$' .env

if grep -q '^HOST_CHECK_URL=http://100.88.245.33:3010' .env; then
  echo "FAIL: HOST_CHECK_URL still points at retired 3010"
  exit 1
fi

if grep -q '^AI_PLATFORM_BASE_URL=http://100.88.245.33:3010' .env; then
  echo "FAIL: AI_PLATFORM_BASE_URL still points at retired 3010"
  exit 1
fi

if grep -q '^AI_PLATFORM_EDGE_INGEST_URL=http://100.88.245.33:3010' .env; then
  echo "FAIL: AI_PLATFORM_EDGE_INGEST_URL still points at retired 3010"
  exit 1
fi

echo
echo "=== compile controller ==="
"$PYTHON_BIN" -m py_compile edge_controller.py

echo
echo "=== verify CT101 API health on 8088 ==="
api_code="$(curl -sS --max-time 10 -o /tmp/stage7u1-api-health.out -w "%{http_code}" http://100.88.245.33:8088/health || true)"
echo "ct101_api_health_code=$api_code"
cat /tmp/stage7u1-api-health.out || true
echo

if [ "$api_code" != "200" ]; then
  echo "FAIL: CT101 API health should return HTTP 200 on 8088"
  exit 1
fi

echo
echo "=== verify Ollama still reachable on 11434 ==="
ollama_code="$(curl -sS --max-time 10 -o /tmp/stage7u1-ollama.out -w "%{http_code}" http://100.88.245.33:11434/ || true)"
echo "ollama_code=$ollama_code"
cat /tmp/stage7u1-ollama.out || true
echo

if [ "$ollama_code" != "200" ]; then
  echo "FAIL: Ollama should remain reachable on 11434"
  exit 1
fi

echo
echo "=== verify retired 3010 is not required ==="
retired_code="$(curl -sS --max-time 3 -o /tmp/stage7u1-3010.out -w "%{http_code}" http://100.88.245.33:3010/ || true)"
echo "retired_3010_code=$retired_code"
if [ "$retired_code" = "200" ]; then
  echo "WARN: 3010 unexpectedly returned 200; not failing because target is now 8088"
fi

echo
echo "PASS: Stage 7U-1 CT101 health retarget smoke passed"
