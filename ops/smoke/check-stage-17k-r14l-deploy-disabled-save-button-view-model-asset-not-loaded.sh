#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14l-deploy-disabled-save-button-view-model-asset-not-loaded.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14l-deploy-disabled-save-button-view-model-asset-not-loaded"
VIEWMODEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-view-model.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$VIEWMODEL"

grep -Fq "Deploy Disabled Save Button View Model Asset Not Loaded" "$DOC"
grep -Fq "No index load" "$DOC"
grep -Fq "No live UI change" "$DOC"
grep -Fq "No button" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No file write" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY" "$VIEWMODEL"
grep -Fq "createDisabledSaveButtonViewModel" "$VIEWMODEL"

if grep -Fq "/privatepages/local-backup-current-file-disabled-save-button-view-model.js" "$INDEX"; then
  echo "FAIL: index must not load disabled save button view model"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL" "$MOUNT" "$PANEL"; then
  echo "FAIL: mount/panel must not reference disabled save button view model"
  exit 1
fi

grep -Fq "R14L_VM200_DISABLED_SAVE_BUTTON_VIEW_MODEL_ASSET_NOT_LOADED_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14L smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14l deploy disabled save button view model asset not loaded smoke"
