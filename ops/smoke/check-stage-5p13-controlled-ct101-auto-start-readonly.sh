#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 5P-13 readonly verification smoke ==="

fail=0

echo
echo "=== git checkpoint ==="
git status --short

echo
echo "=== timer/service state ==="
timer_state="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
service_failed="$(systemctl is-failed edge-queue-power-auto-tick.service || true)"

echo "timer_state=$timer_state"
echo "service_failed=$service_failed"

[ "$timer_state" = "active" ] || {
  echo "FAIL: edge-queue-power-auto-tick.timer is not active"
  fail=1
}

[ "$service_failed" != "failed" ] || {
  echo "FAIL: edge-queue-power-auto-tick.service is failed"
  fail=1
}

echo
echo "=== CT101 status ==="
ct_status="$(ssh -o BatchMode=yes -o ConnectTimeout=8 root@100.88.194.19 'pct status 101' || true)"
echo "$ct_status"

echo "$ct_status" | grep -q 'status: running' || {
  echo "FAIL: CT101 is not running"
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

echo "$status_json" | jq -e '.nodes[] | select(.id=="ct-101" and .state=="online")' >/dev/null || {
  echo "FAIL: ct-101 is not online in system status"
  fail=1
}

echo
echo "=== last auto tick JSON exists ==="
test -s /var/log/edge-queue-controller/power-auto-tick-last.json || {
  echo "FAIL: last auto tick JSON file is missing or empty"
  fail=1
}

cat /var/log/edge-queue-controller/power-auto-tick-last.json \
  | jq '.automation, .wake_plan_summary, [.actions[] | {area, action, executed, reason}]'

cat /var/log/edge-queue-controller/power-auto-tick-last.json \
  | jq -e '.automation.execute_wake_and_start_enabled == true' >/dev/null || {
    echo "FAIL: execute_wake_and_start_enabled is not true"
    fail=1
  }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 5P-13 readonly verification smoke passed"
else
  echo "FAIL: Stage 5P-13 readonly verification smoke failed"
fi

exit "$fail"
