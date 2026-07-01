#!/usr/bin/env bash
set -euo pipefail

VAULT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js"
SCHEMA="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js"
DOC="docs/stage-17k-z-r12r-disabled-local-media-vault-helper.md"

test -f "$VAULT"
test -f "$SCHEMA"
test -f "$DOC"

grep -Fq "APC_LOCAL_MEDIA_VAULT_R12R_DISABLED_SOURCE_ONLY" "$VAULT"
grep -Fq "enabled: ENABLED" "$VAULT"
grep -Fq "function validateMediaFile" "$VAULT"
grep -Fq "function buildMediaId" "$VAULT"
grep -Fq "function digestBlobSha256" "$VAULT"
grep -Fq "function createImageMediaRecordFromFile" "$VAULT"
grep -Fq "function createCardMediaRef" "$VAULT"
grep -Fq "function createEmptyVaultState" "$VAULT"
grep -Fq "function addMediaRecordToManifest" "$VAULT"
grep -Fq "function addCardMediaRef" "$VAULT"
grep -Fq "R12R local media vault is source-only" "$VAULT"
grep -Fq "root.APC_LOCAL_MEDIA_VAULT = api" "$VAULT"

for bad in \
  "fetch(" \
  "XMLHttpRequest" \
  "sendBeacon" \
  "localStorage.setItem" \
  "indexedDB" \
  "showDirectoryPicker" \
  "FileReader" \
  "URL.createObjectURL"; do
  if grep -Fq "$bad" "$VAULT"; then
    echo "FAIL forbidden side-effect/API reference in disabled vault helper: $bad"
    exit 1
  fi
done

if command -v node >/dev/null 2>&1; then
  node --check "$VAULT"
  node - <<'NODE'
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js");
const vault = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js");
if (vault.marker !== "APC_LOCAL_MEDIA_VAULT_R12R_DISABLED_SOURCE_ONLY") throw new Error("marker mismatch");
if (vault.enabled !== false) throw new Error("vault should be disabled");
const ok = vault.validateMediaFile({ name: "cat.png", type: "image/png", size: 1000 });
if (!ok.ok) throw new Error("valid image rejected");
const bad = vault.validateMediaFile({ name: "notes.txt", type: "text/plain", size: 1000 });
if (bad.ok) throw new Error("text file accepted as image");
const tooBig = vault.validateMediaFile({ name: "large.png", type: "image/png", size: vault.defaultMaxBytes + 1 });
if (tooBig.ok) throw new Error("oversize file accepted");
const id = vault.buildMediaId({ sha256: "abc123", originalFilename: "cat.png", sizeBytes: 1000 });
if (id !== "media-sha256-abc123") throw new Error("media id mismatch");
const state = vault.createEmptyVaultState({ createdAt: "2026-07-01T00:00:00.000Z" });
if (!state.mediaManifest || !Array.isArray(state.mediaManifest.items)) throw new Error("missing media manifest");
if (!state.cardMediaRefs || !Array.isArray(state.cardMediaRefs.refs)) throw new Error("missing card refs");
const nextManifest = vault.addMediaRecordToManifest(state.mediaManifest, {
  id: "m1",
  originalFilename: "bad/name.png",
  mimeType: "image/png",
  sizeBytes: 12
});
if (nextManifest.mediaCount !== 1) throw new Error("media manifest append failed");
const nextRefs = vault.addCardMediaRef(state.cardMediaRefs, {
  mediaId: "m1",
  cardId: "c1",
  slot: "front",
  order: 0
});
if (nextRefs.refs.length !== 1) throw new Error("card media ref append failed");
vault.storeMediaBlob().then(
  () => { throw new Error("storeMediaBlob should reject"); },
  () => console.log("PASS node vault behavior smoke")
);
NODE
fi

grep -Fq "Source-only helper checkpoint" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No UI mount" "$DOC"
grep -Fq "No media blob persistence" "$DOC"
grep -Fq "storeMediaBlob" "$DOC"
grep -Fq "R12S" "$DOC"

echo "PASS stage-17k-z-r12r disabled local media vault helper smoke"
