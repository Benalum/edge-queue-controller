#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mq-ct203-private-storage-backup-execution-plan-no-apply"
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

require "Phase 14J-MQ"
require "CT203 Private-Storage Backup Execution Plan No-Apply"
require "a77f486"
require "controller-phase-14j-mp-pvew-ct203-backup-storage-inventory-read-only-2026-06-18"
require "PASS_PHASE_14J_MP_PVEW_CT203_BACKUP_STORAGE_INVENTORY_READ_ONLY_DONE"
require "pvew_ct203_status=running"
require "pvew_ct204_status=stopped"
require "pvew_vm200_status=running"
require "pvew_private_storage_mountpoint=/srv/apc-private-data"
require "pvew_private_storage_findmnt=mounted_or_path_on_mount"
require "pvew_private_storage_dir_mode=700 owner=root group=root"
require "storage_policy=manual-unlock-only"
require "storage_mount_state=unknown"
require "ct204_data_authority_public=false"
require "ct203_inside_connect=pass"
require "CT203_PROJECT_CANDIDATE=/opt/edge-queue-controller"
require "CT203_DB_FILE=/var/lib/edge-queue-controller/edge_queue.sqlite3"
require "CT203_ENV_FILE_PATH_ONLY=/etc/edge-queue-controller/edge-queue-controller.env"
require "CT203_BINARY_sqlite3=present"
require "CT203_BINARY_pg_dump=missing"
require "/srv/apc-private-data/backups/ct203"
require "sqlite3 /var/lib/edge-queue-controller/edge_queue.sqlite3"
require "Do not print contents"
require "Confirm CT204 is stopped before and after"
require "Not unlock, mount, format, or alter private storage"
require "Not start CT204"
require "Not restart or reload CT203 service"
require "Not print secrets"
require "APPROVE_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART"
require "Create one timestamped backup directory under `/srv/apc-private-data/backups/ct203`"
require "Generate backup manifest and SHA256SUMS"
require "Storage unlock/mount/format/key/crypttab/fstab mutation"
require "PASS_PHASE_14J_MQ_CT203_PRIVATE_STORAGE_BACKUP_EXECUTION_PLAN_NO_APPLY_DONE"

echo "PASS: 14J-MQ CT203 private-storage backup execution plan no-apply evidence present"
echo "PASS_${PHASE}"
