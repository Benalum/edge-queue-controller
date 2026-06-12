#!/usr/bin/env bash
set -u

echo "=== Stage 7Y-2C smoke: live /tick fast compatibility shim ==="

fail=0
DOC="docs/stage-7y2c-live-legacy-tick-fast-shim-validation.md"

if [ ! -f "$DOC" ]; then
  echo "FAIL: missing $DOC"
  fail=1
fi

grep -q "Live Legacy Tick Fast Shim Validation" "$DOC" || fail=1
grep -q "Do not re-enable the old" "$DOC" || fail=1

echo
echo "=== verify controller health ==="
health_code="$(curl -sS --max-time 10 -o /tmp/stage7y2c-health.json -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=$health_code"
cat /tmp/stage7y2c-health.json | jq . || cat /tmp/stage7y2c-health.json || true
echo

if [ "$health_code" != "200" ]; then
  echo "FAIL: controller health should be 200"
  fail=1
fi

echo
echo "=== verify /tick returns fast shim ==="
tick_code="$(curl -sS --max-time 8 -o /tmp/stage7y2c-tick.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/tick || true)"
echo "tick_code=$tick_code"
cat /tmp/stage7y2c-tick.json | jq . || cat /tmp/stage7y2c-tick.json || true
echo

tick_mode="$(jq -r '.mode // empty' /tmp/stage7y2c-tick.json 2>/dev/null || true)"
echo "tick_mode=$tick_mode"

if [ "$tick_code" != "200" ]; then
  echo "FAIL: /tick should return HTTP 200"
  fail=1
fi

if [ "$tick_mode" != "legacy_tick_compatibility_shim" ]; then
  echo "FAIL: /tick should return legacy_tick_compatibility_shim mode"
  fail=1
fi

echo
echo "=== verify legacy scheduler timer remains disabled/inactive ==="
enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "scheduler_timer_enabled=$enabled"
echo "scheduler_timer_active=$active"

if [ "$enabled" != "disabled" ] || [ "$active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled/inactive"
  fail=1
fi

echo
echo "=== verify no fresh controller errors ==="
journalctl -u edge-queue-controller --since "2 minutes ago" --no-pager \
  | grep -E 'POST /tick|Traceback|NameError|Internal Server Error' \
  | tail -n 120 || true

if journalctl -u edge-queue-controller --since "2 minutes ago" --no-pager \
  | grep -Eq 'Traceback|NameError|Internal Server Error'; then
  echo "FAIL: fresh controller error found"
  fail=1
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 7Y-2C live /tick shim validation passed"
else
  echo "FAIL: Stage 7Y-2C smoke found an issue"
fi

echo
echo "=== final repo status ==="
git status --short
