#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16n-study-card-images-disabled-html-preview-renderer-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
PRIVATE="$FRONTEND/privatepages"
INDEX="$FRONTEND/index.html"
OUT="$PRIVATE/study-card-images-disabled-html-preview-renderer.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"

test -f "$OUT"
test -f "$INDEX"
grep -Fq "$MARKER" "$OUT"
! grep -Fq 'study-card-images-disabled-html-preview-renderer.js' "$INDEX"
grep -Fq '/privatepages/study-card-images-disabled-render-spec.js?v=stage17k-r16l-load-disabled-image-render-spec-no-ui-no-binding-20260708' "$INDEX"

if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$OUT"; then
  echo "FAIL: forbidden DOM/write/upload/storage API found in source-only renderer" >&2
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
const html = api.renderDisabledCardImagesPreviewHtml();
if (!html.includes('Question image') || !html.includes('Answer image')) {
  throw new Error('missing question/answer disabled preview labels');
}
if (!html.includes('disabled') || !html.includes('aria-disabled="true"')) {
  throw new Error('disabled controls are not represented as disabled');
}
const flags = api.getSafetyFlags();
const badTrue = [
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
if (flags.sourceOnly !== true || flags.htmlOnly !== true || badTrue.length) {
  throw new Error('unsafe R16N safety flags: ' + badTrue.join(','));
}
console.log('PASS node R16N disabled html preview renderer source-only behavior smoke');
NODE

printf 'PASS %s smoke\n' "$STAGE"
