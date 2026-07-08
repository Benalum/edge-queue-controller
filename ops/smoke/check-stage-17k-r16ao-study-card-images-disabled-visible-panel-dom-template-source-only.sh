#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16ao-study-card-images-disabled-visible-panel-dom-template-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-dom-template.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"
[ -f "$ASSET" ] || { echo "FAIL: missing $ASSET"; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing $INDEX"; exit 1; }
grep -q "$MARKER" "$ASSET" || { echo 'FAIL: R16AO marker missing'; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel-dom-template.js' "$INDEX"; then
  echo 'FAIL: R16AO asset must not be loaded by index in source-only stage'
  exit 1
fi
if grep -Eq 'document\.createElement|appendChild|insertAdjacentHTML|innerHTML\s*=|addEventListener|indexedDB|localStorage|sessionStorage|fetch\s*\(|XMLHttpRequest|navigator\.storage|showOpenFilePicker|FileReader|URL\.createObjectURL|APC_GOOGLE_SYNC|APC_ANKI|/api/study|/api/anki' "$ASSET"; then
  echo 'FAIL: forbidden source API present in R16AO asset'
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-dom-template.js');
function assert(condition, message) {
  if (!condition) throw new Error(message);
}
assert(api.marker === 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_DOM_TEMPLATE_R16AO_SOURCE_ONLY', 'marker mismatch');
assert(api.sourceOnly === true, 'sourceOnly must be true');
assert(api.enabled === false, 'enabled must be false');
assert(api.mounted === false, 'mounted must be false');
assert(api.sideEffects.autoMount === false, 'autoMount must be false');
assert(api.sideEffects.createElementOnLoad === false, 'createElementOnLoad must be false');
assert(api.sideEffects.bindEvents === false, 'bindEvents must be false');
assert(api.sideEffects.openFilePicker === false, 'openFilePicker must be false');
assert(api.sideEffects.paintPreview === false, 'paintPreview must be false');
assert(api.sideEffects.writeIndexedDb === false, 'writeIndexedDb must be false');
assert(api.sideEffects.writeBackupPayload === false, 'writeBackupPayload must be false');
assert(api.sideEffects.uploadBackend === false, 'uploadBackend must be false');
assert(api.sideEffects.syncGoogleDrive === false, 'syncGoogleDrive must be false');
assert(api.sideEffects.mutateAnki === false, 'mutateAnki must be false');
const model = api.disabledPanelTemplateModel();
assert(model.controls.length === 2, 'must define question and answer controls');
assert(model.controls.every((control) => control.disabled === true && control.bind === false), 'all controls disabled/unbound');
const html = api.renderDisabledVisiblePanelHtml(model);
assert(api.assertDisabledVisiblePanelHtml(html), 'html assertion failed');
assert(!html.includes('type="file"'), 'html must not include file input yet');
assert(html.includes('data-apc-image-control="question"'), 'question disabled control missing');
assert(html.includes('data-apc-image-control="answer"'), 'answer disabled control missing');
assert(html.includes('disabled aria-disabled="true"'), 'disabled aria marker missing');
console.log('PASS node R16AO disabled visible panel DOM template source-only behavior smoke');
NODE
printf 'PASS %s smoke\n' "$STAGE"
