#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12v-deploy-profile-backup-preview-button.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12v-deploy-profile-backup-preview-button"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-restore-preview-bridge.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Profile Backup Preview Button" "$DOC"
grep -Fq "Preview only" "$DOC"
grep -Fq "No restore write path exists" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"

grep -Fq "local-backup-media-schema.js?v=stage17k-z-r12v-profile-backup-preview-button-20260702" "$INDEX"
grep -Fq "profile-local-backups-restore-preview-bridge.js?v=stage17k-z-r12v-profile-backup-preview-button-20260702" "$INDEX"
grep -Fq "profile-local-backups-panel.js?v=stage17k-z-r12v-profile-backup-preview-button-20260702" "$INDEX"
grep -Fq "profile-local-backups-mount.js?v=stage17k-z-r12v-profile-backup-preview-button-20260702" "$INDEX"

grep -Fq "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BUTTON_R12V" "$PANEL"
grep -Fq "Preview backup file" "$PANEL"
grep -Fq "data-apc-local-backup-preview-restore" "$PANEL"
grep -Fq "data-apc-local-backup-restore-preview-output" "$PANEL"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BIND_R12V" "$MOUNT"
grep -Fq "Backup preview complete. No data was restored." "$MOUNT"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE_R12U_SOURCE_ONLY" "$BRIDGE"

grep -Fq "R12V_VM200_PROFILE_BACKUP_PREVIEW_BUTTON_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12V smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12v deploy Profile backup preview button smoke"
