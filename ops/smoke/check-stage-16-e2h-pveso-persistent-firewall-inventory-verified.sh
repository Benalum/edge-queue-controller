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
  echo "=== Stage 16-E2H persistent firewall inventory smoke ==="
  echo "MUTATION_SCOPE=read_only_smoke_only"
  echo "NO firewall mutation"
  echo "NO env mutation"
  echo "NO service restart/reload"
  echo "NO wake execution"
  echo "NO DB write"
  echo "NO CT/VM start/stop/restart"
  echo "NO worker/model/scheduler activation"
  echo "NO Ollama/model endpoint calls"
  echo "NO CT204/private-storage mutation"
  echo

  cd "$(git rev-parse --show-toplevel)"

  echo "--- baseline inventory smoke from prior E2H checkpoint ---"
  ./ops/smoke/check-stage-16-e2h-pveso-lan-inventory-path-runtime-firewall.sh
  echo

  echo "--- PVESO persistent/runtime firewall marker check ---"
  timeout 25 tailscale ssh root@pveso "set -euo pipefail; node=\$(hostname); grep -F 'apc-stage16e2h-ct203-pveso-inventory' /etc/nftables.d/tslock.nft >/dev/null; grep -F 'apc-stage16e2h-ct203-pveso-inventory-pvefw-host' /etc/pve/nodes/\${node}/host.fw >/dev/null; nft -a list chain inet tslock input | grep -F 'apc-stage16e2h-ct203-pveso-inventory' >/dev/null; iptables -S PVEFW-HOST-IN | grep -F -- '-s ' | grep -F -- '--dport 22' | grep -F -- '-j RETURN' >/dev/null; pve-firewall status 2>/dev/null | grep -F 'enabled/running' >/dev/null; echo 'pveso_persistent_markers_present=true'; echo 'pveso_runtime_firewall_paths_loaded=true'; echo 'NO_MUTATION_EXECUTED=true'"
  echo

  echo "PASS_STAGE_16_E2H_PERSISTENT_FIREWALL_INVENTORY_SMOKE"
} 2>&1 | sanitize_stream
