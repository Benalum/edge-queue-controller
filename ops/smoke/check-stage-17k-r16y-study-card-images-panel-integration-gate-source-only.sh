#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16y-study-card-images-panel-integration-gate-source-only"
SOURCE="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-panel-integration-gate.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="docs/$STAGE.md"
MARKER="APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE_R16Y_SOURCE_ONLY"

echo "=== $STAGE smoke ==="

[ -f "$SOURCE" ] || { echo "FAIL: missing $SOURCE" >&2; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing $INDEX" >&2; exit 1; }
[ -f "$DOC" ] || { echo "FAIL: missing $DOC" >&2; exit 1; }

grep -Fq "$MARKER" "$SOURCE" || { echo "FAIL: marker missing from source" >&2; exit 1; }
grep -Fq "$MARKER" "$DOC" || { echo "FAIL: marker missing from doc" >&2; exit 1; }

if grep -Fq 'study-card-images-panel-integration-gate.js' "$INDEX"; then
  echo "FAIL: R16Y integration gate must not be loaded by index" >&2
  exit 1
fi

if grep -E 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$SOURCE"; then
  echo "FAIL: source-only integration gate contains forbidden DOM/write/network API" >&2
  exit 1
fi

node - <<'NODE'
const path = require('path');
const api = require(path.resolve('frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-panel-integration-gate.js'));
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_PANEL_INTEGRATION_GATE_R16Y_SOURCE_ONLY') throw new Error('marker mismatch');
if (api.normalizeSide('answer') !== 'answer') throw new Error('answer side normalization failed');
if (api.normalizeSide('bad') !== 'question') throw new Error('default side normalization failed');
const plan = api.createPanelIntegrationGate({ surface: 'study-card-editor', requestedSide: 'answer' });
if (plan.sourceOnly !== true) throw new Error('plan sourceOnly not true');
if (plan.mountedNow !== false) throw new Error('mounted now is not false');
if (plan.question.allowedToShowDisabledPlaceholder !== true) throw new Error('question disabled placeholder not true');
if (plan.answer.allowedToShowDisabledPlaceholder !== true) throw new Error('answer disabled placeholder not true');
if (plan.question.allowedToEnableControls !== false) throw new Error('question controls enabled');
if (plan.answer.allowedToOpenFilePicker !== false) throw new Error('answer file picker enabled');
if (plan.storage.allowedToWriteBlob !== false) throw new Error('blob write enabled');
if (plan.storage.allowedToWriteIndexedDb !== false) throw new Error('indexeddb write enabled');
if (plan.storage.allowedToWriteBackupPayload !== false) throw new Error('backup write enabled');
if (plan.network.allowedToUpload !== false) throw new Error('upload enabled');
if (plan.network.allowedToSyncGoogleDrive !== false) throw new Error('drive sync enabled');
const safety = api.getSafetyFlags();
const falseKeys = ['deployNow','uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow','uploadsNow','writesBackupNow','writesIndexedDbNow','mutatesAnkiNow'];
if (safety.sourceOnly !== true) throw new Error('safety sourceOnly not true');
if (safety.ppbRunnable !== true) throw new Error('safety ppbRunnable not true');
if (safety.interactiveRequired !== false) throw new Error('interactive required');
for (const key of falseKeys) {
  if (safety[key] !== false) throw new Error(`${key} expected false`);
}
console.log('PASS node R16Y panel integration gate source-only behavior smoke');
NODE

echo "PASS $STAGE smoke"
