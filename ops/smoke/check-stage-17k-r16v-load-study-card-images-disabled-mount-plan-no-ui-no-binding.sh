#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16v-load-study-card-images-disabled-mount-plan-no-ui-no-binding"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY"
CACHE_BUST="stage17k-r16v-load-disabled-mount-plan-no-ui-no-binding-20260708"

echo "=== ${STAGE} smoke ==="
[ -f "$INDEX" ] || { echo "FAIL: index missing"; exit 1; }
[ -f "$ASSET" ] || { echo "FAIL: mount plan asset missing"; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing from mount plan asset"; exit 1; }
grep -Fq "study-card-images-disabled-mount-plan.js?v=${CACHE_BUST}" "$INDEX" || { echo "FAIL: index does not load R16V mount plan"; exit 1; }
grep -Fq "study-card-images-disabled-html-preview-renderer.js?v=stage17k-r16q-load-disabled-html-preview-renderer-no-ui-no-binding-20260708" "$INDEX" || { echo "FAIL: R16Q html preview renderer load missing"; exit 1; }
if grep -E 'appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET" >/dev/null; then
  echo "FAIL: forbidden write/dom API found in mount plan source"
  exit 1
fi
node - <<'NODE'
const asset = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js');
const api = asset && (asset.APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN || asset.default || asset);
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY') {
  throw new Error('missing R16S mount plan marker');
}
if (typeof api.getSafetyFlags !== 'function') {
  throw new Error('missing getSafetyFlags');
}
const flags = api.getSafetyFlags();
const badKeys = [
  'mountedNow','uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow',
  'imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow',
  'backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed'
];
for (const key of badKeys) {
  if (Object.prototype.hasOwnProperty.call(flags, key) && flags[key] !== false) {
    throw new Error(`unsafe safety flag ${key}=${flags[key]}`);
  }
}
if (Object.prototype.hasOwnProperty.call(flags, 'sourceOnly') && flags.sourceOnly !== true) {
  throw new Error('sourceOnly safety flag was not true');
}
console.log('PASS node R16V disabled mount plan loaded/no-binding behavior smoke');
NODE
printf 'PASS %s smoke\n' "$STAGE"
