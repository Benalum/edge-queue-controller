#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ad-study-card-images-disabled-panel-mount-target-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-mount-target.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET_R16AD_SOURCE_ONLY"
printf '=== %s smoke ===\n' "$STAGE"
test -f "$ASSET"
grep -Fq "$MARKER" "$ASSET"
if grep -Fq 'study-card-images-disabled-panel-mount-target.js' "$INDEX"; then
  printf 'FAIL: R16AD asset is loaded by index.html\n' >&2
  exit 1
fi
if grep -Eq 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET"; then
  printf 'FAIL: forbidden DOM/write API found in source-only R16AD asset\n' >&2
  exit 1
fi
node <<'EOF_NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-mount-target.js');
if (!api || api.MARKER !== 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_MOUNT_TARGET_R16AD_SOURCE_ONLY') throw new Error('marker mismatch');
const question = api.createMountTargetPlan({ side: 'question', targetIds: ['study-card-editor-main', 'study-card-form'] });
const answer = api.createMountTargetPlan({ side: 'answer' });
for (const plan of [question, answer]) {
  const validation = api.validateMountTargetPlan(plan);
  if (!validation.ok) throw new Error('validation failed ' + validation.errors.join(','));
  if (plan.mountedNow !== false || plan.boundNow !== false || plan.writeEnabledNow !== false) throw new Error('unsafe plan state');
  if (!Array.isArray(plan.candidates) || plan.candidates.length < 1) throw new Error('missing candidates');
  for (const candidate of plan.candidates) {
    if (candidate.mountsNow !== false || candidate.bindsNow !== false || candidate.resolvesNow !== false) throw new Error('candidate is active');
  }
}
const safety = api.getSafetyFlags();
const badKeys = [
  'uiMountedNow','buttonRenderedNow','controlsEnabledNow','filePickerOpenedNow','imagePreviewRenderedNow',
  'blobStoredNow','indexedDbWriteNow','backupPayloadWriteNow','backendUploadAllowed','serverSyncAllowed',
  'googleDriveSyncAllowedNow','ankiMutationAllowed','originalFileMutationAllowed','mediaExtractionNow',
  'uploadsNow','writesBackupNow','writesIndexedDbNow','mutatesAnkiNow'
];
if (safety.sourceOnly !== true) throw new Error('sourceOnly not true');
for (const key of badKeys) {
  if (safety[key] !== false) throw new Error('unsafe safety key ' + key);
}
console.log('PASS node R16AD disabled panel mount target source-only behavior smoke');
EOF_NODE
printf 'PASS %s smoke\n' "$STAGE"
