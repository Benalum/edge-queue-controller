#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16bq-study-card-images-disabled-visible-panel-controlled-mount-executor-source-only"
FRONTEND_ROOT="frontend/wrapper-ui/apc-wrapper-local"
INDEX_REL="${FRONTEND_ROOT}/index.html"
ASSET_REL="${FRONTEND_ROOT}/privatepages/study-card-images-disabled-visible-panel-controlled-mount-executor.js"
PREV_ASSET_REL="${FRONTEND_ROOT}/privatepages/study-card-images-disabled-visible-panel-mount-activation-request.js"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_CONTROLLED_MOUNT_EXECUTOR_R16BQ_SOURCE_ONLY"
CACHE_BUST_RESERVED="stage17k-r16bq-disabled-visible-panel-controlled-mount-executor-source-only-20260710"

printf '=== %s smoke ===\n' "$STAGE"

for required in "$INDEX_REL" "$ASSET_REL" "$PREV_ASSET_REL"; do
  if [ ! -f "$required" ]; then
    echo "FAIL: required file missing: $required" >&2
    exit 1
  fi
done

grep -q "$MARKER" "$ASSET_REL" || { echo "FAIL: marker missing from asset" >&2; exit 1; }

if grep -q "study-card-images-disabled-visible-panel-controlled-mount-executor.js" "$INDEX_REL"; then
  echo "FAIL: source-only controlled mount executor must not be loaded by index yet" >&2
  exit 1
fi
if grep -q "$CACHE_BUST_RESERVED" "$INDEX_REL"; then
  echo "FAIL: reserved cache bust must not be present in index yet" >&2
  exit 1
fi

# Source-only asset must not contain direct DOM/network/storage side-effect APIs.
if grep -E '\b(createElement|appendChild|insertBefore|replaceChildren|removeChild|querySelector|querySelectorAll|getElementById|addEventListener|removeEventListener|dispatchEvent|click|showOpenFilePicker|indexedDB|localStorage|sessionStorage|fetch|XMLHttpRequest|sendBeacon|FormData|FileReader|navigator\.storage)\b' "$ASSET_REL" >/dev/null; then
  echo "FAIL: forbidden side-effect API present in source-only asset" >&2
  exit 1
fi

node <<'NODE' "$ASSET_REL" "$MARKER"
const fs = require("fs");
const vm = require("vm");
const assetPath = process.argv[2];
const marker = process.argv[3];
const code = fs.readFileSync(assetPath, "utf8");
const sandbox = { window: {} };
vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: assetPath });
const api = sandbox.window.APC_STUDY_CARD_IMAGES_DISABLED_VISIBLE_PANEL_CONTROLLED_MOUNT_EXECUTOR_R16BQ;
if (!api) throw new Error("controlled mount executor API missing");
if (api.marker !== marker) throw new Error("marker mismatch");
if (!api.status || api.status.sourceOnly !== true) throw new Error("sourceOnly status mismatch");
if (api.status.executed !== false) throw new Error("executed must be false");
if (api.status.mounted !== false) throw new Error("mounted must be false");
if (api.status.controlsEnabled !== false) throw new Error("controlsEnabled must be false");
if (api.status.filePickerOpened !== false) throw new Error("filePickerOpened must be false");
if (api.status.imagePreviewRendered !== false) throw new Error("imagePreviewRendered must be false");
if (api.status.indexedDbWrite !== false) throw new Error("indexedDbWrite must be false");
if (api.status.backendUpload !== false) throw new Error("backendUpload must be false");
if (api.status.googleDriveSync !== false) throw new Error("googleDriveSync must be false");
if (api.status.ankiMutation !== false) throw new Error("ankiMutation must be false");
if (typeof api.makeControlledMountPlan !== "function") throw new Error("makeControlledMountPlan missing");
const plan = api.makeControlledMountPlan({ activationRequest: { activationRequested: true }, readinessGate: { ready: true }, domMountCandidate: { available: true } });
if (!plan || plan.marker !== marker) throw new Error("plan marker mismatch");
if (plan.canExecute !== false) throw new Error("source-only plan must not execute");
if (plan.shouldMount !== false) throw new Error("source-only plan must not mount");
if (plan.mounted !== false) throw new Error("plan mounted must be false");
if (plan.indexedDbWrite !== false) throw new Error("plan indexedDbWrite must be false");
console.log("PASS node R16BQ disabled visible panel controlled mount executor source-only behavior smoke");
NODE

sha256sum "$ASSET_REL" "$INDEX_REL"
printf 'PASS %s smoke\n' "$STAGE"
