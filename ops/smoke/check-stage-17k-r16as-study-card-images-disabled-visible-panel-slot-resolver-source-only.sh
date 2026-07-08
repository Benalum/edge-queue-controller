#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16as-study-card-images-disabled-visible-panel-slot-resolver-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-slot-resolver.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"
[ -f "$ASSET" ] || { echo "FAIL: missing $ASSET"; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing $INDEX"; exit 1; }
grep -q "$MARKER" "$ASSET" || { echo 'FAIL: R16AS marker missing'; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel-slot-resolver.js' "$INDEX"; then
  echo 'FAIL: R16AS slot resolver must not be loaded by index in source-only stage'
  exit 1
fi
if grep -Eq 'document\.|querySelector|createElement|appendChild|insertAdjacentHTML|innerHTML\s*=|addEventListener|indexedDB|localStorage|sessionStorage|fetch\s*\(|XMLHttpRequest|navigator\.storage|showOpenFilePicker|FileReader|createObjectURL|APC_GOOGLE_SYNC|APC_ANKI|/api/study|/api/anki' "$ASSET"; then
  echo 'FAIL: forbidden source API present in R16AS asset'
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-slot-resolver.js');
function assert(condition, message) {
  if (!condition) throw new Error(message);
}
assert(api.marker === 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_SLOT_RESOLVER_R16AS_SOURCE_ONLY', 'marker mismatch');
assert(api.sourceOnly === true, 'sourceOnly must be true');
assert(api.enabled === false, 'enabled must be false');
assert(api.mounted === false, 'mounted must be false');
assert(Array.isArray(api.candidateSlots), 'candidateSlots must be an array');
assert(api.candidateSlots.length === 3, 'expected three candidate slots');
assert(api.sideEffects.inspectPageOnLoad === false, 'inspectPageOnLoad must be false');
assert(api.sideEffects.createSlot === false, 'createSlot must be false');
assert(api.sideEffects.mountPanel === false, 'mountPanel must be false');
assert(api.sideEffects.bindEvents === false, 'bindEvents must be false');
assert(api.sideEffects.openFilePicker === false, 'openFilePicker must be false');
assert(api.sideEffects.renderPreview === false, 'renderPreview must be false');
assert(api.sideEffects.writeClientStorage === false, 'writeClientStorage must be false');
assert(api.sideEffects.writeBackupPayload === false, 'writeBackupPayload must be false');
assert(api.sideEffects.uploadBackend === false, 'uploadBackend must be false');
assert(api.sideEffects.syncGoogleDrive === false, 'syncGoogleDrive must be false');
assert(api.sideEffects.mutateAnki === false, 'mutateAnki must be false');
const defaultPlan = api.createSlotResolutionPlan();
assert(api.assertSlotResolutionPlan(defaultPlan), 'default slot plan assertion failed');
assert(defaultPlan.fallback.behavior === 'defer', 'fallback behavior must defer');
assert(defaultPlan.fallback.createMissingSlot === false, 'must not create missing slot');
assert(defaultPlan.fallback.mountWithoutAnchor === false, 'must not mount without anchor');
const preferredPlan = api.createSlotResolutionPlan({ preferredSlot: 'card-editor-images-footer' });
assert(api.assertSlotResolutionPlan(preferredPlan), 'preferred slot plan assertion failed');
assert(preferredPlan.selectedSlot.name === 'card-editor-images-footer', 'preferred slot selection failed');
console.log('PASS node R16AS disabled visible panel slot resolver source-only behavior smoke');
NODE
printf 'PASS %s smoke\n' "$STAGE"
