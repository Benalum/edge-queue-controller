#!/usr/bin/env bash
set -euo pipefail

echo "=== Stage 5P-12 auto power tick timeout and current inventory smoke ==="

fail=0

echo
echo "=== controller env ==="
env_line="$(systemctl show edge-queue-controller -p Environment --no-pager || true)"
echo "$env_line" | tr ' ' '\n' | grep -E 'EDGE_PROXMOX_AUTO_MANAGED|EDGE_PROXMOX_PROTECTED|EDGE_POWER_AUTO_TICK_FULL|EDGE_POWER_EXECUTE' || true

echo "$env_line" | grep -q 'EDGE_PROXMOX_AUTO_MANAGED=101,llms,llms_ollama' || {
  echo "FAIL: current auto-managed inventory is not loaded"
  fail=1
}

echo "$env_line" | grep -q 'EDGE_PROXMOX_PROTECTED=' || {
  echo "FAIL: protected inventory override is not loaded"
  fail=1
}

echo "$env_line" | grep -q 'EDGE_POWER_AUTO_TICK_FULL=1' || {
  echo "FAIL: full auto tick is not enabled"
  fail=1
}

echo
echo "=== auto tick systemd unit ==="
systemctl cat edge-queue-power-auto-tick.service
systemctl cat edge-queue-power-auto-tick.timer

systemctl cat edge-queue-power-auto-tick.service | grep -q 'TimeoutStartSec=50' || {
  echo "FAIL: auto tick TimeoutStartSec is not 50"
  fail=1
}

systemctl cat edge-queue-power-auto-tick.service | grep -q -- '--max-time 45' || {
  echo "FAIL: auto tick curl max time is not 45 seconds"
  fail=1
}

echo
echo "=== run service once ==="
sudo systemctl reset-failed edge-queue-power-auto-tick.service
sudo systemctl start edge-queue-power-auto-tick.service || fail=1

state="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "timer state: $state"
[ "$state" = "active" ] || {
  echo "FAIL: auto tick timer is not active"
  fail=1
}

failed="$(systemctl is-failed edge-queue-power-auto-tick.service || true)"
echo "service failed state: $failed"
[ "$failed" != "failed" ] || {
  echo "FAIL: auto tick service is failed"
  fail=1
}

echo
echo "=== last tick JSON ==="
test -s /var/log/edge-queue-controller/power-auto-tick-last.json || {
  echo "FAIL: last tick JSON was not written"
  fail=1
}

jq '.automation, .wake_plan_summary, .actions[].action' /var/log/edge-queue-controller/power-auto-tick-last.json

jq -e '.automation.execute_wake_enabled == true' /var/log/edge-queue-controller/power-auto-tick-last.json >/dev/null || {
  echo "FAIL: execute_wake_enabled is not true"
  fail=1
}

jq -e '.automation.execute_wake_and_start_enabled == true' /var/log/edge-queue-controller/power-auto-tick-last.json >/dev/null || {
  echo "FAIL: execute_wake_and_start_enabled is not true"
  fail=1
}

echo
echo "=== corrected system status summary ==="
curl -fsS http://127.0.0.1:8787/api/system/status \
  | jq '{overall_state, nodes: [.nodes[] | {id, state, detail}], services: [.services[] | {id, state, detail}]}'

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS: Stage 5P-12 auto power tick timeout and current inventory smoke passed"
else
  echo "FAIL: Stage 5P-12 smoke failed"
fi

exit "$fail"
