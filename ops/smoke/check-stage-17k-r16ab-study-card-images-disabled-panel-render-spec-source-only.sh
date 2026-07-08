#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ab-study-card-images-disabled-panel-render-spec-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
SRC="${FRONTEND}/privatepages/study-card-images-disabled-panel-render-spec.js"
INDEX="${FRONTEND}/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC_R16AB_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[[ -f "$SRC" ]] || { echo "FAIL: source missing" >&2; exit 1; }
[[ -f "$INDEX" ]] || { echo "FAIL: index missing" >&2; exit 1; }
grep -Fq "$MARKER" "$SRC" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -Fq "study-card-images-disabled-panel-render-spec.js" "$INDEX"; then
  echo "FAIL: panel render spec must not be loaded by index in R16AB" >&2
  exit 1
fi
if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$SRC"; then
  echo "FAIL: forbidden DOM/write/network/storage API found in R16AB source" >&2
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-render-spec.js');
const expected = 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RENDER_SPEC_R16AB_SOURCE_ONLY';
if (!api || api.MARKER !== expected) throw new Error('marker mismatch');
const spec = api.createDisabledPanelRenderSpec({ title: 'Card Images <safe>' });
const valid = api.validateRenderSpec(spec);
if (!valid.ok) throw new Error('render spec invalid: ' + valid.errors.join(','));
const html = api.renderDisabledPanelHtml(spec);
if (!html.includes('data-apc-study-card-images-disabled-panel')) throw new Error('missing disabled panel data attr');
if (!html.includes('&lt;safe&gt;')) throw new Error('HTML escaping failed');
if (html.includes('<script')) throw new Error('unexpected script in html');
const safety = api.getSafetyFlags();
const mustBeFalse = [
  'loadedByIndexNow','uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow',
  'imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed',
  'serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow'
];
if (safety.sourceOnly !== true) throw new Error('sourceOnly flag not true');
for (const key of mustBeFalse) {
  if (safety[key] !== false) throw new Error(`${key} must be false`);
}
console.log('PASS node R16AB disabled panel render spec source-only behavior smoke');
NODE
echo "PASS ${STAGE} smoke"
