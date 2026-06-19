#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mm-vm200-webroot-app-path-read-only-diagnostic"
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

require "Phase 14J-MM"
require "VM200 Webroot App Path Read-Only Diagnostic"
require "db2e2ca"
require "controller-phase-14j-mk-vm200-guest-exec-output-shape-read-only-2026-06-18"
require "guest_locate_exitcode=2"
require "guest_locate_stderr=FAIL: app.js target not found"
require "public_app_sha_after_failed_ml=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "public_app_state_after_failed_ml=old_app_still_deployed_no_public_change"
require "public_status_http=200"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "ct204_data_authority=false"
require "pvew_cache_read_exitcode=0"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "pathdiag_exitcode=2"
require "pathdiag_stdout_bytes=488"
require "appjs_paths_count=3"
require "index_src_paths_count=1"
require "live_wrapper_path=/var/www/apc-wrapper-local/app.js"
require "live_index_path=/var/www/apc-wrapper-local/index.html"
require "next_target_strategy=deploy_to_live_wrapper_path"
require "No VM200 app.js write"
require "no qemu guest-agent operation during recovery record"
require "no frontend deploy"
require "no Cloudflare/DNS/tunnel mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MM_VM200_WEBROOT_APP_PATH_READ_ONLY_DIAGNOSTIC_DONE"

echo "PASS: 14J-MM VM200 webroot app path diagnostic evidence present"
echo "PASS_${PHASE}"
