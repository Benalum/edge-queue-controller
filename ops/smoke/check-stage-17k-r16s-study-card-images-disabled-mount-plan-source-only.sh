#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-${HOME}/Desktop/edge-queue-controller}"
cd "$ROOT"
STAGE="stage-17k-r16s-study-card-images-disabled-mount-plan-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[ -f "$ASSET" ] || { echo "FAIL: missing asset" >&2; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing index" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -Fq "study-card-images-disabled-mount-plan.js" "$INDEX"; then
  echo "FAIL: R16S mount plan is loaded by index" >&2
  exit 1
fi
if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET"; then
  echo "FAIL: forbidden DOM/write API in source-only mount plan" >&2
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js');
const plan = api.createDisabledImageMountPlan({ disabledReason: 'test disabled' });
const validation = api.validateMountPlan(plan);
const summary = api.summarizeMountPlan(plan);
const safety = api.getSafetyFlags();
function assert(cond, msg) { if (!cond) { throw new Error(msg); } }
assert(api.MARKER === 'APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY', 'marker mismatch');
assert(validation.ok === true, 'validation failed');
assert(summary.controlCount === 2, 'expected two controls');
assert(summary.sides.includes('question') && summary.sides.includes('answer'), 'expected question and answer sides');
assert(plan.sourceOnly === true, 'sourceOnly not true');
assert(plan.enabledNow === false, 'enabledNow not false');
assert(plan.mountedNow === false, 'mountedNow not false');
assert(plan.rendersDomNow === false, 'rendersDomNow not false');
assert(plan.bindsEventsNow === false, 'bindsEventsNow not false');
assert(plan.opensFilePickerNow === false, 'opensFilePickerNow not false');
assert(plan.rendersImagePreviewNow === false, 'rendersImagePreviewNow not false');
assert(plan.writesBlobNow === false, 'writesBlobNow not false');
assert(plan.writesIndexedDbNow === false, 'writesIndexedDbNow not false');
assert(plan.writesBackupPayloadNow === false, 'writesBackupPayloadNow not false');
assert(plan.uploadsNow === false, 'uploadsNow not false');
assert(plan.syncsNow === false, 'syncsNow not false');
assert(plan.mutatesAnkiNow === false, 'mutatesAnkiNow not false');
assert(safety.sourceOnly === true, 'safety sourceOnly not true');
for (const [key, value] of Object.entries(safety)) {
  if (key !== 'sourceOnly') assert(value === false, `${key} must be false`);
}
console.log('PASS node R16S disabled mount plan source-only behavior smoke');
NODE

echo "PASS ${STAGE} smoke"
