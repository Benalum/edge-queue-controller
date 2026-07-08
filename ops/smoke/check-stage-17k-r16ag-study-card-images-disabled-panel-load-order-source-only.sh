#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ag-study-card-images-disabled-panel-load-order-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-load-order-contract.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_LOAD_ORDER_CONTRACT_R16AG_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[ -f "$ASSET" ] || { echo "FAIL: missing asset" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
! grep -Fq "study-card-images-disabled-panel-load-order-contract.js" "$INDEX" || { echo "FAIL: asset is loaded by index" >&2; exit 1; }
! grep -Eq 'appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET" || { echo "FAIL: forbidden source API present" >&2; exit 1; }
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-load-order-contract.js');
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_LOAD_ORDER_CONTRACT_R16AG_SOURCE_ONLY') throw new Error('marker mismatch');
const files = api.getExpectedFiles();
for (const name of [
  'study-card-images-local-only-contract.js',
  'study-card-images-disabled-mount-plan.js',
  'study-card-images-disabled-panel-activation-guard.js'
]) {
  if (!files.includes(name)) throw new Error('missing expected file ' + name);
}
const validation = api.validateLoadOrder(files);
if (!validation.ok) throw new Error('valid load order rejected: ' + validation.errors.join(','));
const reversed = files.slice().reverse();
if (api.validateLoadOrder(reversed).ok) throw new Error('bad load order accepted');
const safety = api.getSafetyFlags();
for (const key of ['sourceOnly']) if (safety[key] !== true) throw new Error('expected true ' + key);
for (const key of ['uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow']) {
  if (safety[key] !== false) throw new Error('expected false ' + key);
}
console.log('PASS node R16AG disabled panel load-order source-only behavior smoke');
NODE
echo "PASS ${STAGE} smoke"
