#!/usr/bin/env bash
set -euo pipefail

RENDER_SPEC="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-render-spec.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-r14p-r2-disabled-save-button-render-spec-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14p-r2-disabled-save-button-render-spec-source-only"

test -f "$RENDER_SPEC"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY" "$RENDER_SPEC"
grep -Fq "createDisabledSaveButtonRenderSpec" "$RENDER_SPEC"
grep -Fq "createDisabledSaveButtonRenderSpecText" "$RENDER_SPEC"
grep -Fq "renderSpecOnly: true" "$RENDER_SPEC"
grep -Fq "domElementCreated: false" "$RENDER_SPEC"
grep -Fq "elementInserted: false" "$RENDER_SPEC"
grep -Fq "buttonElementCreated: false" "$RENDER_SPEC"
grep -Fq "buttonVisibleNow: false" "$RENDER_SPEC"
grep -Fq "buttonDisabledNow: true" "$RENDER_SPEC"
grep -Fq "actionBoundToUi: false" "$RENDER_SPEC"
grep -Fq "clickHandlerAdded: false" "$RENDER_SPEC"
grep -Fq "writeExecutorCalled: false" "$RENDER_SPEC"
grep -Fq "canWriteNow: false" "$RENDER_SPEC"
grep -Fq "writesEnabledNow: false" "$RENDER_SPEC"
grep -Fq "requiresLaterDeployStage: true" "$RENDER_SPEC"
grep -Fq "requiresLaterUiMountStage: true" "$RENDER_SPEC"

grep -Fq "Disabled Save Button Render Spec Source-Only" "$DOC"
grep -Fq "R14P-R1 timed out" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

if grep -Fq "/privatepages/local-backup-current-file-disabled-save-button-render-spec.js" "$INDEX"; then
  echo "FAIL: render spec must not be loaded by index.html"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC" "$MOUNT" "$PANEL"; then
  echo "FAIL: render spec must not be referenced by live mount/panel"
  exit 1
fi

if grep -Eq "document\.createElement|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|executeCurrentBackupWrite\(" "$RENDER_SPEC"; then
  echo "FAIL: render spec must not create DOM, attach clicks, or call write executor"
  exit 1
fi

if grep -Eq "createWritable\(|\.write\(|\.close\(|showSaveFilePicker|showDirectoryPicker" "$RENDER_SPEC"; then
  echo "FAIL: render spec must not contain write picker/stream code"
  exit 1
fi

if grep -Eq "fetch\(|XMLHttpRequest|sendBeacon|localStorage\.setItem|sessionStorage\.setItem|indexedDB" "$RENDER_SPEC"; then
  echo "FAIL: render spec contains forbidden network/storage API"
  exit 1
fi

node --check "$RENDER_SPEC"

node - <<'NODE'
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-render-spec.js");
const spec = api.createDisabledSaveButtonRenderSpec({}, {});

if (api.MARKER !== "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY") throw new Error("api marker mismatch");
if (spec.marker !== api.MARKER) throw new Error("spec marker mismatch");
if (spec.sourceOnly !== true) throw new Error("sourceOnly should be true");
if (spec.deployed !== false) throw new Error("deployed should be false");
if (spec.uiLoaded !== false) throw new Error("uiLoaded should be false");
if (spec.renderSpecOnly !== true) throw new Error("renderSpecOnly should be true");
if (spec.domElementCreated !== false) throw new Error("domElementCreated should be false");
if (spec.elementInserted !== false) throw new Error("elementInserted should be false");
if (spec.buttonElementCreated !== false) throw new Error("buttonElementCreated should be false");
if (spec.buttonVisibleNow !== false) throw new Error("buttonVisibleNow should be false");
if (spec.buttonDisabledNow !== true) throw new Error("buttonDisabledNow should be true");
if (spec.actionBoundToUi !== false) throw new Error("actionBoundToUi should be false");
if (spec.clickHandlerAdded !== false) throw new Error("clickHandlerAdded should be false");
if (spec.writeExecutorCalled !== false) throw new Error("writeExecutorCalled should be false");
if (spec.canWriteNow !== false) throw new Error("canWriteNow should be false");
if (spec.writesEnabledNow !== false) throw new Error("writesEnabledNow should be false");
if (spec.requiresLaterDeployStage !== true) throw new Error("requiresLaterDeployStage should be true");
if (spec.requiresLaterUiMountStage !== true) throw new Error("requiresLaterUiMountStage should be true");
if (spec.tagName !== "button") throw new Error("tagName should be button");
if (spec.disabled !== true) throw new Error("disabled should be true");
if (Object.keys(spec.eventHandlers).length !== 0) throw new Error("eventHandlers must be empty");

const text = api.createDisabledSaveButtonRenderSpecText(spec);
if (!text.includes("Save current backup render spec")) throw new Error("missing title");
if (!text.includes("DOM element created: false")) throw new Error("missing DOM false");
if (!text.includes("No file is saved, replaced, merged, restored, or overwritten.")) throw new Error("missing safety text");

console.log("PASS node R14P-R2 render spec source-only behavior smoke");
NODE

echo "PASS stage-17k-r14p-r2 disabled save button render spec source-only smoke"
