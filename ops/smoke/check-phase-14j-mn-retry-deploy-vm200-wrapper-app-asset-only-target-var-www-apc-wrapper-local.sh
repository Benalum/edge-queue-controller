#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mn-retry-deploy-vm200-wrapper-app-asset-only-target-var-www-apc-wrapper-local"
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

require "Phase 14J-MN"
require "Targeted VM200 Wrapper App Asset Deploy"
require "APPROVE_PHASE_14J_MN_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_TARGET_VAR_WWW_APC_WRAPPER_LOCAL"
require "3d0b10f"
require "controller-phase-14j-mm-vm200-webroot-app-path-read-only-diagnostic-2026-06-18"
require "VM200 single-file wrapper asset replacement only"
require "target_path=/var/www/apc-wrapper-local/app.js"
require "index_path=/var/www/apc-wrapper-local/index.html"
require "remote_deploy_mode=synchronous_guest_exec_no_pid"
require "guest_targetcheck_exitcode=0"
require "guest_deploy_exitcode=0"
require "vm200_app_sha_before=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "vm200_app_sha_after=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751"
require "vm200_app_legacy_hits=absent"
require "public_app_sha_after_cache_busted=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751"
require "public_deployed_legacy_hits_after=absent"
require "public_status_http_after=200"
require "overall_state_after=online"
require "normalized_schema_version_after=2"
require "node_ids_sorted_after=ct-203,ct-204,pvew,vm-200"
require "storage_policy_after=manual-unlock-only"
require "storage_mount_state_after=unknown"
require "ct204_expected_state_after=stopped"
require "ct204_data_authority_after=false"
require "No SSH config mutation"
require "no index.html mutation"
require "no Cloudflare/DNS/tunnel mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MN_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_TARGET_VAR_WWW_APC_WRAPPER_LOCAL_DONE"

echo "PASS: 14J-MN targeted VM200 wrapper app asset deploy evidence present"
echo "PASS_${PHASE}"
