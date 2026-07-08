#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16ba-study-card-images-disabled-visible-panel-safe-mount-executor-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
ASSET="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-safe-mount-executor.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"
[[ -f "$INDEX" ]] || { echo "FAIL: index missing" >&2; exit 1; }
[[ -f "$ASSET" ]] || { echo "FAIL: asset missing" >&2; exit 1; }
grep -q "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel-safe-mount-executor.js' "$INDEX"; then
  echo "FAIL: R16BA safe mount executor must not be loaded by index in source-only stage" >&2
  exit 1
fi
if grep -nE '(^|[^A-Za-z])(fetch|XMLHttpRequest|WebSocket|navigator\.sendBeacon|indexedDB|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|chooseFileSystemEntries|appendChild|insertBefore|replaceChildren|innerHTML|addEventListener|querySelector|createElement)([^A-Za-z]|$)' "$ASSET"; then
  echo "FAIL: forbidden source API present" >&2
  exit 1
fi
node <<'NODE'
global.window = {};
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-safe-mount-executor.js");
const api = window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA;
function assert(condition, message) {
  if (!condition) throw new Error(message);
}
assert(api, "api missing");
assert(api.marker === "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SAFE_MOUNT_EXECUTOR_R16BA_SOURCE_ONLY", "marker mismatch");
assert(api.sourceOnly === true, "sourceOnly must be true");
assert(api.disabled === true, "disabled must be true");
assert(api.status.executed === false, "executor must not execute");
assert(api.status.mounted === false, "mounted must stay false");
assert(api.status.controlsEnabled === false, "controls must stay disabled");
assert(api.status.filePickerOpened === false, "file picker must stay closed");
assert(api.status.imagePreviewRendered === false, "preview must stay hidden");
assert(api.status.indexedDbWrite === false, "IndexedDB writes must stay blocked");
assert(api.status.backendUpload === false, "backend upload must stay blocked");
assert(api.status.googleDriveSync === false, "Drive sync must stay blocked");
assert(api.status.ankiMutation === false, "Anki mutation must stay blocked");
const plan = api.createSafeMountExecutionPlan({ slotName: "study-card-editor-image-panel-slot" });
assert(api.assertSafeMountExecutionPlan(plan), "plan assertion failed");
assert(plan.execute === false, "plan execute must stay false");
assert(plan.blockedEffects.domMount === true, "DOM mount must remain blocked");
assert(plan.blockedEffects.eventBind === true, "event bind must remain blocked");
assert(plan.blockedEffects.filePicker === true, "file picker must remain blocked");
assert(plan.blockedEffects.previewPaint === true, "preview paint must remain blocked");
assert(plan.blockedEffects.clientWrite === true, "client write must remain blocked");
assert(plan.blockedEffects.backendUpload === true, "backend upload must remain blocked");
assert(plan.blockedEffects.googleDriveSync === true, "Drive sync must remain blocked");
assert(plan.blockedEffects.ankiMutation === true, "Anki mutation must remain blocked");
const desc = api.describeSafeMountExecutionPlan(plan);
assert(desc.execute === false, "description execute must be false");
assert(desc.mounted === false, "description mounted must be false");
assert(desc.controlsEnabled === false, "description controls must be disabled");
assert(desc.writesAllowed === false, "description writes must be blocked");
console.log("PASS node R16BA disabled visible panel safe mount executor source-only behavior smoke");
NODE
printf 'PASS %s smoke\n' "$STAGE"
