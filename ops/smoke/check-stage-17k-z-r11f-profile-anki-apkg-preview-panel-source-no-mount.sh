#!/usr/bin/env bash
set -euo pipefail

SRC_IMPORT="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js"
SRC_BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js"
SRC_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-panel.js"
DOC="docs/stage-17k-z-r11f-profile-anki-apkg-preview-panel-source-no-mount.md"

test -f "$SRC_IMPORT"
test -f "$SRC_BRIDGE"
test -f "$SRC_PANEL"
test -f "$DOC"

grep -q "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F" "$SRC_PANEL"
grep -q "APC_PROFILE_ANKI_PREVIEW_PANEL" "$SRC_PANEL"
grep -q "createPreviewModel" "$SRC_PANEL"
grep -q "renderPreviewHtml" "$SRC_PANEL"
grep -q "renderPanel" "$SRC_PANEL"
grep -q "input type=\"file\"" "$SRC_PANEL"
grep -q "accept=\".apkg\"" "$SRC_PANEL"

grep -q "No deploy" "$DOC"
grep -q "No UI activation" "$DOC"
grep -q "No index.html script mount" "$DOC"
grep -q "No profile.html script mount" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

if grep -nE 'fetch[[:space:]]*\(|XMLHttpRequest|sendBeacon|/api/|APC_LOCAL_SAVE[.]write|localStorage[.]setItem|indexedDB[.]open' "$SRC_PANEL"; then
  echo "FAIL: R11F panel must not use network, backend routes, or persistence writes"
  exit 1
fi

if grep -n "profile-anki-preview-panel.js" frontend/wrapper-ui/apc-wrapper-local/index.html frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html >/tmp/apc-r11f-mounted-check.txt 2>/dev/null; then
  echo "FAIL: R11F panel must not be mounted in UI yet"
  cat /tmp/apc-r11f-mounted-check.txt
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$SRC_IMPORT"
  node --check "$SRC_BRIDGE"
  node --check "$SRC_PANEL"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
FIXTURE_APKG="$TMPDIR/r11f-profile-panel.apkg"

python3 - "$FIXTURE_APKG" <<'PY'
import json
import sys
import zipfile
from pathlib import Path

out = Path(sys.argv[1])
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_STORED) as zf:
    zf.writestr("collection.anki2", b"SQLite format 3\x00fixture")
    zf.writestr("media", json.dumps({"0": "cell.png"}))
    zf.writestr("0", b"fake-image")
print(out)
PY

if command -v node >/dev/null 2>&1; then
  node - "$FIXTURE_APKG" <<'NODE'
const assert = require("assert");
const fs = require("fs");

const importer = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js");
const bridge = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js");
const panel = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-panel.js");

const filePath = process.argv[2];
const buffer = fs.readFileSync(filePath);
const arrayBuffer = buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);

const fileLike = {
  name: "r11f-profile-panel.apkg",
  size: buffer.length,
  lastModified: 1782880000000,
  arrayBuffer: async () => arrayBuffer
};

panel.createPreviewModel({
  file: fileLike,
  bridge,
  importer
}).then((preview) => {
  assert.strictEqual(panel.marker, "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F");
  assert.strictEqual(preview.marker, "APC_PROFILE_ANKI_PREVIEW_PANEL_R11F");
  assert.strictEqual(preview.sourceSurface, "profile");
  assert.strictEqual(preview.mode, "apkg-preview-only");
  assert.strictEqual(preview.disabledPreviewOnly, true);
  assert.strictEqual(preview.writesOriginalAnki, false);
  assert.strictEqual(preview.writesServer, false);
  assert.strictEqual(preview.writesLocalDocs, false);
  assert.strictEqual(preview.file.name, "r11f-profile-panel.apkg");
  assert.strictEqual(preview.package.isApkgContainer, true);
  assert.strictEqual(preview.package.hasCollectionAnki2, true);
  assert.strictEqual(preview.package.hasMediaJson, true);
  assert.strictEqual(preview.package.numericMediaEntryCount, 1);

  const html = panel.renderPreviewHtml(preview);
  assert.ok(html.includes("Anki package preview"));
  assert.ok(html.includes("r11f-profile-panel.apkg"));
  assert.ok(html.includes("collection.anki2"));
  assert.ok(html.includes("Nothing is uploaded"));
  console.log("PASS node profile anki preview panel smoke");
}).catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE
else
  echo "node unavailable; static smoke only"
fi

echo "PASS stage-17k-z-r11f profile anki preview panel source smoke"
