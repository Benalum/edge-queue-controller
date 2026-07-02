#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13g-r2-deploy-open-current-backup-preview-button-safe-mount.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13g-r2-deploy-open-current-backup-preview-button-safe-mount"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
ADAPTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-access.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Open Current Backup File Preview Button, Safe Mount" "$DOC"
grep -Fq "Open current backup file" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No panel source edit" "$DOC"

grep -Fq "stage17k-r13g-r2-open-current-backup-preview-button-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SNAPSHOT_CURRENT_FILE_WORDING_R13E" "$PANEL"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_OPEN_CURRENT_FILE_PREVIEW_BIND_R13G_R2" "$MOUNT"
grep -Fq "Open current backup file" "$MOUNT"
grep -Fq "data-apc-local-backup-open-current" "$MOUNT"
grep -Fq "Current backup file preview complete. No data was restored or overwritten." "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS_ADAPTER_R13F_SOURCE_ONLY" "$ADAPTER"

grep -Fq "R13G_R2_VM200_OPEN_CURRENT_BACKUP_PREVIEW_BUTTON_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13G-R2 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13g-r2 deploy open current backup preview button safe mount smoke"
