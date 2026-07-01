#!/usr/bin/env bash
set -euo pipefail

SRC_IMPORT="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js"
SRC_BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js"
DOC="docs/stage-17k-z-r11e-profile-anki-apkg-preview-bridge-no-ui.md"

test -f "$SRC_IMPORT"
test -f "$SRC_BRIDGE"
test -f "$DOC"

grep -q "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" "$SRC_IMPORT"
grep -q "inspectApkgFile" "$SRC_IMPORT"

grep -q "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E" "$SRC_BRIDGE"
grep -q "APC_PROFILE_ANKI_IMPORT_BRIDGE" "$SRC_BRIDGE"
grep -q "createProfileAnkiPreview" "$SRC_BRIDGE"
grep -q "buildPreviewFromInspection" "$SRC_BRIDGE"

grep -q "No deploy" "$DOC"
grep -q "No UI activation" "$DOC"
grep -q "No index.html script mount" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

if grep -nE 'fetch[[:space:]]*\(|XMLHttpRequest|sendBeacon|/api/|APC_LOCAL_SAVE[.]write|localStorage[.]setItem|indexedDB[.]open' "$SRC_BRIDGE"; then
  echo "FAIL: R11E bridge must not use network, backend routes, or persistence writes"
  exit 1
fi

if grep -n "profile-anki-preview-mount.js" frontend/wrapper-ui/apc-wrapper-local/index.html >/tmp/apc-r11g-r11e-superseded-check.txt 2>/dev/null; then
  echo "PASS: R11G source mount supersedes the older r11e no-mount assertion"
elif grep -n "profile-anki-import-bridge.js" frontend/wrapper-ui/apc-wrapper-local/index.html frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html >/tmp/apc-r11e-mounted-check.txt 2>/dev/null; then
  echo "FAIL: R11E bridge must not be mounted before R11G"
  cat /tmp/apc-r11e-mounted-check.txt
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$SRC_IMPORT"
  node --check "$SRC_BRIDGE"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
FIXTURE_APKG="$TMPDIR/r11e-profile-preview.apkg"

python3 - "$FIXTURE_APKG" <<'PY'
import json
import sys
import zipfile
from pathlib import Path

out = Path(sys.argv[1])
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_STORED) as zf:
    zf.writestr("collection.anki2", b"SQLite format 3\x00fixture")
    zf.writestr("media", json.dumps({"0": "cell.png", "1": "diagram.svg"}))
    zf.writestr("0", b"fake-image")
    zf.writestr("1", b"fake-svg")
print(out)
PY

if command -v node >/dev/null 2>&1; then
  node - "$FIXTURE_APKG" <<'NODE'
const assert = require("assert");
const fs = require("fs");

const importer = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js");
const bridge = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js");

const filePath = process.argv[2];
const buffer = fs.readFileSync(filePath);
const arrayBuffer = buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);

const fileLike = {
  name: "r11e-profile-preview.apkg",
  size: buffer.length,
  lastModified: 1782880000000,
  arrayBuffer: async () => arrayBuffer
};

bridge.createProfileAnkiPreview({
  file: fileLike,
  api: importer
}).then((preview) => {
  assert.strictEqual(bridge.marker, "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E");
  assert.strictEqual(preview.marker, "APC_PROFILE_ANKI_IMPORT_BRIDGE_R11E");
  assert.strictEqual(preview.sourceSurface, "profile");
  assert.strictEqual(preview.mode, "apkg-preview-only");
  assert.strictEqual(preview.disabledPreviewOnly, true);
  assert.strictEqual(preview.writesOriginalAnki, false);
  assert.strictEqual(preview.writesServer, false);
  assert.strictEqual(preview.writesLocalDocs, false);
  assert.strictEqual(preview.file.name, "r11e-profile-preview.apkg");
  assert.strictEqual(preview.package.isZip, true);
  assert.strictEqual(preview.package.isApkgContainer, true);
  assert.strictEqual(preview.package.hasCollectionAnki2, true);
  assert.strictEqual(preview.package.hasCollectionAnki21, false);
  assert.strictEqual(preview.package.hasMediaJson, true);
  assert.strictEqual(preview.package.hasTopLevelMediaFiles, true);
  assert.strictEqual(preview.package.numericMediaEntryCount, 2);
  assert.ok(preview.entries.some((entry) => entry.name === "collection.anki2"));
  assert.ok(preview.entries.some((entry) => entry.name === "media"));
  assert.ok(preview.entries.some((entry) => entry.name === "0"));
  assert.ok(preview.entries.some((entry) => entry.name === "1"));
  console.log("PASS node profile anki preview bridge smoke");
}).catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE
else
  echo "node unavailable; static smoke only"
fi

echo "PASS stage-17k-z-r11e profile anki apkg preview bridge smoke"
