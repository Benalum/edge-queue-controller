#!/usr/bin/env bash
set -euo pipefail

ADAPTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js"
SCHEMA="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js"
VAULT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js"
DOC="docs/stage-17k-z-r12s-backup-export-empty-media-docs.md"

test -f "$ADAPTER"
test -f "$SCHEMA"
test -f "$VAULT"
test -f "$DOC"

grep -Fq "APC_LOCAL_BACKUP_MEDIA_EXPORT_R12S_SOURCE_ONLY" "$ADAPTER"
grep -Fq "study/media/v1" "$ADAPTER"
grep -Fq "study/media-blobs/v1" "$ADAPTER"
grep -Fq "study/card-media-refs/v1" "$ADAPTER"
grep -Fq "study/media-manifest/v1" "$ADAPTER"
grep -Fq "study/anki-media/v1" "$ADAPTER"
grep -Fq "study/anki-imports/v1" "$ADAPTER"
grep -Fq "function augmentBackupPayload" "$ADAPTER"
grep -Fq "function createEmptyMediaBackupPayload" "$ADAPTER"
grep -Fq "function validateAugmentedBackup" "$ADAPTER"
grep -Fq "root.APC_LOCAL_BACKUP_MEDIA_EXPORT = api" "$ADAPTER"

for bad in \
  "fetch(" \
  "XMLHttpRequest" \
  "sendBeacon" \
  "localStorage.setItem" \
  "indexedDB" \
  "showDirectoryPicker" \
  "FileReader" \
  "URL.createObjectURL"; do
  if grep -Fq "$bad" "$ADAPTER"; then
    echo "FAIL forbidden side-effect/API reference in backup media export adapter: $bad"
    exit 1
  fi
done

if command -v node >/dev/null 2>&1; then
  node --check "$ADAPTER"
  node - <<'NODE'
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js");
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js");
const adapter = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js");
if (adapter.marker !== "APC_LOCAL_BACKUP_MEDIA_EXPORT_R12S_SOURCE_ONLY") throw new Error("marker mismatch");
const payload = adapter.createEmptyMediaBackupPayload({ createdAt: "2026-07-01T00:00:00.000Z" });
const keys = adapter.mediaDocKeys();
for (const key of keys) {
  if (!payload.docs[key]) throw new Error("missing media doc " + key);
}
if (payload.privacy.serverUpload !== false) throw new Error("serverUpload privacy mismatch");
if (payload.privacy.ankiSourceMutation !== false) throw new Error("anki privacy mismatch");
const validation = adapter.validateAugmentedBackup(payload);
if (!validation.ok) throw new Error("validation failed: " + validation.errors.join(", "));
const augmented = adapter.augmentBackupPayload({
  kind: "buddies-who-study-local-backup",
  version: 1,
  docs: {
    "study/cards/v1": { cards: [] }
  },
  privacy: {
    serverUpload: false,
    ankiSourceMutation: false
  }
}, { createdAt: "2026-07-01T00:00:00.000Z" });
if (!augmented.docs["study/cards/v1"]) throw new Error("lost existing cards doc");
if (!augmented.docs["study/media-manifest/v1"]) throw new Error("missing media manifest after augment");
if (adapter.vaultEnabled() !== false) throw new Error("vault should still be disabled");
console.log("PASS node backup media export adapter behavior smoke");
NODE
fi

grep -Fq "Source-only adapter checkpoint" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No index.html loader change" "$DOC"
grep -Fq "study/media/v1" "$DOC"
grep -Fq "R12T" "$DOC"

echo "PASS stage-17k-z-r12s backup export empty media docs smoke"
