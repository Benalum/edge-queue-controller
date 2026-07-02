#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13j-r3-finalize-save-plan-preview-after-whitespace.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13j-r3-finalize-save-plan-preview-after-whitespace"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
SAVE_PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-plan.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Finalize Save-Plan Preview After Whitespace" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No save/write/overwrite helper" "$DOC"

grep -Fq "stage17k-r13j-r2-current-backup-save-plan-preview-only-20260702" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SAVE_PLAN_PREVIEW_BIND_R13J_R2" "$MOUNT"
grep -Fq "Save-plan preview only. No save, merge, restore, or overwrite action is available." "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN_R13I_SOURCE_ONLY" "$SAVE_PLAN"

grep -Fq "R13J_R3_VM200_SAVE_PLAN_PREVIEW_WHITESPACE_FINALIZE_DEPLOY_DONE" "$OUT_DIR/vm200-redeploy."*.txt
grep -Fq "PASS live static R13J-R3 smoke" "$OUT_DIR/live-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/api-guard."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/api-guard."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/api-guard."*.txt

echo "PASS stage-17k-r13j-r3 finalize save-plan preview after whitespace smoke"
