#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14g-load-save-action-controller-no-ui-no-write.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14g-load-save-action-controller-no-ui-no-write"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
CONTROLLER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-action-controller.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Load Save Action Controller, No UI, No Write" "$DOC"
grep -Fq "No visible UI change" "$DOC"
grep -Fq "No Save button" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "stage17k-r14g-load-save-action-controller-no-ui-no-write-20260705" "$INDEX"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY" "$CONTROLLER"
grep -Fq "executorCallAllowedNow: false" "$CONTROLLER"
grep -Fq "writesEnabledNow: false" "$CONTROLLER"
grep -Fq "canWriteNow: false" "$CONTROLLER"

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER" "$MOUNT" "$PANEL"; then
  echo "FAIL: controller referenced by mount/panel"
  exit 1
fi

grep -Fq "R14G_VM200_LOAD_SAVE_ACTION_CONTROLLER_NO_UI_NO_WRITE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14G smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14g load save action controller no ui no write smoke"
