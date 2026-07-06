#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14n-load-disabled-save-button-view-model-no-ui-no-binding.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14n-load-disabled-save-button-view-model-no-ui-no-binding"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
VIEWMODEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-view-model.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$VIEWMODEL"

grep -Fq "Load Disabled Save Button View Model, No UI/Binding" "$DOC"
grep -Fq "No button" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No file write" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "stage17k-r14n-load-disabled-save-button-view-model-no-ui-no-binding-20260705" "$INDEX"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY" "$VIEWMODEL"
grep -Fq "buttonVisibleNow: false" "$VIEWMODEL"
grep -Fq "buttonDisabledNow: true" "$VIEWMODEL"
grep -Fq "actionBoundToUi: false" "$VIEWMODEL"
grep -Fq "clickHandlerAdded: false" "$VIEWMODEL"
grep -Fq "writeExecutorCalled: false" "$VIEWMODEL"

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL" "$MOUNT" "$PANEL"; then
  echo "FAIL: mount/panel must not reference disabled save button view model"
  exit 1
fi

grep -Fq "R14N_VM200_LOAD_DISABLED_SAVE_BUTTON_VIEW_MODEL_NO_UI_NO_BINDING_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14N smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14n load disabled save button view model no ui no binding smoke"
