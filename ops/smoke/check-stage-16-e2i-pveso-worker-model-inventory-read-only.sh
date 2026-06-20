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
  echo "=== Stage 16-E2I smoke: PVESO worker/model inventory read-only ==="
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

  echo "--- persistent PVESO inventory baseline smoke ---"
  ./ops/smoke/check-stage-16-e2h-pveso-persistent-firewall-inventory-verified.sh
  echo

  echo "--- PVESO worker/model facts, read-only ---"
  timeout 30 tailscale ssh root@pveso "set -euo pipefail; pct status 101 | grep -F 'status: stopped' >/dev/null; pct config 101 | grep -E '^onboot: 0$' >/dev/null; pct config 101 | grep -E '^mp0: /mnt/ollama-storage,mp=/mnt/ollama-models' >/dev/null; test -d /usr/share/ollama/.ollama/models; test -d /mnt/ollama-storage; test -d /mnt/ollama-storage/blobs; test -d /mnt/ollama-storage/manifests; command -v ollama >/dev/null; if command -v nvidia-smi >/dev/null 2>&1; then echo 'nvidia_smi_present=true'; else echo 'nvidia_smi_present=false'; fi; systemctl is-enabled ollama.service 2>/dev/null || true; systemctl is-active ollama.service 2>/dev/null || true; echo 'ct101_llms_stopped=true'; echo 'ollama_binary_present=true'; echo 'model_storage_paths_present=true'; echo 'NO_MUTATION_EXECUTED=true'"
  echo

  echo "PASS_STAGE_16_E2I_PVESO_WORKER_MODEL_INVENTORY_SMOKE"
} 2>&1 | sanitize_stream
