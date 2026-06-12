#!/usr/bin/env bash
set -u

echo "=== Stage 7Y-4 smoke: live Power Automation online final status ==="

fail=0
DOC="docs/stage-7y4-live-power-automation-online-final-status.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
else
  echo "OK: found $DOC"
fi

grep -q "Live Power Automation Online Final Status" "$DOC" || fail=1
grep -q "Power Automation: \`online\`" "$DOC" || fail=1
grep -q "legacy_tick_compatibility_shim" "$DOC" || fail=1

echo
echo "=== verify controller health ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7y4-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7y4-health.json | jq . || cat /tmp/stage7y4-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  fail=1
fi

echo
echo "=== verify normalized platform states are online ==="
curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage7y4-system-status.json
jq '.normalized.platform' /tmp/stage7y4-system-status.json

for id in backend-api frontend-wrapper queue workers ct101-laptop-queue-worker power-automation; do
  state="$(jq -r --arg id "$id" '.normalized.platform[] | select(.id==$id) | .state' /tmp/stage7y4-system-status.json)"
  echo "$id=$state"
  if [ "$state" != "online" ]; then
    echo "FAIL: $id should be online"
    fail=1
  fi
done

echo
echo "=== verify public wrapper sees Power Automation online ==="
curl -sS -L --max-time 20 https://alexhartel.com/api/system/status > /tmp/stage7y4-public-status.json
jq '.normalized.platform' /tmp/stage7y4-public-status.json

public_power_state="$(jq -r '.normalized.platform[] | select(.id=="power-automation") | .state' /tmp/stage7y4-public-status.json)"
echo "public_power_automation_state=$public_power_state"

if [ "$public_power_state" != "online" ]; then
  echo "FAIL: public Power Automation should be online"
  fail=1
fi

echo
echo "=== verify /tick remains fast shim ==="
tick_code="$(curl -sS --max-time 8 -o /tmp/stage7y4-tick.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/tick || true)"
echo "tick_code=$tick_code"
cat /tmp/stage7y4-tick.json | jq . || cat /tmp/stage7y4-tick.json || true

tick_mode="$(jq -r '.mode // empty' /tmp/stage7y4-tick.json 2>/dev/null || true)"
echo "tick_mode=$tick_mode"

if [ "$tick_code" != "200" ] || [ "$tick_mode" != "legacy_tick_compatibility_shim" ]; then
  echo "FAIL: /tick should remain fast compatibility shim"
  fail=1
fi

echo
echo "=== verify legacy scheduler timer remains disabled/inactive ==="
legacy_enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
legacy_active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "legacy_enabled=$legacy_enabled"
echo "legacy_active=$legacy_active"

if [ "$legacy_enabled" != "disabled" ] || [ "$legacy_active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled/inactive"
  fail=1
fi

echo
echo "=== verify modern timers remain active ==="
power_auto_active="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
remediation_active="$(systemctl is-active edge-queue-remediation-tick.timer || true)"
echo "power_auto_active=$power_auto_active"
echo "remediation_active=$remediation_active"

if [ "$power_auto_active" != "active" ] || [ "$remediation_active" != "active" ]; then
  echo "FAIL: modern timers should remain active"
  fail=1
fi

echo
echo "=== verify router endpoint remains disabled ==="
router_code="$(curl -sS --max-time 10 -o /tmp/stage7y4-router.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/api/router/dry-run \
  -H 'Content-Type: application/json' \
  --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
echo "router_dry_run_code=$router_code"
cat /tmp/stage7y4-router.json || true
echo

if [ "$router_code" != "404" ]; then
  echo "FAIL: router dry-run endpoint should remain disabled"
  fail=1
fi

echo
echo "=== verify no fresh controller errors ==="
journalctl -u edge-queue-controller --since "2 minutes ago" --no-pager \
  | grep -E 'Traceback|NameError|Internal Server Error' \
  | tail -n 120 || true

if journalctl -u edge-queue-controller --since "2 minutes ago" --no-pager \
  | grep -Eq 'Traceback|NameError|Internal Server Error'; then
  echo "FAIL: fresh controller error found"
  fail=1
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Y-4 live Power Automation online final status smoke passed"
else
  echo "FAIL: Stage 7Y-4 smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
