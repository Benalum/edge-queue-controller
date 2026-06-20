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
  echo "=== Stage 16-E2J smoke: PVESO model runtime readiness plan no-apply ==="
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

  echo "--- prior E2I inventory smoke ---"
  ./ops/smoke/check-stage-16-e2i-pveso-worker-model-inventory-read-only.sh
  echo

  echo "--- doc policy assertions ---"
  doc="docs/stage-16-e2j-pveso-model-runtime-readiness-plan-no-apply.md"
  test -f "$doc"
  grep -F "Option A" "$doc" >/dev/null
  grep -F "Option B" "$doc" >/dev/null
  grep -F "Option C" "$doc" >/dev/null
  grep -F "CT101-first readiness" "$doc" >/dev/null
  grep -F "do not start CT101" "$doc" >/dev/null
  grep -F "do not call \`ollama list\`" "$doc" >/dev/null
  grep -F "do not register workers" "$doc" >/dev/null
  echo "doc_policy_assertions_ok=true"
  echo

  echo "--- live safety quick-check, read-only ---"
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" "set -euo pipefail; qm status 200; pct status 203; pct status 204; pct exec 203 -- grep -E '^EDGE_POWER_EXECUTE_WAKE=false$' /etc/edge-queue-controller/edge-queue-controller.env >/dev/null; pct exec 203 -- systemctl is-active edge-queue-controller.service"
  timeout 20 tailscale ssh root@pveso "set -euo pipefail; pct status 101 | grep -F 'status: stopped' >/dev/null; test -d /mnt/ollama-storage; test -d /usr/share/ollama/.ollama/models; echo 'ct101_still_stopped=true'; echo 'model_paths_still_present=true'; echo 'NO_MUTATION_EXECUTED=true'"
  echo

  echo "PASS_STAGE_16_E2J_MODEL_RUNTIME_READINESS_PLAN_NO_APPLY_SMOKE"
} 2>&1 | sanitize_stream
