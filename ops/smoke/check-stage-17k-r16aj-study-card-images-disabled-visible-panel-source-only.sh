#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16aj-study-card-images-disabled-visible-panel-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"
[ -f "$ASSET" ] || { echo "FAIL: missing $ASSET"; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing $INDEX"; exit 1; }
grep -q "$MARKER" "$ASSET" || { echo 'FAIL: R16AJ marker missing'; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel.js' "$INDEX"; then
  echo 'FAIL: R16AJ asset must not be loaded by index in source-only stage'
  exit 1
fi
if grep -nE '\b(fetch|XMLHttpRequest|indexedDB|localStorage|sessionStorage|navigator\.storage|showOpenFilePicker|createObjectURL|FileReader|FormData)\b' "$ASSET"; then
  echo 'FAIL: forbidden runtime/write/file API present in R16AJ source-only asset'
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel.js');
if (!api || api.marker !== 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_R16AJ_SOURCE_ONLY') throw new Error('bad marker');
if (!api.status || api.status.sourceOnly !== true || api.status.enabled !== false) throw new Error('bad disabled status');
const doc = api.renderDisabledPanelDocument();
if (!api.assertDisabledPanelDocument(doc)) throw new Error('disabled panel document failed assertion');
if (doc.controls.some((control) => control.disabled !== true || control.bind !== false)) throw new Error('control is not disabled/unbound');
if (doc.previewPolicy.renderPreview !== false) throw new Error('preview rendered unexpectedly');
if (doc.persistencePolicy.writeBlob !== false || doc.persistencePolicy.uploadToBackend !== false || doc.persistencePolicy.syncToDrive !== false || doc.persistencePolicy.mutateAnki !== false) throw new Error('persistence guard failed');
console.log('PASS node R16AJ disabled visible panel source-only behavior smoke');
NODE
printf 'PASS %s smoke\n' "$STAGE"
