#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16q-load-study-card-images-disabled-html-preview-renderer-no-ui-no-binding"
ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$ROOT/index.html"
ASSET="$ROOT/privatepages/study-card-images-disabled-html-preview-renderer.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY"
CACHE="stage17k-r16q-load-disabled-html-preview-renderer-no-ui-no-binding-20260708"
SPEC_CACHE="stage17k-r16l-load-disabled-image-render-spec-no-ui-no-binding-20260708"

echo "=== $STAGE smoke ==="
[ -f "$INDEX" ] || { echo 'FAIL: index missing' >&2; exit 1; }
[ -f "$ASSET" ] || { echo 'FAIL: disabled HTML preview renderer asset missing' >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo 'FAIL: marker missing from disabled HTML preview renderer asset' >&2; exit 1; }
grep -Fq "/privatepages/study-card-images-disabled-render-spec.js?v=$SPEC_CACHE" "$INDEX" || { echo 'FAIL: R16L disabled render spec script missing from index' >&2; exit 1; }
grep -Fq "/privatepages/study-card-images-disabled-html-preview-renderer.js?v=$CACHE" "$INDEX" || { echo 'FAIL: R16Q disabled HTML preview renderer script missing from index' >&2; exit 1; }
count="$(grep -F "study-card-images-disabled-html-preview-renderer.js" "$INDEX" | wc -l | tr -d ' ')"
[ "$count" = "1" ] || { echo "FAIL: expected exactly one disabled HTML preview renderer script, got $count" >&2; exit 1; }
if grep -E 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET" >/dev/null; then
  echo 'FAIL: disabled HTML preview renderer contains forbidden DOM/write/network APIs' >&2
  exit 1
fi
node <<'NODE'
global.window = global;
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-html-preview-renderer.js');
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY') {
  throw new Error('missing R16N renderer marker');
}
if (!global.APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER) {
  throw new Error('missing R16N renderer global');
}
const flags = api.getSafetyFlags();
const bad = [
  'uiMountedNow',
  'buttonRenderedNow',
  'controlsEnabledNow',
  'filePickerOpenedNow',
  'imagePreviewRenderedNow',
  'clickBoundNow',
  'blobStoredNow',
  'indexedDbWriteNow',
  'backupPayloadWriteNow',
  'backendUploadAllowed',
  'serverSyncAllowed',
  'googleDriveSyncAllowedNow',
  'ankiMutationAllowed',
  'originalFileMutationAllowed',
  'mediaExtractionNow'
].filter((key) => flags[key] !== false);
if (flags.sourceOnly !== true || flags.htmlOnly !== true || bad.length) {
  throw new Error('unsafe R16Q loaded renderer flags: ' + bad.join(','));
}
console.log('PASS node R16Q disabled HTML preview renderer loaded/no-binding behavior smoke');
NODE
echo "PASS $STAGE smoke"
