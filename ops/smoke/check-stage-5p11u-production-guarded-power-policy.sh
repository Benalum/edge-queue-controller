#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/Desktop/edge-queue-controller"

ok=1

echo "=== Stage 5P-11U Production Guarded Power Policy Smoke ==="

override="/etc/systemd/system/edge-queue-controller.service.d/zz-production-guarded-power.conf"

echo
echo "=== systemd override ==="
if [ -f "$override" ]; then
  echo "OK override exists: $override"
else
  echo "FAIL missing override: $override"
  ok=0
fi

echo
echo "=== loaded env flags ==="
env_text="$(systemctl show edge-queue-controller -p Environment --no-pager || true)"

required_env=(
  "EDGE_POWER_AUTO_TICK_FULL=1"
  "EDGE_POWER_AUTO_START_WORKERS=1"
  "EDGE_POWER_EXECUTE_START_WORKERS=1"
  "EDGE_POWER_EXECUTE_WAKE=1"
  "EDGE_POWER_EXECUTE_WAKE_AND_START=1"
  "WEB_POWER_POLICY_EXECUTE_WAKE=1"
  "WEB_POWER_POLICY_EXECUTE_CONTAINERS=1"
  "EDGE_POWER_AUTO_STOP_WORKERS=1"
  "EDGE_POWER_EXECUTE_STOPS=1"
  "EDGE_POWER_AUTO_SHUTDOWN_HOST=1"
  "EDGE_POWER_EXECUTE_HOST_SHUTDOWN=1"
  "WEB_POWER_POLICY_EXECUTE_SHUTDOWN=1"
  "WEB_PRESENCE_ACTIVE_WINDOW_SECONDS=180"
  "WEB_POWER_CONTAINER_IDLE_SECONDS=1800"
  "WEB_POWER_HOST_IDLE_SECONDS=1800"
  "WEB_POWER_MIN_HOST_ON_SECONDS=600"
)

for item in "${required_env[@]}"; do
  if grep -Fq "$item" <<<"$env_text"; then
    echo "OK env $item"
  else
    echo "FAIL missing env $item"
    ok=0
  fi
done

echo
echo "=== collect JSON ==="
policy_file="/tmp/stage5p11u-policy.json"
tick_file="/tmp/stage5p11u-tick.json"
status_file="/tmp/stage5p11u-status.json"

curl -fsS http://127.0.0.1:7070/system/presence/power-policy > "$policy_file" || ok=0
curl -fsS -X POST http://127.0.0.1:7070/power/auto/tick > "$tick_file" || ok=0
curl -fsS http://127.0.0.1:7070/system/status > "$status_file" || ok=0

echo
echo "=== automation enabled checks ==="
for key in \
  auto_stop_workers \
  auto_shutdown_host \
  auto_start_workers \
  execute_stops_enabled \
  execute_host_shutdown_enabled \
  execute_wake_enabled \
  execute_wake_and_start_enabled
do
  value="$(jq -r ".automation.${key}" "$tick_file")"
  if [ "$value" = "true" ]; then
    echo "OK automation $key=true"
  else
    echo "FAIL automation $key=$value"
    ok=0
  fi
done

echo
echo "=== logged-in presence guard checks ==="
active_auth="$(jq -r '.presence.active_authenticated // 0' "$policy_file")"

if [ "$active_auth" -gt 0 ]; then
  jq -e '.desired_state.host_required == true' "$policy_file" >/dev/null || ok=0
  jq -e '.desired_state.container_required == true' "$policy_file" >/dev/null || ok=0
  jq -e '.desired_state.shutdown_blocked == true' "$policy_file" >/dev/null || ok=0
  jq -e '.actions[] | select(.action == "skip_host_shutdown_due_to_web_presence_or_boot_grace")' "$tick_file" >/dev/null || ok=0
  echo "OK active authenticated presence blocks shutdown"
else
  echo "NOTE no active authenticated presence during smoke"
fi

echo
echo "=== platform health checks ==="
jq -e '.nodes[] | select(.id == "master-laptop" and .state == "online")' "$status_file" >/dev/null || ok=0
jq -e '.services[] | select(.id == "study-api" and .state == "online")' "$status_file" >/dev/null || ok=0

if [ "$ok" = "1" ]; then
  echo
  echo "STAGE_5P11U_SMOKE_OK"
else
  echo
  echo "STAGE_5P11U_SMOKE_FAIL"
  exit 1
fi
