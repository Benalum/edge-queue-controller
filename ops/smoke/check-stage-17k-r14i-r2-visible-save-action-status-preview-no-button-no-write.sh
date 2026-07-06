#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14i-r2-visible-save-action-status-preview-no-button-no-write.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14i-r2-visible-save-action-status-preview-no-button-no-write"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Visible Save Action Status Preview, No Button, No Write" "$DOC"
grep -Fq "Recovery note" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No write binding" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "stage17k-r14i-r2-visible-save-action-status-preview-no-button-no-write-20260705" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_SAVE_ACTION_STATUS_PREVIEW_R14I_R2" "$MOUNT"
grep -Fq "data-apc-local-backup-save-action-status-preview-r14i-r2" "$MOUNT"
grep -Fq "createSaveCurrentBackupActionState" "$MOUNT"
grep -Fq "Can write now" "$MOUNT"
grep -Fq "Writes enabled now" "$MOUNT"
grep -Fq "Executor call allowed now" "$MOUNT"
grep -Fq "No Save button was added" "$MOUNT"

if grep -Fq ".executeCurrentBackupWrite(" "$MOUNT"; then
  echo "FAIL: mount calls executor write function"
  exit 1
fi

grep -Fq "R14I_R2_VM200_VISIBLE_SAVE_ACTION_STATUS_PREVIEW_NO_BUTTON_NO_WRITE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14I-R2 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14i-r2 visible save action status preview no button no write smoke"
