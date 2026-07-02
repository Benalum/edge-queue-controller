#!/usr/bin/env bash
set -euo pipefail

SANITIZER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-legacy-backend-cache-sanitizer.js"
DOC="docs/stage-17k-r13k-legacy-backend-cache-sanitizer-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13k-legacy-backend-cache-sanitizer-source-only"

test -f "$SANITIZER"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_LEGACY_BACKEND_CACHE_SANITIZER_R13K_SOURCE_ONLY" "$SANITIZER"
grep -Fq "backendProgress" "$SANITIZER"
grep -Fq "backendReviewSummary" "$SANITIZER"
grep -Fq "backendSessions" "$SANITIZER"
grep -Fq "backendSyncedAt" "$SANITIZER"
grep -Fq "Preview only. No data was saved, restored, merged, or overwritten." "$SANITIZER"

grep -Fq "Legacy Backend Cache Sanitizer Source-Only" "$DOC"
grep -Fq "No write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$SANITIZER"; then
  echo "FAIL: sanitizer contains forbidden network/write API"
  exit 1
fi

if grep -Eq "\\.write\\(|\\.close\\(|removeEntry\\(|move\\(|rename\\(" "$SANITIZER"; then
  echo "FAIL: sanitizer contains file mutation API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$SANITIZER"
  node - <<'NODE'
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-legacy-backend-cache-sanitizer.js");

const input = {
  docs: {
    "study/store-state/v1": {
      schemaVersion: 1,
      updatedAt: "2026-07-01T03:27:19.842Z",
      state: {
        version: "study-store-v2",
        decks: [{ id: "deck-1" }],
        cards: [{ id: "card-1" }],
        sessions: [{ id: "session-1" }],
        backendProgress: { ok: true },
        backendReviewSummary: { ok: true },
        backendSessions: { ok: true },
        backendSyncedAt: "2026-07-01T03:04:16.458Z"
      }
    }
  }
};

const found = api.findLegacyBackendCacheFields(input);
if (found.legacyFieldCount !== 4) throw new Error("expected 4 legacy fields");

const preview = api.createBackupSanitizationPreview(input, {
  updatedAt: "2026-07-02T02:30:00.000Z"
});

if (preview.canWrite !== false) throw new Error("canWrite must be false");
if (preview.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (preview.sameFileWriteEnabled !== false) throw new Error("sameFileWriteEnabled must be false");
if (preview.legacyFieldCount !== 4) throw new Error("preview expected 4 legacy fields");

const sanitizedState = preview.sanitizedStoreStateDoc.state;
for (const key of api.LEGACY_BACKEND_CACHE_KEYS) {
  if (Object.prototype.hasOwnProperty.call(sanitizedState, key)) {
    throw new Error("sanitized preview still contains " + key);
  }
  if (!Object.prototype.hasOwnProperty.call(input.docs["study/store-state/v1"].state, key)) {
    throw new Error("original input was mutated for " + key);
  }
}

const text = api.formatSanitizationPreviewText(preview);
if (!text.includes("Legacy backend cache sanitizer")) throw new Error("missing heading");
if (!text.includes("Legacy fields found: 4")) throw new Error("missing field count");
if (!text.includes("Preview only. No data was saved, restored, merged, or overwritten.")) throw new Error("missing safety text");

console.log("PASS node R13K sanitizer source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r13k legacy backend cache sanitizer source-only smoke"
