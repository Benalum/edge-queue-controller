# Phase 14J-MQ — CT203 Private-Storage Backup Execution Plan No-Apply

Updated: 2026-06-18

## Purpose

This phase defines the next approved backup creation step for CT203 after the Phase 14J-MP read-only inventory.

It is a no-apply plan only. It does not create a backup, write to private storage, unlock storage, mount storage, mutate databases, start/stop CTs or VMs, restart services, or change infrastructure.

## Prior checkpoint

- Phase: 14J-MP — PVEW/CT203 Backup-Storage Inventory Read-Only.
- Commit: `a77f486`.
- Tag: `controller-phase-14j-mp-pvew-ct203-backup-storage-inventory-read-only-2026-06-18`.
- Result: `PASS_PHASE_14J_MP_PVEW_CT203_BACKUP_STORAGE_INVENTORY_READ_ONLY_DONE`.

## Read-only inventory facts from 14J-MP

PVEW / platform state:

- `pvew_ssh_connect=pass`
- `pvew_remote_user=root`
- `pvew_pct_binary=present`
- `pvew_qm_binary=present`
- `pvew_ct203_status=running`
- `pvew_ct204_status=stopped`
- `pvew_vm200_status=running`
- `ct204_expected_stopped_confirmed=yes`

Private storage state:

- `pvew_private_storage_mountpoint=/srv/apc-private-data`
- `pvew_private_storage_findmnt=mounted_or_path_on_mount`
- `pvew_private_storage_findmnt_line=/srv/apc-private-data /dev/mapper/apc_private_data ext4 rw,relatime`
- `pvew_private_storage_dir_exists=yes`
- `pvew_private_storage_dir_mode=700 owner=root group=root`
- `PVEW_MAPPER_CANDIDATE=apc_private_data`

Public masking remains correct:

- `storage_policy=manual-unlock-only`
- `storage_mount_state=unknown`
- `storage_mountpoint=/srv/apc-private-data`
- `ct204_expected_state_public=stopped`
- `ct204_data_authority_public=false`

CT203 inventory facts:

- `ct203_inside_connect=pass`
- `ct203_hostname=edge-controller-pvew`
- `ct203_user=root`
- `ct203_os_pretty=Debian GNU/Linux 13 (trixie)`
- `CT203_SERVICE=edge-queue-controller.service loaded active running AI Platform Control CT203 Edge Queue Controller`
- `CT203_PROJECT_CANDIDATE=/opt/edge-queue-controller type=directory mode=700 owner=root group=root`
- `CT203_DB_FILE=/var/lib/edge-queue-controller/edge_queue.sqlite3`
- `CT203_ENV_FILE_PATH_ONLY=/etc/edge-queue-controller/edge-queue-controller.env`
- `CT203_ENV_FILE_PATH_ONLY=/etc/edge-queue-controller/edge-queue-controller.env.bak-20260618T172948Z`
- `CT203_BACKUP_CANDIDATE=/var/backups type=directory mode=755 owner=root group=root`
- `CT203_BINARY_sqlite3=present`
- `CT203_BINARY_python3=present`
- `CT203_BINARY_systemctl=present`
- `CT203_BINARY_psql=missing`
- `CT203_BINARY_pg_dump=missing`

## Backup objective for next approved phase

Create a CT203 point-in-time backup bundle on PVEW encrypted private storage.

Target parent directory:

`/srv/apc-private-data/backups/ct203`

Recommended timestamped bundle directory shape:

`/srv/apc-private-data/backups/ct203/ct203-backup-YYYYMMDDTHHMMSSZ`

The bundle should include:

1. CT203 SQLite database backup:
   - Source: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
   - Preferred method inside CT203: `sqlite3 /var/lib/edge-queue-controller/edge_queue.sqlite3 ".backup '/tmp/<staged-db-backup>'"`
   - Reason: avoids raw copying a live SQLite DB if the controller service is active.

2. CT203 service environment file:
   - Source path only known: `/etc/edge-queue-controller/edge-queue-controller.env`
   - The file may contain secrets. Do not print contents.
   - Copy into encrypted private storage only after explicit approval.

3. CT203 systemd service unit metadata:
   - Read-only command in apply phase: `systemctl cat edge-queue-controller.service`
   - Store output in backup bundle.
   - Do not restart/reload the service.

4. CT203 project metadata:
   - Source directory: `/opt/edge-queue-controller`
   - Capture minimal metadata first: current release link/path if present, Git/head marker if present, selected file list.
   - Do not copy large virtualenv/package caches unless separately approved.
   - Avoid copying `/opt/edge-queue-controller/venv` into this first backup bundle.

5. Backup manifest:
   - Bundle path.
   - UTC timestamp.
   - PVEW host.
   - CT203 status before and after.
   - CT204 status remains stopped.
   - VM200 status remains running.
   - SHA256 for every copied backup file.
   - Safety exclusions.
   - Confirmation that no services were restarted/reloaded.

## Apply-phase safety requirements

The next apply phase must:

- Require explicit approval.
- Confirm repo HEAD and previous tag before acting.
- Confirm public status is healthy before and after.
- Confirm CT203 is running before backup.
- Confirm CT204 is stopped before and after.
- Confirm VM200 is running before and after.
- Confirm `/srv/apc-private-data` is already mounted before writing.
- Not unlock, mount, format, or alter private storage.
- Not start CT204.
- Not stop CT203.
- Not restart or reload CT203 service.
- Not mutate the database except for SQLite read-consistent backup API.
- Not print secrets.
- Not print env file contents.
- Not copy secrets anywhere except the encrypted private-storage backup bundle.
- Not alter Cloudflare, DNS, tunnels, nginx, cloudflared, Tailscale, or VM/CT config.
- Produce a manifest and SHA256SUMS file inside the backup bundle.
- Record backup bundle path and hashes in repo documentation without secret contents.

## Proposed next approval phrase

`APPROVE_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART`

## Proposed next phase mutation scope

Allowed only after approval:

- Create one timestamped backup directory under `/srv/apc-private-data/backups/ct203`.
- Create a SQLite backup of `/var/lib/edge-queue-controller/edge_queue.sqlite3` from CT203.
- Copy selected CT203 config/service metadata into the encrypted backup bundle.
- Generate backup manifest and SHA256SUMS.
- Record evidence in repo docs/smoke/commit/tag/push.

Still forbidden:

- CT start/stop/restart.
- VM start/stop/restart.
- Service restart/reload/enable/start/stop.
- Storage unlock/mount/format/key/crypttab/fstab mutation.
- DB restore/import/migration.
- CT204 start.
- CT204 data authority change.
- Cloudflare/DNS/tunnel mutation.
- Frontend deploy.
- App source mutation.
- Tailscale config/auth mutation.
- PVESO wake/start.

## Result marker

`PASS_PHASE_14J_MQ_CT203_PRIVATE_STORAGE_BACKUP_EXECUTION_PLAN_NO_APPLY_DONE`
