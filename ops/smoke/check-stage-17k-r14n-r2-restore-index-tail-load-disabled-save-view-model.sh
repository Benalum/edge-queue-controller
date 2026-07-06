#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14n-r2-restore-index-tail-load-disabled-save-view-model.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14n-r2-restore-index-tail-load-disabled-save-view-model"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
VIEWMODEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-view-model.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$VIEWMODEL"

grep -Fq "Restore Index Tail and Load Disabled Save View Model" "$DOC"
grep -Fq "Recovery note" "$DOC"
grep -Fq "removed scripts: none" "$DOC"
grep -Fq "No button" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "stage17k-r14n-r2-restore-index-tail-load-disabled-save-view-model-20260705" "$INDEX"
grep -Fq "/privatepages/profile-local-backups-mount.js?v=stage17k-r14i-r2-visible-save-action-status-preview-no-button-no-write-20260705" "$INDEX"
grep -Fq "/privatepages/anki-manifest-panel.js" "$INDEX"
grep -Fq "/privatepages/companion.js" "$INDEX"
grep -Fq "/privatepages/closed-beta-signup-guard.js" "$INDEX"
grep -Fq "/privatepages/profile-anki-preview-mount.js" "$INDEX"
grep -Fq "</body>" "$INDEX"
grep -Fq "</html>" "$INDEX"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY" "$VIEWMODEL"

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL" "$MOUNT" "$PANEL"; then
  echo "FAIL: mount/panel must not reference disabled save button view model"
  exit 1
fi

grep -Fq "PASS exact script delta old+1 with no removals" "$OUT_DIR/source-check."*.txt
grep -Fq "R14N_R2_VM200_RESTORE_INDEX_TAIL_LOAD_DISABLED_SAVE_VIEW_MODEL_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14N-R2 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14n-r2 restore index tail load disabled save view model smoke"
