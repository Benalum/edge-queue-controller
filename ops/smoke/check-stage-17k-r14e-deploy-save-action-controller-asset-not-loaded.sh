#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14e-deploy-save-action-controller-asset-not-loaded.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14e-deploy-save-action-controller-asset-not-loaded"
CONTROLLER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-action-controller.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Deploy Save Action Controller Asset, Not Loaded" "$DOC"
grep -Fq "Asset-only deploy" "$DOC"
grep -Fq "No index load" "$DOC"
grep -Fq "No Profile integration" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY" "$CONTROLLER"
grep -Fq "createSaveCurrentBackupActionState" "$CONTROLLER"
grep -Fq "createDisabledActionViewModel" "$CONTROLLER"
grep -Fq "executorCallAllowedNow: false" "$CONTROLLER"
grep -Fq "writesEnabledNow: false" "$CONTROLLER"
grep -Fq "canWriteNow: false" "$CONTROLLER"

if grep -Fq "/privatepages/local-backup-current-file-save-action-controller.js" "$INDEX"; then
  echo "FAIL: action controller loaded by index"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER" "$MOUNT" "$PANEL"; then
  echo "FAIL: action controller referenced by live Profile source"
  exit 1
fi

grep -Fq "R14E_VM200_SAVE_ACTION_CONTROLLER_ASSET_NOT_LOADED_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14E asset smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14e deploy save action controller asset not loaded smoke"
