#!/usr/bin/env bash
set -euo pipefail

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
SRC_IMPORT="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js"
SRC_BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js"
SRC_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-panel.js"
SRC_MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js"
SMOKE_E="ops/smoke/check-stage-17k-z-r11e-profile-anki-apkg-preview-bridge-no-ui.sh"
SMOKE_F="ops/smoke/check-stage-17k-z-r11f-profile-anki-apkg-preview-panel-source-no-mount.sh"
DOC="docs/stage-17k-z-r11g-profile-anki-preview-source-mount-no-deploy.md"

test -f "$INDEX"
test -f "$SRC_IMPORT"
test -f "$SRC_BRIDGE"
test -f "$SRC_PANEL"
test -f "$SRC_MOUNT"
test -f "$SMOKE_E"
test -f "$SMOKE_F"
test -f "$DOC"

grep -q "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" "$SRC_IMPORT"
grep -q "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E" "$SRC_BRIDGE"
grep -q "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F" "$SRC_PANEL"
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" "$SRC_MOUNT"
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT" "$SRC_MOUNT"
grep -q "ensureProfileAnkiPreviewMounted" "$SRC_MOUNT"
grep -q "scheduleAutoMount" "$SRC_MOUNT"

grep -q "/privatepages/anki-import-local.js" "$INDEX"
grep -q "/privatepages/profile-anki-import-bridge.js" "$INDEX"
grep -q "/privatepages/profile-anki-preview-panel.js" "$INDEX"
grep -q "/privatepages/profile-anki-preview-mount.js" "$INDEX"

python3 - <<'PY'
from pathlib import Path
html = Path("frontend/wrapper-ui/apc-wrapper-local/index.html").read_text()
order = [
    "/privatepages/anki-import-local.js",
    "/privatepages/profile-anki-import-bridge.js",
    "/privatepages/profile-anki-preview-panel.js",
    "/privatepages/profile-anki-preview-mount.js",
]
positions = [html.index(item) for item in order]
if positions != sorted(positions):
    raise SystemExit(f"script load order is wrong: {positions}")
print("PASS source script load order")
PY

grep -q "No deploy" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"
grep -q "No live frontend mutation" "$DOC"

grep -q "R11G source mount supersedes" "$SMOKE_E"
grep -q "R11G source mount supersedes" "$SMOKE_F"

if grep -nE 'fetch[[:space:]]*\(|XMLHttpRequest|sendBeacon|/api/|APC_LOCAL_SAVE[.]write|localStorage[.]setItem|indexedDB[.]open' "$SRC_MOUNT"; then
  echo "FAIL: R11G mount must not use network, backend routes, or persistence writes"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$SRC_IMPORT"
  node --check "$SRC_BRIDGE"
  node --check "$SRC_PANEL"
  node --check "$SRC_MOUNT"
  node - <<'NODE'
const assert = require("assert");
const mount = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js");
assert.strictEqual(mount.marker, "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G");
assert.strictEqual(mount.mountId, "apc-profile-anki-preview-panel-r11g");
assert.strictEqual(typeof mount.ensureProfileAnkiPreviewMounted, "function");
assert.strictEqual(typeof mount.scheduleAutoMount, "function");
console.log("PASS node profile anki preview mount api smoke");
NODE
fi

echo "PASS stage-17k-z-r11g profile anki preview source mount smoke"
