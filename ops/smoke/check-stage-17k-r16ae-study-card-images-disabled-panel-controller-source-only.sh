#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ae-study-card-images-disabled-panel-controller-source-only"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
ASSET="$FRONTEND/privatepages/study-card-images-disabled-panel-controller-plan.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_CONTROLLER_PLAN_R16AE_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[ -f "$INDEX" ] || { echo "FAIL: missing index" >&2; exit 1; }
[ -f "$ASSET" ] || { echo "FAIL: missing asset" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -Fq "study-card-images-disabled-panel-controller-plan.js" "$INDEX"; then
  echo "FAIL: index loads source-only controller plan" >&2
  exit 1
fi
if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET"; then
  echo "FAIL: forbidden DOM/write/network API found" >&2
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-controller-plan.js');
function assert(cond, msg) { if (!cond) { throw new Error(msg); } }
assert(api.MARKER === 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_CONTROLLER_PLAN_R16AE_SOURCE_ONLY', 'marker mismatch');
assert(typeof api.getSafetyFlags === 'function', 'missing getSafetyFlags');
assert(typeof api.createDisabledPanelControllerPlan === 'function', 'missing createDisabledPanelControllerPlan');
assert(typeof api.validateDisabledPanelControllerPlan === 'function', 'missing validateDisabledPanelControllerPlan');
const safety = api.getSafetyFlags();
for (const key of [
  'uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow',
  'indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow',
  'ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow','uploadsNow','writesBackupNow','writesIndexedDbNow','mutatesAnkiNow'
]) {
  assert(safety[key] === false, `expected ${key}=false`);
}
const plan = api.createDisabledPanelControllerPlan({ cardId: 'card-1', sides: ['question', 'answer'] });
assert(api.validateDisabledPanelControllerPlan(plan), 'plan validation failed');
assert(plan.sections.length === 2, 'expected question and answer sections');
assert(plan.sections.every((section) => section.buttonDisabled === true), 'sections must be disabled');
assert(plan.sections.every((section) => section.fileInputAllowedNow === false), 'file input must be disabled');
assert(plan.sections.every((section) => section.previewAllowedNow === false), 'preview must be disabled');
console.log('PASS node R16AE disabled panel controller source-only behavior smoke');
NODE

echo "PASS ${STAGE} smoke"
