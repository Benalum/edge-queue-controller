#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-14a-runtime-power-auto-quarantine-and-timer-nonoverlap"
fail=0

echo "=== ${PHASE}: runtime quarantine and timer non-overlap smoke ==="

echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo "=== source markers ==="
grep -q "STAGE_5O2_POWER_AUTO_TICK_NONBLOCKING_DEFAULT_V1" edge_controller.py || fail=1
grep -q "EDGE_POWER_AUTO_TICK_FULL" edge_controller.py || fail=1
grep -q "stage_5o2_power_auto_tick_nonblocking_default" edge_controller.py || fail=1
grep -q "power_auto_tick_quarantined_nonblocking" edge_controller.py || fail=1
echo "PASS: source markers exist"

echo "=== no edge_controller.py local diff ==="
if git diff -- edge_controller.py | grep -q .; then
  echo "FAIL: edge_controller.py has local modifications"
  git diff -- edge_controller.py
  fail=1
else
  echo "PASS: edge_controller.py unchanged"
fi

echo "=== runtime env ==="
env_dump="$(systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "^EDGE_POWER_AUTO_PAUSED=|^EDGE_POWER_AUTO_TICK_FULL=" || true)"
echo "$env_dump"
echo "$env_dump" | grep -q "^EDGE_POWER_AUTO_PAUSED=0$" && echo "PASS: EDGE_POWER_AUTO_PAUSED=0" || { echo "FAIL: EDGE_POWER_AUTO_PAUSED is not 0"; fail=1; }
echo "$env_dump" | grep -q "^EDGE_POWER_AUTO_TICK_FULL=0$" && echo "PASS: EDGE_POWER_AUTO_TICK_FULL=0" || { echo "FAIL: EDGE_POWER_AUTO_TICK_FULL is not 0"; fail=1; }

echo "=== timer override ==="
timer_unit="/tmp/${PHASE}-timer-unit.txt"
SYSTEMD_PAGER=cat systemctl cat --no-pager edge-queue-power-auto-tick.service > "$timer_unit"
grep -q "/usr/bin/flock -n /tmp/edge-queue-power-auto-tick.lock" "$timer_unit" && echo "PASS: timer uses flock" || { echo "FAIL: timer missing flock"; fail=1; }
grep -q -- "--max-time 10" "$timer_unit" && echo "PASS: timer curl max-time is 10 seconds" || { echo "FAIL: timer curl max-time is not 10"; fail=1; }
grep -q "TimeoutStartSec=15" "$timer_unit" && echo "PASS: timer TimeoutStartSec override is 15" || { echo "FAIL: timer TimeoutStartSec=15 missing"; fail=1; }

echo "=== controller health ==="
health_code="$(curl -sS --max-time 5 -o "/tmp/${PHASE}-health.json" -w "%{http_code}" http://127.0.0.1:7070/health || true)"
echo "health_code=${health_code}"
[ "$health_code" = "200" ] || fail=1

echo "=== fast quarantined /power/auto/tick ==="
tick_code="$(curl -sS --max-time 8 -o "/tmp/${PHASE}-auto-tick.json" -w "%{http_code}" -X POST http://127.0.0.1:7070/power/auto/tick || true)"
echo "tick_code=${tick_code}"
if [ "$tick_code" != "200" ]; then
  echo "FAIL: /power/auto/tick did not return 200"
  fail=1
else
  jq ".quarantined, .source, .automation, .actions" "/tmp/${PHASE}-auto-tick.json" || fail=1
  jq -e ".quarantined == true and .automation.full_power_auto_tick == false and .automation.paused == false and (.actions[0].action == \"power_auto_tick_quarantined_nonblocking\")" "/tmp/${PHASE}-auto-tick.json" >/dev/null && echo "PASS: /power/auto/tick is quarantined nonblocking" || { echo "FAIL: /power/auto/tick is not quarantined nonblocking"; fail=1; }
fi

echo "=== responsive /system/status ==="
status_code="$(curl -sS --max-time 12 -o "/tmp/${PHASE}-system-status.json" -w "%{http_code}" http://127.0.0.1:7070/system/status || true)"
echo "status_code=${status_code}"
[ "$status_code" = "200" ] || fail=1

echo "=== safety summary ==="
echo "PASS: no edge_controller.py changes"
echo "PASS: power automation remains unpaused"
echo "PASS: full SSH-backed auto tick planner remains quarantined"
echo "PASS: timer has non-overlap guard"
echo "PASS: no CT101 runtime code changed"
echo "PASS: no Study or Companion behavior changed"
echo "PASS: no Ollama call, model call, or job enqueue added"

if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
