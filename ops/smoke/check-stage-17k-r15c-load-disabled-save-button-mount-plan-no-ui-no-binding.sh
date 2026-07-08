#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r15c-load-disabled-save-button-mount-plan-no-ui-no-binding.md"
OUT_DIR="docs/smoke/generated/stage-17k-r15c-load-disabled-save-button-mount-plan-no-ui-no-binding"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT_PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-mount-plan.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$MOUNT_PLAN"

grep -Fq "Load Disabled Save Button Mount Plan, No UI/Binding" "$DOC"
grep -Fq "No button" "$DOC"
grep -Fq "No DOM insertion" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "stage17k-r15c-load-disabled-save-button-mount-plan-no-ui-no-binding-20260708" "$INDEX"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY" "$MOUNT_PLAN"

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN" "$MOUNT" "$PANEL"; then
  echo "FAIL: mount/panel must not reference mount plan"
  exit 1
fi

grep -Fq "PASS exact script delta old+1 with no removals" "$OUT_DIR/source-check."*.txt
grep -Fq "R15C_VM200_LOAD_DISABLED_SAVE_BUTTON_MOUNT_PLAN_NO_UI_NO_BINDING_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R15C smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r15c load disabled save button mount plan no ui no binding smoke"
