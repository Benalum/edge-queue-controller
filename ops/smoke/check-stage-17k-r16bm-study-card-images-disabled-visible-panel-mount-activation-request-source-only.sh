#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16bm-study-card-images-disabled-visible-panel-mount-activation-request-source-only"
FRONTEND="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$FRONTEND/index.html"
ASSET="$FRONTEND/privatepages/study-card-images-disabled-visible-panel-mount-activation-request.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM_SOURCE_ONLY"
API="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM"

echo "=== ${STAGE} smoke ==="
[ -f "$INDEX" ] || { echo "FAIL: missing index"; exit 1; }
[ -f "$ASSET" ] || { echo "FAIL: missing asset"; exit 1; }
grep -q "$MARKER" "$ASSET" || { echo "FAIL: missing marker"; exit 1; }
grep -q "$API" "$ASSET" || { echo "FAIL: missing API"; exit 1; }
if grep -q 'study-card-images-disabled-visible-panel-mount-activation-request.js' "$INDEX"; then
  echo "FAIL: source-only activation request must not be loaded by index"
  exit 1
fi
if grep -Eq 'appendChild|addEventListener|createElement|insertAdjacentHTML|innerHTML[[:space:]]*=|indexedDB|fetch[[:space:]]*\(|XMLHttpRequest|FileReader|showOpenFilePicker|localStorage[.]setItem|APC_LOCAL_SAVE' "$ASSET"; then
  echo "FAIL: forbidden side-effect API present in source-only asset"
  exit 1
fi
node <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = 'frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-activation-request.js';
const src = fs.readFileSync(path, 'utf8');
const sandbox = { window: {}, globalThis: {} };
sandbox.globalThis = sandbox.window;
vm.createContext(sandbox);
vm.runInContext(src, sandbox, { filename: path });
const api = sandbox.window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM;
if (!api) throw new Error('API missing');
if (api.marker !== 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ACTIVATION_REQUEST_R16BM_SOURCE_ONLY') throw new Error('marker mismatch');
if (!api.request || api.request.mountMode !== 'disabled-visible-shell') throw new Error('mount mode mismatch');
if (!api.status || api.status.executed !== false) throw new Error('must not execute');
if (api.status.mounted !== false) throw new Error('must not mount');
if (api.status.controlsEnabled !== false) throw new Error('controls must stay disabled');
if (api.status.indexedDbWrite !== false) throw new Error('must not write IndexedDB');
if (api.status.backendUpload !== false) throw new Error('must not upload backend');
if (api.status.googleDriveSync !== false) throw new Error('must not sync Drive');
if (api.status.ankiMutation !== false) throw new Error('must not mutate Anki');
if (typeof api.describeActivationRequest !== 'function') throw new Error('describeActivationRequest missing');
console.log('PASS node R16BM disabled visible panel mount activation request source-only behavior smoke');
NODE
sha256sum "$ASSET" "$INDEX"
echo "PASS ${STAGE} smoke"
