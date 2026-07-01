#!/usr/bin/env bash
set -euo pipefail

SRC="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js"
DOC="docs/stage-17k-z-r11b-browser-local-anki-import-skeleton-no-ui.md"
FIXTURE="ops/smoke/fixtures/stage-17k-z-r11b-minimal-apkg-summary.json"

test -f "$SRC"
test -f "$DOC"
test -f "$FIXTURE"

grep -q "APC_ANKI_IMPORT_LOCAL_DISABLED_SKELETON_R11B" "$SRC"
grep -q "APC_ANKI_IMPORT_LOCAL" "$SRC"
grep -q "study/import-sources/v1" "$SRC"
grep -q "study/anki-packages/v1" "$SRC"
grep -q "study/anki-notes/v1" "$SRC"
grep -q "study/anki-cards/v1" "$SRC"
grep -q "study/anki-media/v1" "$SRC"
grep -q "study/import-runs/v1" "$SRC"

grep -q "No deploy" "$DOC"
grep -q "No UI activation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No real apkg parsing activation" "$DOC"

if grep -nE 'fetch[[:space:]]*\(|XMLHttpRequest|sendBeacon|/api/|APC_LOCAL_SAVE[.]write|localStorage[.]setItem|indexedDB[.]open' "$SRC"; then
  echo "FAIL: R11B importer skeleton must not use network, backend routes, or persistence writes"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$SRC"
  node - <<'NODE'
const assert = require("assert");
const fs = require("fs");
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js");
const fixture = JSON.parse(fs.readFileSync("./ops/smoke/fixtures/stage-17k-z-r11b-minimal-apkg-summary.json", "utf8"));

assert.strictEqual(api.marker, "APC_ANKI_IMPORT_LOCAL_DISABLED_SKELETON_R11B");
assert.strictEqual(api.isSupportedFileName("biology.apkg"), true);
assert.strictEqual(api.isSupportedFileName("biology.txt"), false);

const source = api.describeFileSource({
  name: "biology.apkg",
  size: 123456,
  lastModified: 1782880000000
}, {
  createdAt: "2026-07-01T00:00:00.000Z",
  contentSha256: "fixture-package-hash"
});

const validation = api.validatePackageSummary(fixture);
assert.strictEqual(validation.ok, true);

const plan = api.createImportPlan({
  source,
  summary: fixture,
  timestamp: "2026-07-01T00:00:01.000Z"
});

assert.strictEqual(plan.disabledSkeleton, true);
assert.strictEqual(plan.writesOriginalAnki, false);
assert.strictEqual(plan.writesServer, false);
assert.strictEqual(plan.writesLocalDocs, false);

const notes = plan.docs[api.docKeys.ankiNotes].notes;
const cards = plan.docs[api.docKeys.ankiCards].cards;
const media = plan.docs[api.docKeys.ankiMedia].media;
const packages = plan.docs[api.docKeys.ankiPackages].packages;
const runs = plan.docs[api.docKeys.importRuns].runs;

assert.strictEqual(notes.length, 1);
assert.strictEqual(cards.length, 1);
assert.strictEqual(media.length, 1);
assert.strictEqual(packages.length, 1);
assert.strictEqual(runs.length, 1);

assert.strictEqual(notes[0].guid, "r11b-guid-001");
assert.strictEqual(cards[0].ordinal, 0);
assert.strictEqual(cards[0].deckPath, "Biology::Chapter 1");
assert.strictEqual(cards[0].templateName, "Card 1");
assert.strictEqual(media[0].originalFilename, "cell.png");
assert.strictEqual(media[0].contentSha256, "fixture-media-hash");

console.log("PASS node fixture import plan smoke");
NODE
else
  echo "node unavailable; static smoke only"
fi

echo "PASS stage-17k-z-r11b browser-local importer skeleton smoke"
