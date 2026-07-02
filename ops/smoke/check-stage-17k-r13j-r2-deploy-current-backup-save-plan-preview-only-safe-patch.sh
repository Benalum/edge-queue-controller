#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13j-r2-deploy-current-backup-save-plan-preview-only-safe-patch.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13j-r2-deploy-current-backup-save-plan-preview-only-safe-patch"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
SAVE_PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-plan.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Current Backup Save-Plan Preview Only, Safe Patch" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No save/write/overwrite helper" "$DOC"

grep -Fq "stage17k-r13j-r2-current-backup-save-plan-preview-only-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SAVE_PLAN_PREVIEW_BIND_R13J_R2" "$MOUNT"
grep -Fq "Save-plan preview only. No save, merge, restore, or overwrite action is available." "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN_R13I_SOURCE_ONLY" "$SAVE_PLAN"

grep -Fq "R13J_R2_VM200_CURRENT_BACKUP_SAVE_PLAN_PREVIEW_ONLY_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13J-R2 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13j-r2 deploy current backup save-plan preview only safe patch smoke"
