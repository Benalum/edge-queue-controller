#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mb-retry-deploy-blocked-pvew-dns-resolution"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

require() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing required pattern: $pattern"
    exit 1
  fi
}

test -f "$DOC"

require "Phase 14J-MB"
require "Retry Deploy Blocked: PVEW Tailscale DNS Resolution"
require "APPROVE_PHASE_14J_MB_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "f1b0cb7"
require "controller-phase-14j-ls-add-workstation-pvew-ssh-alias-only-2026-06-18"
require "repo app source hash was \`8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751\`"
require "public app hash before deploy was \`dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812\`"
require "public deployed legacy hit count before deploy was \`10\`"
require "node_ids_sorted_before=ct-203,ct-204,pvew,vm-200"
require "storage_policy_before=manual-unlock-only"
require "ct204_data_authority_before=false"
require "ssh: Could not resolve hostname <redacted-tailscale-dns>"
require "phase_exit_code=255"
require "No VM200 write occurred"
require "No qemu guest-agent operation reached VM200"
require "No frontend deploy occurred"
require "No Cloudflare/DNS/tunnel mutation occurred"
require "No service restart/reload/enable/start/stop occurred"
require "APPROVE_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY"
require "APPROVE_PHASE_14J_MD_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "PASS_PHASE_14J_MB_RETRY_DEPLOY_BLOCKED_PVEW_DNS_RESOLUTION_DONE"

echo "PASS: 14J-MB blocked DNS retry evidence present"
echo "PASS_${PHASE}"
