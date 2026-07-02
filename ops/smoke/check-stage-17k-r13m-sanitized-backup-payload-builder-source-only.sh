#!/usr/bin/env bash
set -euo pipefail

BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"
DOC="docs/stage-17k-r13m-sanitized-backup-payload-builder-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13m-sanitized-backup-payload-builder-source-only"

test -f "$BUILDER"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER_R13M_SOURCE_ONLY" "$BUILDER"
grep -Fq "backendProgress" "$BUILDER"
grep -Fq "backendReviewSummary" "$BUILDER"
grep -Fq "backendSessions" "$BUILDER"
grep -Fq "backendSyncedAt" "$BUILDER"
grep -Fq "Preview only. No data was saved, restored, merged, or overwritten." "$BUILDER"

grep -Fq "Sanitized Backup Payload Builder Source-Only" "$DOC"
grep -Fq "No write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$BUILDER"; then
  echo "FAIL: builder contains forbidden network/write API"
  exit 1
fi

if grep -Eq "\\.write\\(|\\.close\\(|removeEntry\\(|move\\(|rename\\(" "$BUILDER"; then
  echo "FAIL: builder contains file mutation API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$BUILDER"
  node - <<'NODE'
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js");

const input = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  privacy: {
    serverUpload: true,
    uploadsToServer: true,
    ankiSourceMutation: true,
    sourceMutation: true,
    localOnly: false,
    originalAnkiBytesIncluded: true
  },
  docs: {
    "study/decks/v1": { decks: [{ id: "deck-1" }, { id: "deck-2" }] },
    "study/cards/v1": { cards: [{ id: "card-1" }, { id: "card-2" }] },
    "study/sessions/v1": { recentSessions: Array.from({ length: 16 }, (_, i) => ({ id: String(i + 1) })) },
    "study/media-manifest/v1": { mediaCount: 0, totalBytes: 0 },
    "study/store-state/v1": {
      schemaVersion: 1,
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

const preview = api.createSanitizedBackupPayloadPreview(input, {
  updatedAt: "2026-07-02T03:00:00.000Z"
});

if (preview.canWrite !== false) throw new Error("canWrite must be false");
if (preview.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (preview.sameFileWriteEnabled !== false) throw new Error("sameFileWriteEnabled must be false");
if (preview.removedFieldCount !== 4) throw new Error("expected 4 removed fields");
if (preview.afterSummary.deckCount !== 2) throw new Error("deck count mismatch");
if (preview.afterSummary.cardCount !== 2) throw new Error("card count mismatch");
if (preview.afterSummary.sessionCount !== 16) throw new Error("session count mismatch");

const sanitized = preview.sanitizedPayload;
const sanitizedState = sanitized.docs["study/store-state/v1"].state;

for (const key of api.LEGACY_BACKEND_CACHE_KEYS) {
  if (Object.prototype.hasOwnProperty.call(sanitizedState, key)) {
    throw new Error("sanitized payload still contains " + key);
  }
  if (!Object.prototype.hasOwnProperty.call(input.docs["study/store-state/v1"].state, key)) {
    throw new Error("original input was mutated for " + key);
  }
}

if (sanitized.privacy.serverUpload !== false) throw new Error("privacy serverUpload not forced false");
if (sanitized.privacy.uploadsToServer !== false) throw new Error("privacy uploadsToServer not forced false");
if (sanitized.privacy.ankiSourceMutation !== false) throw new Error("privacy ankiSourceMutation not forced false");
if (sanitized.privacy.localOnly !== true) throw new Error("privacy localOnly not forced true");

const text = api.formatSanitizedBackupPayloadPreviewText(preview);
if (!text.includes("Sanitized backup payload preview")) throw new Error("missing heading");
if (!text.includes("Legacy fields removed from sanitized payload: 4")) throw new Error("missing removed count");
if (!text.includes("Preview only. No data was saved, restored, merged, or overwritten.")) throw new Error("missing safety text");

console.log("PASS node R13M sanitized payload builder source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r13m sanitized backup payload builder source-only smoke"
