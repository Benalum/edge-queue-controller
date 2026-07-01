#!/usr/bin/env bash
set -euo pipefail

SRC="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js"
DOC="docs/stage-17k-z-r11c-browser-local-apkg-container-inspector-no-extract.md"

test -f "$SRC"
test -f "$DOC"

grep -q "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C" "$SRC"
grep -q "inspectZipContainer" "$SRC"
grep -q "inspectApkgContainer" "$SRC"
grep -q "inspectApkgFile" "$SRC"

grep -q "No deploy" "$DOC"
grep -q "No UI activation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

if grep -nE 'fetch[[:space:]]*\(|XMLHttpRequest|sendBeacon|/api/|APC_LOCAL_SAVE[.]write|localStorage[.]setItem|indexedDB[.]open' "$SRC"; then
  echo "FAIL: R11C inspector must not use network, backend routes, or persistence writes"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$SRC"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
FIXTURE_APKG="$TMPDIR/r11c-minimal.apkg"

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
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js");

const filePath = process.argv[2];
const buffer = fs.readFileSync(filePath);
const arrayBuffer = buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);

assert.strictEqual(api.apkgInspectorMarker, "APC_ANKI_IMPORT_LOCAL_APKG_CONTAINER_INSPECTOR_R11C");

const container = api.inspectApkgContainer(arrayBuffer, "r11c-minimal.apkg");

assert.strictEqual(container.isZip, true);
assert.strictEqual(container.isApkgContainer, true);
assert.strictEqual(container.hasCollectionAnki2, true);
assert.strictEqual(container.hasMediaJson, true);
assert.strictEqual(container.hasTopLevelMediaFiles, true);
assert.ok(container.entryCount >= 3);

const names = container.entries.map((entry) => entry.name).sort();
assert.ok(names.includes("collection.anki2"));
assert.ok(names.includes("media"));
assert.ok(names.includes("0"));

const fileLike = {
  name: "r11c-minimal.apkg",
  size: buffer.length,
  lastModified: 1782880000000,
  arrayBuffer: async () => arrayBuffer
};

api.inspectApkgFile(fileLike).then((result) => {
  assert.strictEqual(result.disabledInspectorOnly, true);
  assert.strictEqual(result.writesOriginalAnki, false);
  assert.strictEqual(result.writesServer, false);
  assert.strictEqual(result.writesLocalDocs, false);
  assert.strictEqual(result.container.isApkgContainer, true);
  console.log("PASS node apkg container inspector smoke");
}).catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE
else
  echo "node unavailable; static smoke only"
fi

echo "PASS stage-17k-z-r11c browser-local apkg container inspector smoke"
