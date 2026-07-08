#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16aw-study-card-images-disabled-visible-panel-mount-controller-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
ASSET="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-mount-controller.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"
[[ -f "$INDEX" ]] || { echo "FAIL: index missing" >&2; exit 1; }
[[ -f "$ASSET" ]] || { echo "FAIL: asset missing" >&2; exit 1; }
grep -q "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel-mount-controller.js' "$INDEX"; then
  echo "FAIL: R16AW mount controller must not be loaded by index in source-only stage" >&2
  exit 1
fi
if grep -nE '(^|[^A-Za-z])(fetch|XMLHttpRequest|WebSocket|navigator\.sendBeacon|indexedDB|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|chooseFileSystemEntries|appendChild|insertBefore|replaceChildren|innerHTML|addEventListener|querySelector|createElement)([^A-Za-z]|$)' "$ASSET"; then
  echo "FAIL: forbidden source API present" >&2
  exit 1
fi
node <<'NODE'
global.window = {};
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-controller.js");
const api = window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW;
function assert(condition, message) {
  if (!condition) throw new Error(message);
}
assert(api, "api missing");
assert(api.marker === "APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_CONTROLLER_R16AW_SOURCE_ONLY", "marker mismatch");
assert(api.sourceOnly === true, "sourceOnly must be true");
assert(api.disabled === true, "disabled must be true");
assert(api.status.mounted === false, "mounted must stay false");
assert(api.status.controlsEnabled === false, "controls must stay disabled");
assert(api.status.pickerOpened === false, "picker must stay closed");
assert(api.status.previewRendered === false, "preview must stay hidden");
assert(api.status.clientWrite === false, "client writes must stay blocked");
assert(api.status.backendUpload === false, "backend upload must stay blocked");
assert(api.status.driveSync === false, "drive sync must stay blocked");
assert(api.status.ankiMutation === false, "Anki mutation must stay blocked");
const controller = api.createDisabledMountController({ slotName: "study-card-editor-image-panel-slot" });
assert(api.assertDisabledMountController(controller), "controller assertion failed");
const desc = api.describeDisabledMountController(controller);
assert(desc.mounted === false, "description mounted must be false");
assert(desc.controlsEnabled === false, "description controls must be disabled");
assert(desc.writesAllowed === false, "description writes must be blocked");
console.log("PASS node R16AW disabled visible panel mount controller source-only behavior smoke");
NODE
printf 'PASS %s smoke\n' "$STAGE"
