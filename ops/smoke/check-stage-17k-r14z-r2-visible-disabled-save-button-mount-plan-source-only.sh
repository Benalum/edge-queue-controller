#!/usr/bin/env bash
set -euo pipefail

MOUNT_PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-mount-plan.js"
HTML_RENDERER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-html-preview-renderer.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-r14z-r2-visible-disabled-save-button-mount-plan-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14z-r2-visible-disabled-save-button-mount-plan-source-only"

test -f "$MOUNT_PLAN"
test -f "$HTML_RENDERER"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY" "$MOUNT_PLAN"
grep -Fq "createVisibleDisabledSaveButtonMountPlan" "$MOUNT_PLAN"
grep -Fq "createVisibleDisabledSaveButtonMountPlanText" "$MOUNT_PLAN"
grep -Fq "mountPlanOnly: true" "$MOUNT_PLAN"
grep -Fq "domElementCreated: false" "$MOUNT_PLAN"
grep -Fq "elementInserted: false" "$MOUNT_PLAN"
grep -Fq "buttonElementCreated: false" "$MOUNT_PLAN"
grep -Fq "buttonVisibleNow: false" "$MOUNT_PLAN"
grep -Fq "buttonDisabledNow: true" "$MOUNT_PLAN"
grep -Fq "actionBoundToUi: false" "$MOUNT_PLAN"
grep -Fq "clickHandlerAdded: false" "$MOUNT_PLAN"
grep -Fq "writeExecutorCalled: false" "$MOUNT_PLAN"
grep -Fq "canWriteNow: false" "$MOUNT_PLAN"
grep -Fq "writesEnabledNow: false" "$MOUNT_PLAN"

grep -Fq "Visible Disabled Save Button Mount Plan Source-Only" "$DOC"
grep -Fq "Recovered and completed" "$DOC"
grep -Fq "No DOM creation" "$DOC"
grep -Fq "No button insertion" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

if grep -Fq "/privatepages/local-backup-current-file-disabled-save-button-mount-plan.js" "$INDEX"; then
  echo "FAIL: mount plan must not be loaded by index.html"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN" "$MOUNT" "$PANEL"; then
  echo "FAIL: mount plan must not be referenced by live mount/panel"
  exit 1
fi

if grep -Eq "document\.createElement|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|executeCurrentBackupWrite\(" "$MOUNT_PLAN"; then
  echo "FAIL: mount plan must not create DOM, attach clicks, or call write executor"
  exit 1
fi

if grep -Eq "createWritable\(|\.write\(|\.close\(|showSaveFilePicker|showDirectoryPicker" "$MOUNT_PLAN"; then
  echo "FAIL: mount plan must not contain write picker/stream code"
  exit 1
fi

node --check "$MOUNT_PLAN"

node - <<'NODE'
const htmlApi = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-html-preview-renderer.js");
globalThis.APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER = htmlApi;

const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-mount-plan.js");
const plan = api.createVisibleDisabledSaveButtonMountPlan({}, {});
const text = api.createVisibleDisabledSaveButtonMountPlanText(plan);

if (api.MARKER !== "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY") throw new Error("api marker mismatch");
if (plan.marker !== api.MARKER) throw new Error("plan marker mismatch");
if (plan.sourceOnly !== true) throw new Error("sourceOnly should be true");
if (plan.deployed !== false) throw new Error("deployed should be false");
if (plan.uiLoaded !== false) throw new Error("uiLoaded should be false");
if (plan.mountPlanOnly !== true) throw new Error("mountPlanOnly should be true");
if (plan.domElementCreated !== false) throw new Error("domElementCreated should be false");
if (plan.elementInserted !== false) throw new Error("elementInserted should be false");
if (plan.buttonElementCreated !== false) throw new Error("buttonElementCreated should be false");
if (plan.buttonVisibleNow !== false) throw new Error("buttonVisibleNow should be false");
if (plan.buttonDisabledNow !== true) throw new Error("buttonDisabledNow should be true");
if (plan.actionBoundToUi !== false) throw new Error("actionBoundToUi should be false");
if (plan.clickHandlerAdded !== false) throw new Error("clickHandlerAdded should be false");
if (plan.writeExecutorCalled !== false) throw new Error("writeExecutorCalled should be false");
if (plan.canWriteNow !== false) throw new Error("canWriteNow should be false");
if (plan.writesEnabledNow !== false) throw new Error("writesEnabledNow should be false");
if (plan.futureButtonText !== "Save current backup") throw new Error("future button text mismatch");
if (plan.futureButtonDisabled !== true) throw new Error("future button disabled mismatch");
if (!text.includes("Visible disabled Save current backup mount plan")) throw new Error("text missing title");
if (!text.includes("DOM element created: false")) throw new Error("text missing DOM false");
if (!text.includes("No file is saved, replaced, merged, restored, or overwritten.")) throw new Error("text missing safety");

console.log("PASS node R14Z-R2 visible disabled save button mount plan source-only behavior smoke");
NODE

echo "PASS stage-17k-r14z-r2 visible disabled save button mount plan source-only smoke"
