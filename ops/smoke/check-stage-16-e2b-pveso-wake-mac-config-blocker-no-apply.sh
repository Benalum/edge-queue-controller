#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-e2b-pveso-wake-mac-config-blocker-no-apply.md"

echo "=== Stage 16-E2B smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-E2B doc missing"
  exit 1
fi

require_text() {
  needle="$1"
  if grep -F -- "$needle" "$DOC" >/dev/null 2>&1; then
    echo "PASS: found required text: $needle"
  else
    echo "FAIL: missing required text: $needle"
    exit 1
  fi
}

require_text "PVESO Wake MAC Config Blocker, No Apply"
require_text "It does not wake PVESO."
require_text "It does not call /power/execute-wake."
require_text "It does not mutate configuration."
require_text "wake_plan_eligible=false"
require_text "EDGE_PROXMOX_WAKE_MAC is not configured."
require_text "Do not use the Tailscale virtual MAC for Wake-on-LAN."
require_text "Do not use a container MAC for host Wake-on-LAN."
require_text "Do not use VM/CT MACs for host Wake-on-LAN."
require_text "APPROVE_STAGE_16_E2C_CONFIGURE_PVESO_WAKE_MAC_ONLY_NO_WAKE_NO_WORKER_NO_MODEL_JOB"
require_text "add EDGE_PROXMOX_WAKE_MAC only"
require_text "not call /power/execute-wake"
require_text "not start workers"
require_text "not call Ollama"
require_text "not create jobs"
require_text "Only if wake_plan_eligible=true should /power/execute-wake be considered."

echo "PASS_STAGE_16_E2B_SMOKE"
