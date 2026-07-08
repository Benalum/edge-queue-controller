#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-17k-r16ac-study-card-images-disabled-panel-html-preview-renderer-source-only"
ASSET="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-html-preview-renderer.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MARKER="APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER_R16AC_SOURCE_ONLY"

echo "=== ${STAGE} smoke ==="
[ -f "$ASSET" ] || { echo "FAIL: missing asset" >&2; exit 1; }
[ -f "$INDEX" ] || { echo "FAIL: missing index" >&2; exit 1; }
grep -Fq "$MARKER" "$ASSET" || { echo "FAIL: marker missing" >&2; exit 1; }
if grep -Fq "study-card-images-disabled-panel-html-preview-renderer.js" "$INDEX"; then
  echo "FAIL: asset should not be loaded by index" >&2
  exit 1
fi
if grep -Eq 'appendChild|insertAdjacentElement|addEventListener\(["'"'"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|showDirectoryPicker|createWritable\(|\.write\(|\.close\(' "$ASSET"; then
  echo "FAIL: forbidden DOM/write/network/file API present in source-only asset" >&2
  exit 1
fi

node <<'NODE'
const assert = require("assert");
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-html-preview-renderer.js");
assert.strictEqual(api.MARKER, "APC_STUDY_CARD_IMAGES_DISABLED_PANEL_HTML_PREVIEW_RENDERER_R16AC_SOURCE_ONLY");
const model = api.createDisabledPanelPreviewModel({ note: "<unsafe>" });
assert.strictEqual(model.disabled, true);
assert.strictEqual(model.mounted, false);
assert.strictEqual(model.sides.length, 2);
assert.strictEqual(model.sides[0].side, "question");
assert.strictEqual(model.sides[1].side, "answer");
assert.strictEqual(model.sides[0].disabled, true);
assert.strictEqual(model.sides[1].inputDisabled, true);
const html = api.buildDisabledPanelHtmlPreview({ note: "<unsafe>" });
assert(html.includes("Question image"));
assert(html.includes("Answer image"));
assert(html.includes("disabled"));
assert(html.includes("&lt;unsafe&gt;"));
assert(!html.includes("<unsafe>"));
assert(!/<script/i.test(html));
const safety = api.getSafetyFlags();
assert.strictEqual(safety.sourceOnly, true);
for (const [key, value] of Object.entries(safety)) {
  if (key !== "sourceOnly") assert.strictEqual(value, false, key);
}
console.log("PASS node R16AC disabled panel html preview renderer source-only behavior smoke");
NODE

echo "PASS ${STAGE} smoke"
