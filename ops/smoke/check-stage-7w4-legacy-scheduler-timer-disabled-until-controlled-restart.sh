#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 7W-4 smoke: legacy scheduler timer disabled until controlled restart ==="

DOC="docs/stage-7w4-legacy-scheduler-timer-disabled-until-controlled-restart.md"

test -f "$DOC"

grep -q "Legacy Scheduler Timer Disabled Until Controlled Restart" "$DOC"
grep -q "edge-queue-scheduler-tick.timer" "$DOC"
grep -q "does not restart the controller" "$DOC"
grep -q "does not call /tick" "$DOC"

echo
echo "=== verify legacy scheduler timer disabled/inactive ==="
enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "scheduler_timer_enabled=$enabled"
echo "scheduler_timer_active=$active"

if [ "$enabled" != "disabled" ]; then
  echo "FAIL: edge-queue-scheduler-tick.timer should remain disabled"
  exit 1
fi

if [ "$active" != "inactive" ]; then
  echo "FAIL: edge-queue-scheduler-tick.timer should remain inactive"
  exit 1
fi

echo
echo "=== verify modern timers are still scheduled ==="
systemctl list-timers --all --no-pager | grep -q 'edge-queue-power-auto-tick.timer'
systemctl list-timers --all --no-pager | grep -q 'edge-queue-remediation-tick.timer'
systemctl list-timers --all --no-pager | grep -E 'edge-queue-power-auto-tick|edge-queue-remediation-tick|edge-queue-scheduler-tick' || true

echo
echo "=== verify controller remains healthy without restart ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7w4-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7w4-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  exit 1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7w4-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7w4-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  exit 1
fi

echo
echo "PASS: Stage 7W-4 legacy scheduler timer disabled checkpoint passed"
