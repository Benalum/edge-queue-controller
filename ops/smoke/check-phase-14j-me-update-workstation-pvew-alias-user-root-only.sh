#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-me-update-workstation-pvew-alias-user-root-only"
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

require "Phase 14J-ME"
require "Update Workstation PVEW Alias User Root Only"
require "APPROVE_PHASE_14J_ME_UPDATE_WORKSTATION_PVEW_ALIAS_USER_ROOT_ONLY"
require "017f1a9"
require "controller-phase-14j-md-retry-deploy-blocked-pvew-ssh-auth-user-2026-06-18"
require "local workstation \`~/.ssh/config\` managed \`Host pvew\` block \`User\` line only"
require "managed_begin_count=1"
require "managed_end_count=1"
require "managed_block_has_host_pvew=yes"
require "managed_block_hostname_class=tailscale-ip-redacted"
require "ssh_config_managed_host_pvew_user_updated=root"
require "managed_block_user_line_count_after=1"
require "managed_block_user_root_count_after=1"
require "managed_block_user_is_root_after=yes"
require "ssh_g_pvew_exitcode=0"
require "ssh_g_hostname_prefix_100=yes"
require "ssh_g_hostname_class=tailscale-ip-redacted"
require "ssh_g_user=root"
require "ssh_g_user_is_root=yes"
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
require "APPROVE_PHASE_14J_MF_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "PASS_PHASE_14J_ME_UPDATE_WORKSTATION_PVEW_ALIAS_USER_ROOT_ONLY_DONE"

echo "PASS: 14J-ME workstation PVEW alias User root evidence present"
echo "PASS_${PHASE}"
