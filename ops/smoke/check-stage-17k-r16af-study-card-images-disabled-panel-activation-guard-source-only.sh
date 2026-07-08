#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16af-study-card-images-disabled-panel-activation-guard-source-only"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
ASSET="$FRONTEND/privatepages/study-card-images-disabled-panel-activation-guard.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD_R16AF_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[ -f "$INDEX" ] || { echo "FAIL: missing index" >&2; exit 1; }
[ -f "$ASSET" ] || { echo "FAIL: missing asset" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -Fq "study-card-images-disabled-panel-activation-guard.js" "$INDEX"; then
  echo "FAIL: index loads source-only activation guard" >&2
  exit 1
fi
if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET"; then
  echo "FAIL: forbidden DOM/write/network API found" >&2
  exit 1
fi
node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-activation-guard.js');
function assert(cond, msg) { if (!cond) { throw new Error(msg); } }
assert(api.MARKER === 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_ACTIVATION_GUARD_R16AF_SOURCE_ONLY', 'marker mismatch');
assert(typeof api.getSafetyFlags === 'function', 'missing getSafetyFlags');
assert(typeof api.createDisabledPanelActivationGuard === 'function', 'missing createDisabledPanelActivationGuard');
assert(typeof api.evaluateActivationRequest === 'function', 'missing evaluateActivationRequest');
assert(typeof api.validateDisabledPanelActivationGuard === 'function', 'missing validateDisabledPanelActivationGuard');
const safety = api.getSafetyFlags();
for (const key of [
  'uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow',
  'indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow',
  'ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow','uploadsNow','writesBackupNow','writesIndexedDbNow','mutatesAnkiNow'
]) {
  assert(safety[key] === false, `expected ${key}=false`);
}
const guard = api.createDisabledPanelActivationGuard({ proofs: ['PASS_R16V_DISABLED_MOUNT_PLAN_LOADED_NO_UI_NO_BINDING'] });
assert(api.validateDisabledPanelActivationGuard(guard), 'guard validation failed');
assert(guard.canActivateVisibleDisabledPanelNow === false, 'activation must remain false');
assert(guard.canEnableControlsNow === false, 'controls must remain false');
assert(Array.isArray(guard.missingProofs), 'missingProofs missing');
const decision = api.evaluateActivationRequest({ proofs: guard.providedProofs });
assert(decision.approved === false, 'activation request must not be approved');
assert(decision.canActivateVisibleDisabledPanelNow === false, 'decision activation must remain false');
console.log('PASS node R16AF disabled panel activation guard source-only behavior smoke');
NODE

echo "PASS ${STAGE} smoke"
