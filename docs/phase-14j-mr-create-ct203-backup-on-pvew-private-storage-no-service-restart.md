# Phase 14J-MR — Create CT203 Backup on PVEW Private Storage, No Service Restart

Updated: 2026-06-18

## Purpose

This phase created one timestamped CT203 backup bundle on already-mounted PVEW encrypted private storage.

## Approval

`APPROVE_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART`

## Prior checkpoint

- Phase: 14J-MQ-A — Smoke Backtick Hygiene Repair No-Apply.
- Commit: `fed0a48`.
- Tag: `controller-phase-14j-mq-a-smoke-backtick-hygiene-repair-no-apply-2026-06-18`.
- Result: `PASS_PHASE_14J_MQ_A_SMOKE_BACKTICK_HYGIENE_REPAIR_NO_APPLY_DONE`.

## Backup bundle

- backup_run_ts=20260619T002628Z
- backup_bundle_path=/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z
- backup_parent=/srv/apc-private-data/backups/ct203
- backup_manifest_created=yes
- backup_sha256sums_created=yes
- backup_sha256_entry_count=12
- backup_bundle_file_count=13
- backup_bundle_total_bytes=43826464

## Backup contents

- SQLite DB backup: `db/edge_queue.sqlite3`
- SQLite integrity output: `db/edge_queue.integrity.txt`
- SQLite schema: `db/edge_queue.schema.sql`
- SQLite table list: `db/edge_queue.tables.txt`
- CT203 env file: `config/edge-queue-controller.env`
- CT203 systemd metadata: `systemd/edge-queue-controller.service.*`
- CT203 project metadata: `project/project-metadata.txt`
- CT203 state metadata: `state/ct203-state.txt`
- Bundle manifest: `MANIFEST.txt`
- Bundle hash list: `SHA256SUMS`

## Size evidence

- backup_db_bytes=43794432
- backup_env_bytes=1076
- backup_systemd_cat_bytes=575

## PVEW / private storage evidence

- pvew_backup_exitcode=0
- pvew_ssh_connect=pass
- pvew_remote_user=root
- pvew_pct_binary=present
- pvew_qm_binary=present
- private_storage_findmnt=mounted_or_path_on_mount
- private_storage_mountpoint=/srv/apc-private-data
- private_storage_source=/dev/mapper/apc_private_data
- private_storage_filesystem=ext4
- private_storage_dir_mode=700 owner=root group=root

## CT / VM state evidence

- ct203_status_before=running
- ct203_status_after=running
- ct204_status_before=stopped
- ct204_status_after=stopped
- vm200_status_before=running
- vm200_status_after=running
- ct203_service_state_before=active
- ct203_service_state_after=active

## Backup method evidence

- sqlite_backup_created_inside_ct203=yes
- sqlite_backup_integrity_check=ok
- ct203_temp_backup_files_removed=yes
- ct203_env_file_copied_to_private_storage=yes
- ct203_env_file_contents_printed=no
- ct203_systemd_metadata_captured=yes
- ct203_project_metadata_captured=yes
- ct203_state_metadata_captured=yes
- backup_bundle_created_and_verified=yes

## Public status before backup

- public_status_http_before=200
- overall_state_before=online
- normalized_schema_version_before=2
- node_ids_sorted_before=ct-203,ct-204,pvew,vm-200
- storage_policy_before=manual-unlock-only
- storage_mount_state_before=unknown
- storage_mountpoint_before=/srv/apc-private-data
- ct204_expected_state_before=stopped
- ct204_data_authority_before=false

## Public status after backup

- public_status_http_after=200
- overall_state_after=online
- normalized_schema_version_after=2
- node_ids_sorted_after=ct-203,ct-204,pvew,vm-200
- storage_policy_after=manual-unlock-only
- storage_mount_state_after=unknown
- storage_mountpoint_after=/srv/apc-private-data
- ct204_expected_state_after_public=stopped
- ct204_data_authority_after_public=false

## Safety posture retained

- CT203 remains controller/API/queue authority.
- VM200 remains public/static only.
- CT204 remains stopped, backup-data-only, and non-authoritative.
- Private storage remains manual-unlock-only.
- Public private storage mount_state remains unknown.
- PVESO remains parked/on-demand.
- Cloudflare/DNS/tunnels were not changed.
- Services were not restarted or reloaded.
- No env file contents or secrets were printed.

## Mutation scope

Created one timestamped backup directory under already-mounted PVEW private storage. No CT start/stop/restart, no VM start/stop/restart, no service restart/reload/enable/start/stop, no storage unlock/mount/format/key/crypttab/fstab mutation, no DB restore/import/migration, no CT204 start, no CT204 data authority change, no Cloudflare/DNS/tunnel mutation, no frontend deploy, no app source mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Result marker

`PASS_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_DONE`
