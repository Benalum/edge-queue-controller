#!/usr/bin/env bash
set -Eeuo pipefail
STAGE="stage-17k-r16x-study-card-images-disabled-panel-bridge-source-only"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
SRC="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-bridge.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE_R16X_SOURCE_ONLY"

echo "=== $STAGE smoke ==="
test -f "$SRC"
test -f "$INDEX"
grep -Fq "$MARKER" "$SRC"
if grep -Fq "study-card-images-disabled-panel-bridge.js" "$INDEX"; then
  echo "FAIL: R16X bridge must not be loaded by index.html" >&2
  exit 1
fi
if grep -E 'document\.|appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$SRC" >/dev/null; then
  echo "FAIL: forbidden DOM/write/network/file API found in source-only bridge" >&2
  exit 1
fi
node <<'NODE'
const path = require('path');
const src = path.resolve('frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-bridge.js');
require(src);
const api = globalThis.APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE;
function assert(cond, msg) { if (!cond) throw new Error(msg); }
assert(api, 'api missing');
assert(api.MARKER === 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BRIDGE_R16X_SOURCE_ONLY', 'marker mismatch');
const plan = api.createPanelBridgePlan();
assert(plan.sourceOnly === true, 'plan sourceOnly mismatch');
assert(plan.mountedNow === false, 'plan mountedNow mismatch');
assert(plan.boundNow === false, 'plan boundNow mismatch');
assert(Array.isArray(plan.panels) && plan.panels.length === 2, 'expected two side panels');
assert(plan.panels.some((p) => p.side === 'question'), 'question panel missing');
assert(plan.panels.some((p) => p.side === 'answer'), 'answer panel missing');
assert(plan.panels.every((p) => p.controls.filePickerEnabled === false), 'file picker enabled unexpectedly');
assert(plan.panels.every((p) => p.controls.saveEnabled === false), 'save enabled unexpectedly');
const noop = api.createNoopMountResult();
assert(noop.mounted === false && noop.bound === false && noop.rendered === false, 'noop result unsafe');
const flags = api.getSafetyFlags();
for (const [key, value] of Object.entries(flags)) {
  if (key === 'marker' || key === 'version') continue;
  if (key === 'sourceOnly') assert(value === true, 'sourceOnly flag false');
  else assert(value === false, key + ' expected false');
}
console.log('PASS node R16X disabled panel bridge source-only behavior smoke');
NODE

echo "PASS $STAGE smoke"
