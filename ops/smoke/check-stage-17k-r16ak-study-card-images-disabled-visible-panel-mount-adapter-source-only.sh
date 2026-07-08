#!/usr/bin/env bash
set -Eeuo pipefail

STAGE="stage-17k-r16ak-study-card-images-disabled-visible-panel-mount-adapter-source-only"
ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$ROOT/index.html"
ASSET="$ROOT/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY"

printf '=== %s smoke ===\n' "$STAGE"

[[ -f "$INDEX" ]] || { echo "FAIL: missing $INDEX" >&2; exit 1; }
[[ -f "$ASSET" ]] || { echo "FAIL: missing $ASSET" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }

if grep -Fq "study-card-images-disabled-visible-panel-mount-adapter.js" "$INDEX"; then
  echo "FAIL: R16AK asset is loaded by index.html; expected source-only not loaded" >&2
  exit 1
fi

if grep -nE '(indexedDB|localStorage|sessionStorage|fetch\(|XMLHttpRequest|FileReader|createObjectURL|navigator\.storage|sendBeacon|WebSocket|postMessage|\.submit\(|\.click\(|new Request|new URL\(|FormData|navigator\.clipboard)' "$ASSET"; then
  echo "FAIL: forbidden browser/write/network API token present" >&2
  exit 1
fi

node <<'NODE'
const api = require('./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-visible-panel-mount-adapter.js');
function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}
assert(api.marker === 'APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_MOUNT_ADAPTER_R16AK_SOURCE_ONLY', 'marker mismatch');
assert(api.sourceOnly === true, 'sourceOnly must be true');
assert(api.disabled === true, 'disabled must be true');
assert(typeof api.createMountAdapter === 'function', 'missing createMountAdapter');
assert(typeof api.describeMount === 'function', 'missing describeMount');
const adapter = api.createMountAdapter({ slotName: '  editor-images  ' });
assert(adapter.sourceOnly === true, 'adapter sourceOnly mismatch');
assert(adapter.disabled === true, 'adapter disabled mismatch');
assert(adapter.loadedByIndex === false, 'adapter must not be loaded by index');
assert(adapter.slotName === 'editor-images', 'slot normalization mismatch');
assert(adapter.sideEffects.domMount === false, 'domMount must remain false');
assert(adapter.sideEffects.filePicker === false, 'filePicker must remain false');
assert(adapter.sideEffects.clientWrite === false, 'clientWrite must remain false');
assert(adapter.sideEffects.networkWrite === false, 'networkWrite must remain false');
const descriptor = api.describeMount(adapter);
assert(descriptor.mounted === false, 'descriptor must not mount');
assert(descriptor.controlsEnabled === false, 'controls must be disabled');
assert(descriptor.previewVisible === false, 'preview must not be visible');
assert(descriptor.writesAllowed === false, 'writes must not be allowed');
console.log('PASS node R16AK disabled visible panel mount adapter source-only behavior smoke');
NODE

printf 'PASS %s smoke\n' "$STAGE"
