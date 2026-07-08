#!/usr/bin/env bash
set -Eeuo pipefail
STAGE="stage-17k-r16aa-study-card-images-disabled-panel-composition-source-only"
SRC_ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$SRC_ROOT/index.html"
SRC="$SRC_ROOT/privatepages/study-card-images-disabled-panel-composition-plan.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN_R16AA_SOURCE_ONLY"

echo "=== $STAGE smoke ==="
[[ -f "$INDEX" ]] || { echo "FAIL: missing index" >&2; exit 1; }
[[ -f "$SRC" ]] || { echo "FAIL: missing source asset" >&2; exit 1; }
grep -Fq "$MARKER" "$SRC" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -Fq "study-card-images-disabled-panel-composition-plan.js" "$INDEX"; then
  echo "FAIL: composition plan is loaded by index; this stage must remain source-only" >&2
  exit 1
fi
if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$SRC"; then
  echo "FAIL: forbidden DOM/write/API token found in source-only composition plan" >&2
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-composition-plan.js');
const expected = 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN_R16AA_SOURCE_ONLY';
if (!api || api.MARKER !== expected) throw new Error('marker mismatch');
const plan = api.createPanelCompositionPlan({ targetSurface: 'study-card-editor' });
const validation = api.validatePanelCompositionPlan(plan);
if (!validation.ok) throw new Error('validation failed: ' + validation.errors.join(', '));
if (plan.sides.length !== 2) throw new Error('expected question and answer sides');
for (const side of plan.sides) {
  if (side.disabled !== true) throw new Error('side not disabled');
  for (const control of side.controls) {
    if (control.disabled !== true || control.action !== 'none') throw new Error('control unexpectedly enabled');
  }
}
const safety = api.getSafetyFlags();
for (const [key, value] of Object.entries(safety)) {
  if (key === 'sourceOnly') {
    if (value !== true) throw new Error('sourceOnly must be true');
  } else if (value !== false) {
    throw new Error(key + ' must be false');
  }
}
const summary = api.summarizePanelCompositionPlan(plan);
if (!summary.ok || summary.sideCount !== 2 || summary.enabled || summary.mounted || summary.bindingEnabled) {
  throw new Error('bad summary');
}
console.log('PASS node R16AA disabled panel composition source-only behavior smoke');
NODE
echo "PASS $STAGE smoke"
