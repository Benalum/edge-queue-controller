#!/usr/bin/env bash
set -euo pipefail

BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-restore-preview-bridge.js"
RESTORE="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js"
EXPORTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js"
SCHEMA="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js"
DOC="docs/stage-17k-z-r12u-profile-backup-restore-preview-bridge.md"

test -f "$BRIDGE"
test -f "$RESTORE"
test -f "$EXPORTER"
test -f "$SCHEMA"
test -f "$DOC"

grep -Fq "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE_R12U_SOURCE_ONLY" "$BRIDGE"
grep -Fq "function validateBackupFileLike" "$BRIDGE"
grep -Fq "function previewBackupFile" "$BRIDGE"
grep -Fq "function chooseBackupFileForPreview" "$BRIDGE"
grep -Fq "function formatPreviewText" "$BRIDGE"
grep -Fq "function formatPreviewHtml" "$BRIDGE"
grep -Fq "function createPreviewFromExistingBackupPayload" "$BRIDGE"
grep -Fq "function createPreviewFromEmptyMediaBackup" "$BRIDGE"
grep -Fq "explicit user action" "$BRIDGE"
grep -Fq "root.APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE = api" "$BRIDGE"

for bad in \
  "fetch(" \
  "XMLHttpRequest" \
  "sendBeacon" \
  "localStorage.setItem" \
  "indexedDB" \
  "showDirectoryPicker" \
  "FileReader" \
  "URL.createObjectURL"; do
  if grep -Fq "$bad" "$BRIDGE"; then
    echo "FAIL forbidden side-effect/API reference in Profile restore preview bridge: $bad"
    exit 1
  fi
done

if command -v node >/dev/null 2>&1; then
  node --check "$BRIDGE"
  node - <<'NODE'
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js");
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js");
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js");
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js");
const bridge = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-restore-preview-bridge.js");
if (bridge.marker !== "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE_R12U_SOURCE_ONLY") throw new Error("marker mismatch");
const validFile = {
  name: "backup.json",
  type: "application/json",
  size: 200,
  text: async () => JSON.stringify(globalThis.APC_LOCAL_BACKUP_MEDIA_EXPORT.createEmptyMediaBackupPayload({ createdAt: "2026-07-02T00:00:00.000Z" }))
};
const validation = bridge.validateBackupFileLike(validFile);
if (!validation.ok) throw new Error("valid file rejected");
const badValidation = bridge.validateBackupFileLike({ name: "empty.json", type: "application/json", size: 0, text: async () => "" });
if (badValidation.ok) throw new Error("empty file accepted");
bridge.previewBackupFile(validFile, { explicitUserAction: true }).then((preview) => {
  if (!preview.ok) throw new Error("preview failed: " + preview.errors.join(", "));
  if (preview.canWrite !== false) throw new Error("preview canWrite must be false");
  if (preview.restorePlan.writesEnabled !== false) throw new Error("writesEnabled must be false");
  const text = bridge.formatPreviewText(preview);
  if (!text.includes("Backup preview")) throw new Error("missing preview text title");
  if (!text.includes("Write mode: preview-only")) throw new Error("missing preview-only text");
  const html = bridge.formatPreviewHtml(preview);
  if (!html.includes("data-apc-local-backup-restore-preview-output")) throw new Error("missing preview html marker");
  const emptyPreview = bridge.createPreviewFromEmptyMediaBackup({ createdAt: "2026-07-02T00:00:00.000Z" });
  if (emptyPreview.canWrite !== false) throw new Error("empty preview canWrite must be false");
  console.log("PASS node Profile restore preview bridge behavior smoke");
}).catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE
fi

grep -Fq "Source-only bridge checkpoint" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No index.html loader change" "$DOC"
grep -Fq "No Profile card mutation" "$DOC"
grep -Fq "canWrite false" "$DOC"
grep -Fq "R12V" "$DOC"

echo "PASS stage-17k-z-r12u Profile backup restore preview bridge smoke"
