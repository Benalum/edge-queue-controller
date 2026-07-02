#!/usr/bin/env bash
set -euo pipefail

RESTORE="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js"
EXPORTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js"
SCHEMA="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js"
DOC="docs/stage-17k-z-r12t-backup-restore-preview-helper.md"

test -f "$RESTORE"
test -f "$EXPORTER"
test -f "$SCHEMA"
test -f "$DOC"

grep -Fq "APC_LOCAL_BACKUP_RESTORE_PREVIEW_R12T_SOURCE_ONLY" "$RESTORE"
grep -Fq "function parseBackupText" "$RESTORE"
grep -Fq "function createRestorePreview" "$RESTORE"
grep -Fq "function previewBackupText" "$RESTORE"
grep -Fq "function assertPreviewOnly" "$RESTORE"
grep -Fq "function summarizeStudyDocs" "$RESTORE"
grep -Fq "function summarizeMediaDocs" "$RESTORE"
grep -Fq "canWrite: false" "$RESTORE"
grep -Fq "writesEnabled: false" "$RESTORE"
grep -Fq "writeMode: \"preview-only\"" "$RESTORE"
grep -Fq "root.APC_LOCAL_BACKUP_RESTORE_PREVIEW = api" "$RESTORE"

for bad in \
  "fetch(" \
  "XMLHttpRequest" \
  "sendBeacon" \
  "localStorage.setItem" \
  "indexedDB" \
  "showDirectoryPicker" \
  "FileReader" \
  "URL.createObjectURL"; do
  if grep -Fq "$bad" "$RESTORE"; then
    echo "FAIL forbidden side-effect/API reference in restore preview helper: $bad"
    exit 1
  fi
done

if command -v node >/dev/null 2>&1; then
  node --check "$RESTORE"
  node - <<'NODE'
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js");
require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js");
const exporter = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js");
const restore = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js");
if (restore.marker !== "APC_LOCAL_BACKUP_RESTORE_PREVIEW_R12T_SOURCE_ONLY") throw new Error("marker mismatch");
const payload = exporter.createEmptyMediaBackupPayload({ createdAt: "2026-07-02T00:00:00.000Z" });
payload.docs["study/cards/v1"] = { cards: [{ id: "c1" }] };
payload.docs["study/decks/v1"] = { decks: [{ id: "d1" }] };
payload.docs["study/progress/v1"] = { progress: [] };
payload.docs["study/sessions/v1"] = { sessions: [] };
payload.docs["study/store-state/v1"] = { state: {} };
const preview = restore.createRestorePreview(payload);
if (!preview.ok) throw new Error("preview should be ok: " + preview.errors.join(", "));
if (preview.canWrite !== false) throw new Error("preview canWrite must be false");
if (preview.restorePlan.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (preview.summary.study.cards !== 1) throw new Error("card summary failed");
if (preview.summary.study.decks !== 1) throw new Error("deck summary failed");
if (!preview.mediaDocKeys.includes("study/media-manifest/v1")) throw new Error("missing media doc key");
restore.assertPreviewOnly(preview);
const textPreview = restore.previewBackupText(JSON.stringify(payload));
if (!textPreview.ok) throw new Error("text preview failed");
const bad = restore.previewBackupText("{bad json");
if (bad.ok) throw new Error("bad json should fail");
if (bad.canWrite !== false) throw new Error("bad preview canWrite must be false");
console.log("PASS node restore preview behavior smoke");
NODE
fi

grep -Fq "Source-only helper checkpoint" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No index.html loader change" "$DOC"
grep -Fq "canWrite false" "$DOC"
grep -Fq "preview-only" "$DOC"
grep -Fq "R12U" "$DOC"

echo "PASS stage-17k-z-r12t backup restore preview helper smoke"
