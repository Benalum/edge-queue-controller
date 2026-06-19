#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mo-post-targeted-vm200-wrapper-app-deploy-public-regression-read-only"
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

require "Phase 14J-MO"
require "Post-Targeted VM200 Wrapper App Deploy Public Regression Read-Only"
require "156db84"
require "controller-phase-14j-mn-retry-deploy-vm200-wrapper-app-asset-only-target-var-www-apc-wrapper-local-2026-06-18"
require "PASS_PHASE_14J_MN_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_TARGET_VAR_WWW_APC_WRAPPER_LOCAL_DONE"
require "repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751"
require "repo_app_legacy_hits=absent"
require "public_root_http=200"
require "public_app_src=/app.js?v=2026061814jlbr2"
require "public_app_sha_cache_busted=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751"
require "public_app_legacy_hits=absent"
require "public_root_html_legacy_hits=absent"
require "public_status_http=200"
require "overall_state=online"
require "normalized_schema_version=2"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "storage_mount_state=unknown"
require "storage_mountpoint=/srv/apc-private-data"
require "ct204_expected_state=stopped"
require "ct204_data_authority=false"
require "VM200 live wrapper app path: \`/var/www/apc-wrapper-local/app.js\`"
require "VM200 live wrapper index path: \`/var/www/apc-wrapper-local/index.html\`"
require "No SSH connection"
require "no VM200 write"
require "no qemu guest-agent operation"
require "no Cloudflare/DNS/tunnel mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MO_POST_TARGETED_VM200_WRAPPER_APP_DEPLOY_PUBLIC_REGRESSION_READ_ONLY_DONE"

echo "PASS: 14J-MO public regression evidence present"
echo "PASS_${PHASE}"
