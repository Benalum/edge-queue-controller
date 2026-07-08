#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16be-study-card-images-disabled-visible-panel-mount-readiness-gate-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-readiness-gate.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[ -f "$ASSET" ] || { echo "FAIL: missing asset $ASSET"; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing index $INDEX"; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing from asset"; exit 1; }
if grep -Fq 'study-card-images-disabled-visible-panel-mount-readiness-gate.js' "$INDEX"; then
  echo "FAIL: R16BE asset must not be loaded by index in source-only stage"
  exit 1
fi
if grep -En '\b(fetch|XMLHttpRequest|sendBeacon|indexedDB|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|addEventListener|dispatchEvent)\b|\.click\s*\(' "$ASSET"; then
  echo "FAIL: forbidden runtime/write/bind API present"
  exit 1
fi
node <<'NODE'
const fs = require('fs');
const vm = require('vm');
const code = fs.readFileSync('frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-readiness-gate.js', 'utf8');
const context = { window: {} };
vm.createContext(context);
vm.runInContext(code, context, { filename: 'study-card-images-disabled-visible-panel-mount-readiness-gate.js' });
const api = context.window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE;
function assert(condition, message) { if (!condition) throw new Error(message); }
assert(api, 'api missing');
assert(api.marker === 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_READINESS_GATE_R16BE_SOURCE_ONLY', 'marker mismatch');
assert(api.sourceOnly === true, 'sourceOnly must be true');
assert(api.disabled === true, 'disabled must be true');
assert(api.status.executed === false, 'executed must be false');
assert(api.status.mounted === false, 'mounted must be false');
assert(api.status.controlsEnabled === false, 'controls must be disabled');
assert(api.status.filePickerOpened === false, 'file picker must not open');
assert(api.status.imagePreviewRendered === false, 'preview must not render');
assert(api.status.indexedDbWrite === false, 'indexedDbWrite must be false');
assert(api.status.backendUpload === false, 'backendUpload must be false');
assert(api.status.googleDriveSync === false, 'googleDriveSync must be false');
assert(api.status.ankiMutation === false, 'ankiMutation must be false');
const report = api.createMountReadinessReport();
assert(api.assertMountReadinessDisabled(report) === true, 'readiness report must assert disabled');
assert(report.mayExecute === false, 'mayExecute must be false');
assert(report.mayMount === false, 'mayMount must be false');
assert(report.mayBindEvents === false, 'mayBindEvents must be false');
assert(report.requiredApis.length === 6, 'requiredApis length mismatch');
console.log('PASS node R16BE mount readiness gate source-only behavior smoke');
NODE
echo "PASS ${STAGE} smoke"
