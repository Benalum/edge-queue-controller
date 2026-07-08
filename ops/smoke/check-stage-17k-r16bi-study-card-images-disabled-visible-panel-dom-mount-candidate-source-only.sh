#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16bi-study-card-images-disabled-visible-panel-dom-mount-candidate-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
ASSET="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-dom-mount-candidate.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI_SOURCE_ONLY"

printf '%s\n' "=== $STAGE smoke ==="
[ -f "$INDEX" ] || { printf '%s\n' "FAIL: missing $INDEX"; exit 1; }
[ -f "$ASSET" ] || { printf '%s\n' "FAIL: missing $ASSET"; exit 1; }
grep -q "$MARKER" "$ASSET" || { printf '%s\n' "FAIL: marker missing from $ASSET"; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel-dom-mount-candidate.js' "$INDEX"; then
  printf '%s\n' "FAIL: R16BI asset must not be loaded by index in source-only stage"
  exit 1
fi
if grep -Eq '\b(indexedDB|fetch|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|showOpenFilePicker|createObjectURL|FileReader|addEventListener|appendChild|replaceChildren|insertAdjacentHTML)\b' "$ASSET"; then
  printf '%s\n' "FAIL: forbidden side-effect API present in source-only asset"
  exit 1
fi
node <<'NODE'
const fs = require('fs');
const vm = require('vm');
const src = fs.readFileSync('frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-dom-mount-candidate.js', 'utf8');
const sandbox = { window: {} };
vm.createContext(sandbox);
vm.runInContext(src, sandbox, { filename: 'study-card-images-disabled-visible-panel-dom-mount-candidate.js' });
const api = sandbox.window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI;
function assert(condition, message) {
  if (!condition) throw new Error(message);
}
assert(api, 'api missing');
assert(api.marker === 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_MOUNT_CANDIDATE_R16BI_SOURCE_ONLY', 'marker mismatch');
assert(api.sourceOnly === true, 'sourceOnly must be true');
assert(api.disabled === true, 'disabled must be true');
assert(api.status.executed === false, 'must not execute');
assert(api.status.mounted === false, 'must not mount');
assert(api.status.controlsEnabled === false, 'controls must stay disabled');
assert(api.status.filePickerOpened === false, 'file picker must not open');
assert(api.status.imagePreviewRendered === false, 'preview must not render');
assert(api.status.indexedDbWrite === false, 'IndexedDB write must not happen');
assert(api.status.backendUpload === false, 'backend upload must not happen');
assert(api.status.googleDriveSync === false, 'Drive sync must not happen');
assert(api.status.ankiMutation === false, 'Anki mutation must not happen');
const candidate = api.createDomMountCandidate({ slotName: 'study-card-editor-image-panel-slot' });
assert(api.assertDomMountCandidate(candidate) === true, 'candidate assertion must pass');
assert(candidate.autoExecute === false, 'candidate must not auto-execute');
assert(candidate.sideEffects.domNodeCreation === false, 'candidate must not create DOM nodes');
assert(candidate.sideEffects.domInsertion === false, 'candidate must not insert DOM nodes');
assert(candidate.sideEffects.domReplacement === false, 'candidate must not replace DOM nodes');
assert(candidate.sideEffects.eventBinding === false, 'candidate must not bind events');
assert(candidate.sideEffects.filePicker === false, 'candidate must not open file picker');
assert(candidate.sideEffects.networkWrite === false, 'candidate must not write network');
console.log('PASS node R16BI disabled visible panel DOM mount candidate source-only behavior smoke');
NODE
sha256sum "$ASSET" "$INDEX"
printf '%s\n' "PASS $STAGE smoke"
