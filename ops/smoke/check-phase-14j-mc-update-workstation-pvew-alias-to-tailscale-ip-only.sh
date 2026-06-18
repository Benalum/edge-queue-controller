#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mc-update-workstation-pvew-alias-to-tailscale-ip-only"
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

require "Phase 14J-MC"
require "Update Workstation PVEW Alias to Tailscale IP Only"
require "APPROVE_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY"
require "3d0cfce"
require "controller-phase-14j-mb-retry-deploy-blocked-pvew-dns-resolution-2026-06-18"
require "local workstation \`~/.ssh/config\` managed \`Host pvew\` block \`HostName\` line only"
require "tailscale_backend_state=Running"
require "pvew_peer_match_count=1"
require "pvew_tailscale_ipv4_found=yes"
require "pvew_alias_target_class=tailscale-ip-redacted"
require "pvew_alias_target_ipv4_prefix_100=yes"
require "managed_begin_count=1"
require "managed_end_count=1"
require "managed_block_has_host_pvew=yes"
require "managed_block_hostname_line_count=1"
require "ssh_config_managed_host_pvew_hostname_updated=yes"
require "ssh_g_pvew_exitcode=0"
require "ssh_g_hostname_matches_tailscale_ip=yes"
require "ssh_g_hostname_prefix_100=yes"
require "ssh_g_hostname_class=tailscale-ip-redacted"
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
require "APPROVE_PHASE_14J_MD_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY"
require "PASS_PHASE_14J_MC_UPDATE_WORKSTATION_PVEW_ALIAS_TO_TAILSCALE_IP_ONLY_DONE"

echo "PASS: 14J-MC workstation PVEW alias Tailscale IP update evidence present"
echo "PASS_${PHASE}"
