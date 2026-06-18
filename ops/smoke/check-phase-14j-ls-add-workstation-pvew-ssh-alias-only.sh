#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-ls-add-workstation-pvew-ssh-alias-only"
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

require "Phase 14J-LS"
require "Add Workstation PVEW SSH Alias Only"
require "APPROVE_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY"
require "9ab67c6"
require "controller-phase-14j-ma-vm200-wrapper-app-deploy-blocked-pvew-alias-missing-2026-06-18"
require "local workstation \`~/.ssh/config\` managed \`Host pvew\` block only"
require "tailscale_backend_state=Running"
require "pvew_peer_match_count=1"
require "pvew_peer_target_is_literal_pvew=no"
require "ssh_config_managed_host_pvew=written"
require "ssh_g_pvew_exitcode=0"
require "ssh_g_hostname_matches_target=yes"
require "ssh_g_hostname_literal_pvew=no"
require "ssh_g_user_present=yes"
require "ssh_g_port=22"
require "No SSH connection attempt"
require "no qemu guest-agent operation"
require "no VM200 write"
require "no frontend deploy"
require "no Cloudflare/DNS/tunnel mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "APPROVE_PHASE_14J_MB_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "PASS_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY_DONE"

echo "PASS: 14J-LS workstation PVEW SSH alias evidence present"
echo "PASS_${PHASE}"
