#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mp-pvew-ct203-backup-storage-inventory-read-only"
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

require "Phase 14J-MP"
require "PVEW/CT203 Backup-Storage Inventory Read-Only"
require "f299f29"
require "controller-phase-14j-mo-post-targeted-vm200-wrapper-app-deploy-public-regression-read-only-2026-06-18"
require "PASS_PHASE_14J_MO_POST_TARGETED_VM200_WRAPPER_APP_DEPLOY_PUBLIC_REGRESSION_READ_ONLY_DONE"
require "public_status_http=200"
require "overall_state=online"
require "normalized_schema_version=2"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "storage_mount_state=unknown"
require "storage_mountpoint=/srv/apc-private-data"
require "ct204_expected_state_public=stopped"
require "ct204_data_authority_public=false"
require "pvew_inventory_exitcode=0"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "pvew_pct_binary=present"
require "pvew_ct203_status=running"
require "pvew_ct204_status=stopped"
require "pvew_vm200_status=running"
require "ct204_expected_stopped_confirmed=yes"
require "ct203_inside_connect=pass"
require "ct203_db_file_count="
require "ct203_compose_file_count="
require "ct203_env_file_path_count="
require "No CT start/stop/restart"
require "no service restart/reload/enable/start/stop"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no private storage write"
require "no DB backup creation"
require "no DB restore/import/migration"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MP_PVEW_CT203_BACKUP_STORAGE_INVENTORY_READ_ONLY_DONE"

echo "PASS: 14J-MP PVEW/CT203 backup-storage inventory evidence present"
echo "PASS_${PHASE}"
