#!/usr/bin/env bash
set -euo pipefail

HTML_RENDERER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-html-preview-renderer.js"
RENDER_SPEC="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-render-spec.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-r14u-disabled-save-button-html-preview-renderer-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14u-disabled-save-button-html-preview-renderer-source-only"

test -f "$HTML_RENDERER"
test -f "$RENDER_SPEC"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER_R14U_SOURCE_ONLY" "$HTML_RENDERER"
grep -Fq "createDisabledSaveButtonHtmlPreview" "$HTML_RENDERER"
grep -Fq "createDisabledSaveButtonHtmlPreviewText" "$HTML_RENDERER"
grep -Fq "htmlPreviewOnly: true" "$HTML_RENDERER"
grep -Fq "domElementCreated: false" "$HTML_RENDERER"
grep -Fq "elementInserted: false" "$HTML_RENDERER"
grep -Fq "buttonElementCreated: false" "$HTML_RENDERER"
grep -Fq "buttonVisibleNow: false" "$HTML_RENDERER"
grep -Fq "buttonDisabledNow: true" "$HTML_RENDERER"
grep -Fq "htmlStringCreated: true" "$HTML_RENDERER"
grep -Fq "actionBoundToUi: false" "$HTML_RENDERER"
grep -Fq "clickHandlerAdded: false" "$HTML_RENDERER"
grep -Fq "writeExecutorCalled: false" "$HTML_RENDERER"
grep -Fq "canWriteNow: false" "$HTML_RENDERER"
grep -Fq "writesEnabledNow: false" "$HTML_RENDERER"

grep -Fq "Disabled Save Button HTML Preview Renderer Source-Only" "$DOC"
grep -Fq "No DOM creation" "$DOC"
grep -Fq "No button insertion" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

if grep -Fq "/privatepages/local-backup-current-file-disabled-save-button-html-preview-renderer.js" "$INDEX"; then
  echo "FAIL: HTML renderer must not be loaded by index.html"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER" "$MOUNT" "$PANEL"; then
  echo "FAIL: HTML renderer must not be referenced by live mount/panel"
  exit 1
fi

if grep -Eq "document\.createElement|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|executeCurrentBackupWrite\(" "$HTML_RENDERER"; then
  echo "FAIL: HTML renderer must not create DOM, attach clicks, or call write executor"
  exit 1
fi

if grep -Eq "createWritable\(|\.write\(|\.close\(|showSaveFilePicker|showDirectoryPicker" "$HTML_RENDERER"; then
  echo "FAIL: HTML renderer must not contain write picker/stream code"
  exit 1
fi

node --check "$HTML_RENDERER"

node - <<'NODE'
const renderSpec = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-render-spec.js");
globalThis.APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC = renderSpec;

const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-html-preview-renderer.js");
const preview = api.createDisabledSaveButtonHtmlPreview({}, {});

if (api.MARKER !== "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_HTML_PREVIEW_RENDERER_R14U_SOURCE_ONLY") throw new Error("api marker mismatch");
if (preview.marker !== api.MARKER) throw new Error("preview marker mismatch");
if (preview.sourceOnly !== true) throw new Error("sourceOnly should be true");
if (preview.deployed !== false) throw new Error("deployed should be false");
if (preview.uiLoaded !== false) throw new Error("uiLoaded should be false");
if (preview.htmlPreviewOnly !== true) throw new Error("htmlPreviewOnly should be true");
if (preview.domElementCreated !== false) throw new Error("domElementCreated should be false");
if (preview.elementInserted !== false) throw new Error("elementInserted should be false");
if (preview.buttonElementCreated !== false) throw new Error("buttonElementCreated should be false");
if (preview.buttonVisibleNow !== false) throw new Error("buttonVisibleNow should be false");
if (preview.buttonDisabledNow !== true) throw new Error("buttonDisabledNow should be true");
if (preview.htmlStringCreated !== true) throw new Error("htmlStringCreated should be true");
if (preview.actionBoundToUi !== false) throw new Error("actionBoundToUi should be false");
if (preview.clickHandlerAdded !== false) throw new Error("clickHandlerAdded should be false");
if (preview.writeExecutorCalled !== false) throw new Error("writeExecutorCalled should be false");
if (preview.canWriteNow !== false) throw new Error("canWriteNow should be false");
if (preview.writesEnabledNow !== false) throw new Error("writesEnabledNow should be false");
if (!preview.html.includes("<button ")) throw new Error("preview should include button HTML string");
if (!preview.html.includes("disabled=\"disabled\"")) throw new Error("preview should include disabled attr");
if (!preview.html.includes("aria-disabled=\"true\"")) throw new Error("preview should include aria-disabled attr");
if (!preview.html.includes("Save current backup")) throw new Error("preview should include label");

const text = api.createDisabledSaveButtonHtmlPreviewText(preview);
if (!text.includes("Save current backup HTML preview")) throw new Error("text missing title");
if (!text.includes("DOM element created: false")) throw new Error("text missing DOM false");
if (!text.includes("No file is saved, replaced, merged, restored, or overwritten.")) throw new Error("text missing safety");

console.log("PASS node R14U HTML preview renderer source-only behavior smoke");
NODE

echo "PASS stage-17k-r14u disabled save button html preview renderer source-only smoke"
