#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ah-study-card-images-disabled-panel-source-bundle-manifest-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-source-bundle-manifest.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_SOURCE_BUNDLE_MANIFEST_R16AH_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"
[ -f "$ASSET" ] || { echo "FAIL: missing asset $ASSET" >&2; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing index $INDEX" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: missing marker" >&2; exit 1; }
! grep -Fq 'study-card-images-disabled-panel-source-bundle-manifest.js' "$INDEX" || { echo "FAIL: index loads R16AH asset" >&2; exit 1; }
! grep -Eq "appendChild|insertAdjacentElement|addEventListener\([^)]*click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(" "$ASSET" || { echo "FAIL: forbidden source API present" >&2; exit 1; }
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-source-bundle-manifest.js');
function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}
assert(api.MARKER === 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_SOURCE_BUNDLE_MANIFEST_R16AH_SOURCE_ONLY', 'marker mismatch');
const assets = api.getBundleAssets();
const files = api.getBundleFiles();
const globals = api.getBundleGlobals();
assert(Array.isArray(assets) && assets.length === 10, 'expected 10 bundle assets');
assert(Array.isArray(files) && files.length === 10, 'expected 10 bundle files');
assert(Array.isArray(globals) && globals.length === 10, 'expected 10 bundle globals');
assert(files.includes('study-card-images-disabled-panel-load-order-contract.js'), 'missing load-order file');
assert(globals.includes('APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD'), 'missing activation guard global');
assert(api.validateSourceBundle(files).ok === true, 'expected valid bundle');
assert(api.validateSourceBundle([]).ok === false, 'empty bundle should fail');
const plan = api.getDeploymentPlan();
assert(plan.sourceOnlyNow === true, 'sourceOnlyNow must be true');
assert(plan.deployNow === false, 'deployNow must be false');
assert(plan.loadByIndexNow === false, 'loadByIndexNow must be false');
assert(plan.mountNow === false, 'mountNow must be false');
assert(plan.enableControlsNow === false, 'enableControlsNow must be false');
const safety = api.getSafetyFlags();
for (const key of ['uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow']) {
  assert(safety[key] === false, `${key} must be false`);
}
assert(safety.sourceOnly === true, 'sourceOnly must be true');
console.log('PASS node R16AH disabled panel source-bundle manifest source-only behavior smoke');
NODE
printf 'PASS %s smoke\n' "$STAGE"
