# Phase 14J-MS — Independent CT203 Backup Bundle Verification Read-Only

Updated: 2026-06-18

## Purpose

This phase performed an independent read-only verification of the CT203 backup bundle created in Phase 14J-MR.

## Prior checkpoint

- Phase: 14J-MR — Create CT203 Backup on PVEW Private Storage, No Service Restart.
- Commit: `d7c57a4`.
- Tag: `controller-phase-14j-mr-create-ct203-backup-on-pvew-private-storage-no-service-restart-2026-06-18`.
- Result: `PASS_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_DONE`.

## Verified bundle

- verify_bundle_path=/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z
- pvew_verify_exitcode=0
- pvew_ssh_connect=pass
- pvew_remote_user=root
- backup_required_files_present=yes
- backup_independent_verification=pass

## Hash verification

- sha256_check_exitcode=0
- sha256_ok_count=12
- sha256_failed_count=0

## SQLite read-only verification

- sqlite_readonly_integrity_verification=pass
- sqlite_integrity_check=ok
- sqlite_page_count=10692
- sqlite_table_count=40

## Env/config safety verification

- backup_env_file_mode=600
- backup_env_file_owner=root
- backup_env_file_group=root
- backup_env_file_bytes=1076
- backup_env_file_contents_printed=no

## Size and file-count evidence

- backup_db_bytes=43794432
- backup_bundle_file_count=13
- backup_bundle_total_bytes=43826464

## Manifest safety verification

- manifest_phase=14J-MR
- manifest_env_file_contents_printed=no
- manifest_services_restarted_or_reloaded=no
- manifest_ct204_started=no
- manifest_storage_unlock_mount_format_key_crypttab_fstab_mutation=no
- manifest_safety_fields_verified=yes

## Runtime state after verification

- ct203_service_state_after=active
- ct203_status_after=running
- ct204_status_after=stopped
- vm200_status_after=running

## Public status before verification

- public_status_http_before=200
- overall_state_before=online
- normalized_schema_version_before=2
- node_ids_sorted_before=ct-203,ct-204,pvew,vm-200
- storage_policy_before=manual-unlock-only
- storage_mount_state_before=unknown
- ct204_expected_state_before=stopped
- ct204_data_authority_before=false

## Public status after verification

- public_status_http_after=200
- overall_state_after=online
- normalized_schema_version_after=2
- node_ids_sorted_after=ct-203,ct-204,pvew,vm-200
- storage_policy_after=manual-unlock-only
- storage_mount_state_after=unknown
- ct204_expected_state_after=stopped
- ct204_data_authority_after=false

## Mutation scope

This was read-only backup bundle verification plus repo documentation. No CT start/stop/restart, no VM start/stop/restart, no service restart/reload/enable/start/stop, no storage unlock/mount/format/key/crypttab/fstab mutation, no new backup creation, no private storage file creation/deletion/modification, no DB mutation, no DB backup creation, no DB restore/import/migration, no CT204 start, no CT204 data authority change, no Cloudflare/DNS/tunnel mutation, no frontend deploy, no app source mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred. No secrets or env file contents were printed.

## Result marker

`PASS_PHASE_14J_MS_INDEPENDENT_CT203_BACKUP_BUNDLE_VERIFICATION_READ_ONLY_DONE`
