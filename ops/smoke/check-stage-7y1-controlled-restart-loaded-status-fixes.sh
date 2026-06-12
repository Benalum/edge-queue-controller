#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7Y-1 smoke: controlled restart loaded status fixes ==="

DOC="docs/stage-7y1-controlled-restart-loaded-status-fixes.md"
test -f "$DOC"

grep -q "Controlled Restart Loaded Status Fixes" "$DOC"
grep -q "Frontend Wrapper: \`online\`" "$DOC"
grep -q "Queue: \`online\`" "$DOC"
grep -q "Power Automation: \`degraded\`" "$DOC"
grep -q "did not re-enable the legacy" "$DOC"

echo
echo "=== verify controller health ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7y1-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7y1-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  exit 1
fi

echo
echo "=== verify normalized platform states ==="
curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage7y1-system-status.json
jq '.normalized.platform' /tmp/stage7y1-system-status.json

jq -e '
  (.normalized.platform[] | select(.id=="frontend-wrapper") | .state) == "online"
  and
  (.normalized.platform[] | select(.id=="queue") | .state) == "online"
  and
  (.normalized.platform[] | select(.id=="power-automation") | .state) == "degraded"
  and
  (.normalized.platform[] | select(.id=="ct101-laptop-queue-worker") | .state) == "online"
' /tmp/stage7y1-system-status.json

echo
echo "=== verify public wrapper sees updated normalized states ==="
curl -sS -L --max-time 20 https://alexhartel.com/api/system/status > /tmp/stage7y1-public-status.json
jq '.normalized.platform' /tmp/stage7y1-public-status.json

jq -e '
  (.normalized.platform[] | select(.id=="frontend-wrapper") | .state) == "online"
  and
  (.normalized.platform[] | select(.id=="queue") | .state) == "online"
  and
  (.normalized.platform[] | select(.id=="power-automation") | .state) == "degraded"
' /tmp/stage7y1-public-status.json

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
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7y1-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7y1-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7Y-1 controlled restart status smoke passed"
