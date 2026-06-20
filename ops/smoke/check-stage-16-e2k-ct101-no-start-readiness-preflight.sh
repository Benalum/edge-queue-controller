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
  echo "=== Stage 16-E2K smoke: CT101 no-start readiness preflight ==="
  echo "MUTATION_SCOPE=read_only_smoke_only"
  echo "NO firewall mutation"
  echo "NO env mutation"
  echo "NO service restart/reload/start/stop"
  echo "NO wake execution"
  echo "NO DB write"
  echo "NO CT/VM start/stop/restart"
  echo "NO pct mount"
  echo "NO worker/model/scheduler activation"
  echo "NO Ollama/model endpoint calls"
  echo "NO CT204/private-storage mutation"
  echo

  cd "$(git rev-parse --show-toplevel)"

  echo "--- local doc policy assertions ---"
  doc="docs/stage-16-e2k-ct101-no-start-readiness-preflight.md"
  test -f "$doc"
  grep -F "No containers were started" "$doc" >/dev/null
  grep -F "APPROVE_STAGE_16_E2L_START_CT101_LLMS_FOR_READINESS_ONLY_NO_WORKER_REGISTRATION_NO_MODEL_JOB" "$doc" >/dev/null
  grep -F "do not call Ollama/model endpoints" "$doc" >/dev/null
  grep -F "do not register workers" "$doc" >/dev/null
  echo "doc_policy_assertions_ok=true"
  echo

  echo "--- platform authority safety via PVEW ---"
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" "set -euo pipefail; qm status 200; pct status 203; pct status 204; if findmnt /srv/apc-private-data >/dev/null 2>&1; then echo private_storage=mounted_UNEXPECTED; exit 1; else echo private_storage=not-mounted; fi; pct exec 203 -- grep -E '^EDGE_POWER_EXECUTE_WAKE=false$' /etc/edge-queue-controller/edge-queue-controller.env >/dev/null; pct exec 203 -- systemctl is-active edge-queue-controller.service"
  echo

  echo "--- PVESO/CT101 no-start readiness facts, read-only ---"
  timeout 35 tailscale ssh root@pveso "set -euo pipefail; pct status 101 | grep -F 'status: stopped' >/dev/null; pct config 101 | grep -E '^onboot: 0$' >/dev/null; pct config 101 | grep -E '^hostname: llms$' >/dev/null; pct config 101 | grep -E '^mp0: /mnt/ollama-storage,mp=/mnt/ollama-models' >/dev/null; pvesm list local-lvm --vmid 101 | grep -F 'vm-101' >/dev/null; test -d /mnt/ollama-storage/blobs; test -d /mnt/ollama-storage/manifests; test -d /mnt/ollama-storage/models; test -d /usr/share/ollama/.ollama/models; test -d /var/lib/vz/ollama/models; grep -F 'apc-stage16e2h-ct203-pveso-inventory' /etc/nftables.d/tslock.nft >/dev/null; echo 'ct101_still_stopped=true'; echo 'ct101_config_shape_ok=true'; echo 'ct101_storage_paths_present=true'; echo 'pveso_inventory_firewall_marker_present=true'; echo 'NO_MUTATION_EXECUTED=true'"
  echo

  echo "PASS_STAGE_16_E2K_CT101_NO_START_READINESS_PREFLIGHT_SMOKE"
} 2>&1 | sanitize_stream
