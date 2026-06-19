#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mt-private-storage-lock-readiness-read-only"
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

require "Phase 14J-MT"
require "Private Storage Lock Readiness Read-Only"
require "6ba6db8"
require "controller-phase-14j-ms-independent-ct203-backup-bundle-verification-read-only-2026-06-18"
require "PASS_PHASE_14J_MS_INDEPENDENT_CT203_BACKUP_BUNDLE_VERIFICATION_READ_ONLY_DONE"
require "public_status_http_before=200"
require "overall_state_before=online"
require "normalized_schema_version_before=2"
require "node_ids_sorted_before=ct-203,ct-204,pvew,vm-200"
require "storage_policy_before=manual-unlock-only"
require "storage_mount_state_before=unknown"
require "pvew_readiness_exitcode=0"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "ct203_status=running"
require "ct204_status=stopped"
require "vm200_status=running"
require "ct203_service_state=active"
require "private_mount=/srv/apc-private-data"
require "private_storage_findmnt=mounted_or_path_on_mount"
require "private_storage_source=/dev/mapper/apc_private_data"
require "private_storage_filesystem=ext4"
require "private_storage_dir_mode=700 owner=root group=root"
require "backup_parent=/srv/apc-private-data/backups/ct203"
require "latest_bundle=/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z"
require "latest_backup_bundle_required_files_present=yes"
require "latest_bundle_manifest_phase=14J-MR"
require "latest_bundle_env_file_contents_printed=no"
require "latest_bundle_sha256_check_exitcode=0"
require "latest_bundle_sha256_failed_count=0"
require "latest_env_mode=600"
require "latest_env_contents_printed=no"
require "private_storage_active_users_detected="
require "public_status_http_after=200"
require "overall_state_after=online"
require "storage_policy_after=manual-unlock-only"
require "storage_mount_state_after=unknown"
require "ct204_expected_state_after=stopped"
require "ct204_data_authority_after=false"
require "APPROVE_PHASE_14J_MV_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE"
require "no storage unlock/mount/unmount/format/key/crypttab/fstab mutation"
require "no private storage file creation/deletion/modification"
require "no new backup creation"
require "No secrets or env file contents were printed"
require "PASS_PHASE_14J_MT_PRIVATE_STORAGE_LOCK_READINESS_READ_ONLY_DONE"

echo "PASS: 14J-MT private-storage lock readiness evidence present"
echo "PASS_${PHASE}"
