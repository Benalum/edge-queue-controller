#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 5P-16 readonly verification smoke ==="

fail=0

echo
echo "=== git checkpoint ==="
git status --short

echo
echo "=== controller/timer state ==="
controller_state="$(systemctl is-active edge-queue-controller || true)"
timer_state="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
tick_failed="$(systemctl is-failed edge-queue-power-auto-tick.service || true)"

echo "controller_state=$controller_state"
echo "timer_state=$timer_state"
echo "tick_failed=$tick_failed"

[ "$controller_state" = "active" ] || {
  echo "FAIL: edge-queue-controller is not active"
  fail=1
}

[ "$timer_state" = "active" ] || {
  echo "FAIL: edge-queue-power-auto-tick.timer is not active"
  fail=1
}

[ "$tick_failed" != "failed" ] || {
  echo "FAIL: edge-queue-power-auto-tick.service is failed"
  fail=1
}

echo
echo "=== presence policy snapshot ==="
presence_json="$(curl -fsS http://127.0.0.1:7070/system/presence/power-policy)"
echo "$presence_json" | jq '{presence, desired_state, actions, reasons}'

echo
echo "=== auto tick snapshot ==="
tick_json="$(curl -fsS -X POST http://127.0.0.1:7070/power/auto/tick)"
echo "$tick_json" | jq '.automation, .wake_plan_summary, [.actions[] | {area, action, executed, reason}]'

echo "$tick_json" | jq -e '.automation.execute_wake_enabled == true' >/dev/null || {
  echo "FAIL: execute_wake_enabled is not true"
  fail=1
}

echo "$tick_json" | jq -e '.automation.execute_wake_and_start_enabled == true' >/dev/null || {
  echo "FAIL: execute_wake_and_start_enabled is not true"
  fail=1
}

echo "$tick_json" | jq -e '.wake_plan_summary.eligible == true' >/dev/null || {
  echo "FAIL: wake plan is not eligible"
  fail=1
}

echo
echo "=== platform status ==="
status_json="$(curl -fsS http://127.0.0.1:8787/api/system/status)"
echo "$status_json" | jq '{overall_state, nodes: [.nodes[] | {id, state, detail}], services: [.services[] | {id, state, detail}]}'

echo "$status_json" | jq -e '.overall_state == "online"' >/dev/null || {
  echo "FAIL: platform overall_state is not online"
  fail=1
}

echo "$status_json" | jq -e '.nodes[] | select(.id=="pveso" and .state=="online")' >/dev/null || {
  echo "FAIL: pveso is not online"
  fail=1
}

echo "$status_json" | jq -e '.nodes[] | select(.id=="ct-101" and .state=="online")' >/dev/null || {
  echo "FAIL: ct-101 is not online"
  fail=1
}

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 5P-16 readonly verification smoke passed"
else
  echo "FAIL: Stage 5P-16 readonly verification smoke failed"
fi

exit "$fail"
