#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-ms-independent-ct203-backup-bundle-verification-read-only"
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

require "Phase 14J-MS"
require "Independent CT203 Backup Bundle Verification Read-Only"
require "d7c57a4"
require "controller-phase-14j-mr-create-ct203-backup-on-pvew-private-storage-no-service-restart-2026-06-18"
require "PASS_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_DONE"
require "verify_bundle_path=/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z"
require "pvew_verify_exitcode=0"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "backup_required_files_present=yes"
require "backup_independent_verification=pass"
require "sha256_check_exitcode=0"
require "sha256_ok_count="
require "sha256_failed_count=0"
require "sqlite_readonly_integrity_verification=pass"
require "sqlite_integrity_check=ok"
require "sqlite_page_count="
require "sqlite_table_count="
require "backup_env_file_mode=600"
require "backup_env_file_owner=root"
require "backup_env_file_group=root"
require "backup_env_file_contents_printed=no"
require "manifest_phase=14J-MR"
require "manifest_env_file_contents_printed=no"
require "manifest_services_restarted_or_reloaded=no"
require "manifest_ct204_started=no"
require "manifest_safety_fields_verified=yes"
require "ct203_service_state_after=active"
require "ct203_status_after=running"
require "ct204_status_after=stopped"
require "vm200_status_after=running"
require "public_status_http_before=200"
require "public_status_http_after=200"
require "overall_state_after=online"
require "normalized_schema_version_after=2"
require "node_ids_sorted_after=ct-203,ct-204,pvew,vm-200"
require "storage_policy_after=manual-unlock-only"
require "storage_mount_state_after=unknown"
require "ct204_expected_state_after=stopped"
require "ct204_data_authority_after=false"
require "no new backup creation"
require "no private storage file creation/deletion/modification"
require "no DB restore/import/migration"
require "no CT204 start"
require "No secrets or env file contents were printed"
require "PASS_PHASE_14J_MS_INDEPENDENT_CT203_BACKUP_BUNDLE_VERIFICATION_READ_ONLY_DONE"

echo "PASS: 14J-MS independent backup bundle verification evidence present"
echo "PASS_${PHASE}"
