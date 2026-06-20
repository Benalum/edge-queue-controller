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
echo "=== Stage 16-E2H smoke: PVESO inventory path checkpoint ==="
echo "MUTATION_SCOPE=read_only_smoke_only"
echo "NO firewall mutation"
echo "NO env mutation"
echo "NO service restart"
echo "NO wake execution"
echo "NO DB write"
echo "NO CT/VM start/stop/restart"
echo "NO worker/model/scheduler activation"
echo "NO Ollama/model endpoint calls"
echo "NO CT204/private-storage mutation"
echo

ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
set +H

echo "--- node safety ---"
qm status 200
pct status 203
pct status 204
if findmnt /srv/apc-private-data >/dev/null 2>&1; then
  echo "private_storage=mounted_UNEXPECTED"
  exit 1
else
  echo "private_storage=not-mounted"
fi
echo

echo "--- CT203 env/service safety ---"
pct exec 203 -- bash -lc '
set -euo pipefail
ENV_FILE="/etc/edge-queue-controller/edge-queue-controller.env"
echo "controller_service_active=$(systemctl is-active edge-queue-controller.service 2>/dev/null || true)"
grep -E "^EDGE_POWER_EXECUTE_WAKE=false$" "$ENV_FILE" >/dev/null 2>&1 && echo "EDGE_POWER_EXECUTE_WAKE=false" || exit 1
grep -E "^EDGE_PROXMOX_HOST_ID=pveso$" "$ENV_FILE" >/dev/null 2>&1 && echo "EDGE_PROXMOX_HOST_ID=pveso" || exit 1
grep -E "^EDGE_PROXMOX_SSH_TARGET=root@" "$ENV_FILE" >/dev/null 2>&1 && echo "EDGE_PROXMOX_SSH_TARGET=root@<redacted-private-ip>" || exit 1
'
echo

echo "--- inventory endpoint read-only check ---"
pct exec 203 -- bash -lc '
set -euo pipefail
tmp="/tmp/stage16e2h-inventory-smoke.json"
code="$(curl -sS -o "$tmp" -w "%{http_code}" -X POST http://127.0.0.1:7070/power/proxmox/inventory || true)"
echo "proxmox_inventory_http=$code"
python3 - "$tmp" <<PY
import json, sys
data=json.load(open(sys.argv[1], "r", encoding="utf-8"))
print("proxmox_inventory_ok=" + str(bool(data.get("ok", False))).lower())
print("proxmox_inventory_host_id=" + str(data.get("host_id") or ""))
print("proxmox_inventory_hostname=" + str(data.get("hostname") or ""))
containers=data.get("containers") or []
vms=data.get("vms") or []
print("proxmox_inventory_containers_count=" + str(len(containers)))
for item in containers:
    print("proxmox_inventory_container=" + str(item.get("vmid")) + ":" + str(item.get("status")) + ":" + str(item.get("name")))
print("proxmox_inventory_vms_count=" + str(len(vms)))
if not data.get("ok") or str(data.get("host_id")) != "pveso" or len(containers) < 1:
    raise SystemExit(1)
PY
rm -f "$tmp"
'
echo

echo "--- DB count guard ---"
pct exec 203 -- bash -lc '
set -euo pipefail
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
echo

echo "PASS_STAGE_16_E2H_SMOKE_PVESO_INVENTORY_PATH"
REMOTE
} 2>&1 | sanitize_stream
