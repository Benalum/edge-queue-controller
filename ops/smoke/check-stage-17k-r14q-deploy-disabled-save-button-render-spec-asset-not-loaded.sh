#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14q-deploy-disabled-save-button-render-spec-asset-not-loaded.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14q-deploy-disabled-save-button-render-spec-asset-not-loaded"
RENDER_SPEC="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-render-spec.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$RENDER_SPEC"

grep -Fq "Deploy Disabled Save Button Render Spec Asset Not Loaded" "$DOC"
grep -Fq "No index load" "$DOC"
grep -Fq "No live UI change" "$DOC"
grep -Fq "No DOM creation" "$DOC"
grep -Fq "No button insertion" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No file write" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY" "$RENDER_SPEC"
grep -Fq "createDisabledSaveButtonRenderSpec" "$RENDER_SPEC"

if grep -Fq "/privatepages/local-backup-current-file-disabled-save-button-render-spec.js" "$INDEX"; then
  echo "FAIL: index must not load disabled save button render spec"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC" "$MOUNT" "$PANEL"; then
  echo "FAIL: mount/panel must not reference disabled save button render spec"
  exit 1
fi

grep -Fq "R14Q_VM200_DISABLED_SAVE_BUTTON_RENDER_SPEC_ASSET_NOT_LOADED_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R14Q smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-r14q deploy disabled save button render spec asset not loaded smoke"
