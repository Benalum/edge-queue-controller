#!/usr/bin/env bash
set -euo pipefail
set +H

PVEW_SSH="${PVEW_SSH:-root@pvew}"

sanitize_stream() {
  sed -E \
    -e 's#https://login\.tailscale\.com/a/[A-Za-z0-9]+#<redacted-tailscale-auth-url>#g' \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<redacted-mac>/g' \
    -e 's/(EDGE_PROXMOX_SSH_TARGET=root@).*/\1<redacted-private-ip>/g'
}

{
  echo "=== Stage 16-E2M smoke: E2L findings and CT203 network repair plan no-apply ==="
  echo "MUTATION_SCOPE=read_only_smoke_only"
  echo "NO CT/VM start/stop/restart"
  echo "NO service restart/reload/start/stop"
  echo "NO env mutation"
  echo "NO firewall mutation"
  echo "NO network config mutation"
  echo "NO DB write"
  echo "NO worker/model/scheduler activation"
  echo "NO Ollama/model endpoint calls"
  echo

  cd "$(git rev-parse --show-toplevel)"

  echo "--- doc assertions ---"
  doc="docs/stage-16-e2m-e2l-findings-and-ct203-network-repair-plan-no-apply.md"
  test -f "$doc"
  grep -F "CT101 did start and boot successfully" "$doc" >/dev/null
  grep -F "CT101 auto-started legacy runtime components" "$doc" >/dev/null
  grep -F "No route to host" "$doc" >/dev/null
  grep -F "BLOCKER" "$doc" >/dev/null || true
  grep -F "Stage 16-E2N" "$doc" >/dev/null
  grep -F "Do not start CT101 again yet" "$doc" >/dev/null
  grep -F "APPROVE_STAGE_16_E2N_REALIGN_CT203_NETWORK_TO_PVEW_PVESO_LAN_UPDATE_PVESO_SSH_TARGET_RESTART_CT203_NETWORK_ONLY" "$doc" >/dev/null
  echo "doc_assertions_ok=true"
  echo

  echo "--- platform safety quick check ---"
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
set +H
qm status 200
pct status 203
pct status 204
if findmnt /srv/apc-private-data >/dev/null 2>&1; then
  echo "private_storage=mounted_UNEXPECTED"
  exit 1
else
  echo "private_storage=not-mounted"
fi

pct exec 203 -- bash -lc '
set -euo pipefail
echo "ct203_controller_active=$(systemctl is-active edge-queue-controller.service 2>/dev/null || true)"
grep -E "^EDGE_POWER_EXECUTE_WAKE=false$" /etc/edge-queue-controller/edge-queue-controller.env >/dev/null && echo "EDGE_POWER_EXECUTE_WAKE=false"
curl -sS -o /tmp/e2m-health.json -w "ct203_health_http=%{http_code}\n" http://127.0.0.1:7070/health || true
curl -sS -o /tmp/e2m-status.json -w "ct203_system_status_http=%{http_code}\n" http://127.0.0.1:7070/system/status || true
DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"
expected="user_sessions:235 jobs:23 job_results:6 router_logs:0 router_resolution_steps:0 router_feedback:0 workers:2 worker_events:3"
for pair in $expected; do
  t="${pair%%:*}"
  e="${pair##*:}"
  c="$(sqlite3 "$DB" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo ERR)"
  echo "count=${t}:${c}"
  test "$c" = "$e"
done
'
REMOTE
  echo

  echo "--- PVESO rollback state check ---"
  timeout 25 tailscale ssh root@pveso 'bash -lc "
set -euo pipefail
pct status 101 | grep -F \"status: stopped\" >/dev/null && echo ct101_stopped=true
pct status 201 | grep -F \"status: stopped\" >/dev/null && echo ct201_stopped=true
pct status 202 | grep -F \"status: stopped\" >/dev/null && echo ct202_stopped=true
pct config 101 | grep -E \"^onboot: 0$\" >/dev/null && echo ct101_onboot_0=true
echo host_ollama_active=\$(systemctl is-active ollama.service 2>/dev/null || true)
echo NO_MUTATION_EXECUTED=true
"'
  echo

  echo "PASS_STAGE_16_E2M_E2L_FINDINGS_NETWORK_PLAN_SMOKE"
} 2>&1 | sanitize_stream
