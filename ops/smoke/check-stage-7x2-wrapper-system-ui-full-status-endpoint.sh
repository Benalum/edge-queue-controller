#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7X-2 smoke: wrapper System UI loads full system status ==="

DOC="docs/stage-7x2-wrapper-system-ui-full-status-endpoint.md"
APP="frontend/wrapper-ui/app.js"
INDEX="frontend/wrapper-ui/index.html"

test -f "$DOC"
test -f "$APP"
test -f "$INDEX"

grep -q "Wrapper System UI Full Status Endpoint" "$DOC"
grep -q 'api("/system/status"' "$APP"
grep -q 'app.js?v=20260612210200' "$INDEX"

echo
echo "=== verify loadSystemStatus uses full status, not lightweight public-status ==="
python3 - <<'PY_INNER'
from pathlib import Path

s = Path("frontend/wrapper-ui/app.js").read_text()

start = s.index("async function loadSystemStatus()")
end = s.index("function ensureResendVerificationButton()", start)
block = s[start:end]

assert 'api("/system/status"' in block, 'loadSystemStatus must call api("/system/status")'
assert 'api("/system/public-status"' not in block, 'loadSystemStatus must not call lightweight public-status'

print("OK: loadSystemStatus uses full wrapper system status")
PY_INNER

echo
echo "=== verify legacy scheduler timer remains disabled/inactive ==="
enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "scheduler_timer_enabled=$enabled"
echo "scheduler_timer_active=$active"

if [ "$enabled" != "disabled" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled"
  exit 1
fi

if [ "$active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain inactive"
  exit 1
fi

echo
echo "=== verify local controller health remains OK ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7x2-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7x2-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  exit 1
fi

echo
echo "=== verify public wrapper full status JSON endpoint ==="
public_code="$(curl -sS -L --max-time 15 -o /tmp/stage7x2-public-status.json \
  -w "%{http_code}" \
  https://alexhartel.com/api/system/status || true)"
echo "public_api_system_status_code=$public_code"
cat /tmp/stage7x2-public-status.json | jq '{ok, overall_state, nodes: [.nodes[]? | {id, state}], services: [.services[]? | {id, state}]}' || cat /tmp/stage7x2-public-status.json
echo

if [ "$public_code" != "200" ]; then
  echo "FAIL: public /api/system/status should return HTTP 200"
  exit 1
fi

overall="$(cat /tmp/stage7x2-public-status.json | jq -r '.overall_state // "missing"')"
if [ "$overall" != "online" ]; then
  echo "FAIL: public /api/system/status should report overall_state online"
  exit 1
fi

echo
echo "=== verify direct /system/status remains SPA HTML, not JSON ==="
direct_type="$(curl -sS -L --max-time 15 -o /tmp/stage7x2-direct-system-status.out \
  -w "%{content_type}" \
  https://alexhartel.com/system/status || true)"
echo "direct_system_status_content_type=$direct_type"
head -c 120 /tmp/stage7x2-direct-system-status.out || true
echo

if ! echo "$direct_type" | grep -qi 'text/html'; then
  echo "FAIL: public /system/status should remain SPA HTML"
  exit 1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7x2-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7x2-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7X-2 wrapper System UI full status endpoint smoke passed"
