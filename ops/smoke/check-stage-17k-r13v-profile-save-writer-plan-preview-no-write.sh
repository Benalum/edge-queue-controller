#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13v-profile-save-writer-plan-preview-no-write.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13v-profile-save-writer-plan-preview-no-write"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
WRITER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Profile Save Writer Plan Preview, No Write" "$DOC"
grep -Fq "Current backup save plan" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No current-file save" "$DOC"
grep -Fq "No same-file write path" "$DOC"
grep -Fq "No File System Access write stream" "$DOC"

grep -Fq "stage17k-r13v-profile-save-writer-plan-preview-no-write-20260705" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SAVE_WRITER_PLAN_PREVIEW_R13V" "$MOUNT"
grep -Fq "function renderSaveWriterPlanPreviewR13V()" "$MOUNT"
grep -Fq "data-apc-local-backup-save-writer-plan-preview-r13v" "$MOUNT"
grep -Fq "Preview only. No file is saved, replaced, merged, restored, or overwritten." "$MOUNT"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER_R13S_SOURCE_ONLY" "$WRITER"
grep -Fq "sameFileWriteEnabled: false" "$WRITER"
grep -Fq "currentFileWriteEnabled: false" "$WRITER"
grep -Fq "previousFileWriteEnabled: false" "$WRITER"

grep -Fq "R13V_VM200_PROFILE_SAVE_WRITER_PLAN_PREVIEW_NO_WRITE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R13V smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r13v profile save writer plan preview no write smoke"
