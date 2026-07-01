#!/usr/bin/env bash
set -euo pipefail

SCHEMA="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js"
DOC="docs/stage-17k-z-r12q-backup-media-manifest-schema.md"

test -f "$SCHEMA"
test -f "$DOC"

grep -Fq "APC_LOCAL_BACKUP_MEDIA_SCHEMA_R12Q" "$SCHEMA"
grep -Fq "study/media/v1" "$SCHEMA"
grep -Fq "study/media-blobs/v1" "$SCHEMA"
grep -Fq "study/card-media-refs/v1" "$SCHEMA"
grep -Fq "study/media-manifest/v1" "$SCHEMA"
grep -Fq "study/anki-media/v1" "$SCHEMA"
grep -Fq "study/anki-imports/v1" "$SCHEMA"
grep -Fq "function createBackupManifest" "$SCHEMA"
grep -Fq "function createEmptyMediaManifest" "$SCHEMA"
grep -Fq "function createEmptyCardMediaRefs" "$SCHEMA"
grep -Fq "function normalizeMediaItem" "$SCHEMA"
grep -Fq "function normalizeCardMediaRef" "$SCHEMA"
grep -Fq "function validateBackupEnvelope" "$SCHEMA"
grep -Fq "function validateMediaManifest" "$SCHEMA"
grep -Fq "function validateCardMediaRefs" "$SCHEMA"
grep -Fq "serverUpload: false" "$SCHEMA"
grep -Fq "ankiSourceMutation: false" "$SCHEMA"

for bad in \
  "fetch(" \
  "XMLHttpRequest" \
  "sendBeacon" \
  "localStorage.setItem" \
  "indexedDB" \
  "showDirectoryPicker" \
  "FileReader" \
  "URL.createObjectURL"; do
  if grep -Fq "$bad" "$SCHEMA"; then
    echo "FAIL forbidden side-effect/API reference in schema helper: $bad"
    exit 1
  fi
done

if command -v node >/dev/null 2>&1; then
  node --check "$SCHEMA"
  node - <<'NODE'
const schema = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js");
if (schema.marker !== "APC_LOCAL_BACKUP_MEDIA_SCHEMA_R12Q") throw new Error("marker mismatch");
if (!schema.mediaDocKeys.includes("study/media/v1")) throw new Error("missing media doc");
if (!schema.mediaDocKeys.includes("study/card-media-refs/v1")) throw new Error("missing refs doc");
const manifest = schema.createBackupManifest({ mediaCount: 0, totalMediaBytes: 0 });
if (manifest.privacy.serverUpload !== false) throw new Error("serverUpload privacy mismatch");
if (manifest.privacy.ankiSourceMutation !== false) throw new Error("anki mutation privacy mismatch");
const media = schema.createEmptyMediaManifest();
if (!schema.validateMediaManifest(media).ok) throw new Error("media manifest validation failed");
const refs = schema.createEmptyCardMediaRefs();
if (!schema.validateCardMediaRefs(refs).ok) throw new Error("card media refs validation failed");
const item = schema.normalizeMediaItem({ originalFilename: "bad/name.png", mimeType: "image/png" });
if (item.kind !== "image") throw new Error("mime classification failed");
if (item.safeFilename.indexOf("/") !== -1) throw new Error("safe filename failed");
console.log("PASS node schema behavior smoke");
NODE
fi

grep -Fq "Source-only schema checkpoint" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No UI mount" "$DOC"
grep -Fq "local-backup-media-schema.js" "$DOC"
grep -Fq "serverUpload false" "$DOC"
grep -Fq "R12R" "$DOC"

echo "PASS stage-17k-z-r12q backup media manifest schema smoke"
