#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16z-study-card-images-disabled-panel-bind-plan-source-only"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN_R16Z_SOURCE_ONLY"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
SOURCE="$FRONTEND/privatepages/study-card-images-disabled-panel-bind-plan.js"
INDEX="$FRONTEND/index.html"
DOC="docs/$STAGE.md"

echo "=== $STAGE smoke ==="

[ -f "$SOURCE" ] || { echo "FAIL: missing source" >&2; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing index" >&2; exit 1; }
[ -f "$DOC" ] || { echo "FAIL: missing doc" >&2; exit 1; }

grep -Fq "$MARKER" "$SOURCE" || { echo "FAIL: marker missing from source" >&2; exit 1; }
if grep -Fq 'study-card-images-disabled-panel-bind-plan.js' "$INDEX"; then
  echo "FAIL: R16Z bind plan must not be loaded by index" >&2
  exit 1
fi

if grep -E 'appendChild|insertAdjacentElement|addEventListener|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$SOURCE" >/dev/null; then
  echo "FAIL: forbidden DOM/write API present in source" >&2
  exit 1
fi

node - <<'NODE'
const path = require('path');
const api = require(path.resolve('frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-bind-plan.js'));
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN_R16Z_SOURCE_ONLY') throw new Error('marker mismatch');
const safety = api.getSafetyFlags();
const falseKeys = ['deployNow','uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow','blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed','googleDriveSyncAllowedNow','ankiMutationAllowed','eventWiringNow','domWriteNow'];
if (safety.sourceOnly !== true) throw new Error('sourceOnly expected true');
for (const key of falseKeys) {
  if (safety[key] !== false) throw new Error(`${key} expected false`);
}
const plan = api.createPanelBindPlan({ surface: 'study-card-editor', rootKey: 'studyCardImagePanel' });
if (plan.marker !== api.MARKER) throw new Error('plan marker mismatch');
if (plan.sourceOnly !== true) throw new Error('plan sourceOnly mismatch');
if (plan.deployNow !== false || plan.mountNow !== false || plan.bindNow !== false) throw new Error('bind path enabled');
if (plan.eventWiringNow !== false || plan.domWriteNow !== false) throw new Error('dom/event path enabled');
if (plan.controls.question.enabledNow !== false || plan.controls.answer.enabledNow !== false) throw new Error('controls enabled');
if (plan.storage.writeBlobNow !== false || plan.storage.writeIndexedDbNow !== false || plan.storage.writeBackupPayloadNow !== false) throw new Error('storage write enabled');
if (plan.network.uploadNow !== false || plan.network.serverSyncNow !== false || plan.network.googleDriveSyncNow !== false) throw new Error('network enabled');
console.log('PASS node R16Z disabled panel bind plan source-only behavior smoke');
NODE

grep -Fq "$MARKER" "$DOC" || { echo "FAIL: marker missing from doc" >&2; exit 1; }
grep -Fq 'source-only' "$DOC" || { echo "FAIL: source-only wording missing from doc" >&2; exit 1; }

echo "PASS $STAGE smoke"
