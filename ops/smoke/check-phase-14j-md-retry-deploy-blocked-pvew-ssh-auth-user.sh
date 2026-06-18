#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-md-retry-deploy-blocked-pvew-ssh-auth-user"
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

require "Phase 14J-MD"
require "Retry Deploy Blocked: PVEW SSH Auth/User Denied"
require "APPROVE_PHASE_14J_MD_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "4f3037e"
require "controller-phase-14j-mc-update-workstation-pvew-alias-to-tailscale-ip-only-2026-06-18"
require "8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751"
require "ssh_g_hostname_class=tailscale-ip-redacted"
require "dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "public deployed legacy hit count before deploy was"
require "node_ids_sorted_before=ct-203,ct-204,pvew,vm-200"
require "storage_policy_before=manual-unlock-only"
require "ct204_data_authority_before=false"
require "Permission denied (publickey)"
require "no deploy performed"
require "No VM200 write occurred"
require "No qemu guest-agent operation reached VM200"
require "No frontend deploy occurred"
require "No Cloudflare/DNS/tunnel mutation occurred"
require "No service restart/reload/enable/start/stop occurred"
require "APPROVE_PHASE_14J_ME_UPDATE_WORKSTATION_PVEW_ALIAS_USER_ROOT_ONLY"
require "APPROVE_PHASE_14J_MF_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "PASS_PHASE_14J_MD_RETRY_DEPLOY_BLOCKED_PVEW_SSH_AUTH_USER_DONE"

echo "PASS: 14J-MD blocked SSH auth retry evidence present"
echo "PASS_${PHASE}"
