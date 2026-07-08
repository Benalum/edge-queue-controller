#!/usr/bin/env bash
set -Eeuo pipefail

STAGE="stage-17k-r16ai-study-card-images-disabled-panel-runtime-readiness-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-runtime-readiness-check.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RUNTIME_READINESS_R16AI_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="

if [ ! -f "$ASSET" ]; then
  echo "FAIL: missing asset $ASSET" >&2
  exit 1
fi
if [ ! -f "$INDEX" ]; then
  echo "FAIL: missing index $INDEX" >&2
  exit 1
fi
if ! grep -q "$MARKER" "$ASSET"; then
  echo "FAIL: marker missing from $ASSET" >&2
  exit 1
fi
if grep -q "study-card-images-disabled-panel-runtime-readiness-check.js" "$INDEX"; then
  echo "FAIL: R16AI asset must not be loaded by index in source-only stage" >&2
  exit 1
fi

node <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = 'frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-runtime-readiness-check.js';
const code = fs.readFileSync(path, 'utf8');
const forbidden = [
  /\blocalStorage\b/,
  /\bsessionStorage\b/,
  /\bindexedDB\b/i,
  /\bfetch\s*\(/,
  /XMLHttpRequest/,
  /FileReader/,
  /showOpenFilePicker/,
  /createObjectURL/,
  /new\s+Blob\s*\(/,
  /\bFormData\b/,
  /sendBeacon/,
  /navigator\.storage/,
  /document\.createElement\s*\(\s*['"]input['"]/,
  /\.click\s*\(/
];
for (const pattern of forbidden) {
  if (pattern.test(code)) {
    throw new Error(`forbidden source API present: ${pattern}`);
  }
}
const sandbox = { console };
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: path });
const marker = 'APC_STUDY_CARD_IMAGES_DISABLED_PANEL_RUNTIME_READINESS_R16AI_SOURCE_ONLY';
const api = sandbox[marker];
if (!api) throw new Error('marker API missing');
if (api.sourceOnly !== true) throw new Error('sourceOnly must be true');
if (api.runtimeEnabled !== false) throw new Error('runtimeEnabled must be false');
if (api.loadedByIndex !== false) throw new Error('loadedByIndex must be false');
if (api.deploy !== false) throw new Error('deploy must be false');
if (api.mount !== false) throw new Error('mount must be false');
if (!Array.isArray(api.requiredPanelAssets) || api.requiredPanelAssets.length < 10) {
  throw new Error('expected requiredPanelAssets list');
}
const fullRegistry = Object.fromEntries(api.requiredPanelAssets.map((name) => [name, true]));
const ready = api.evaluateReadiness(fullRegistry);
if (ready.readyToLoadAsDisabledPanel !== true) throw new Error('expected ready when registry has all assets');
if (ready.runtimeEnabled !== false) throw new Error('ready check must remain disabled');
if (ready.disabledRuntimeFlags.controlsEnabled !== false) throw new Error('controls must remain disabled');
const notReady = api.evaluateReadiness({});
if (notReady.readyToLoadAsDisabledPanel !== false) throw new Error('expected not ready for empty registry');
if (!Array.isArray(notReady.missingAssets) || notReady.missingAssets.length < 10) {
  throw new Error('expected missing assets for empty registry');
}
console.log('PASS node R16AI disabled panel runtime readiness source-only behavior smoke');
NODE

echo "PASS ${STAGE} smoke"
