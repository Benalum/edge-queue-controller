#!/usr/bin/env bash
set -euo pipefail

HELPER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"
BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"
DOC="docs/stage-17k-r13o-sanitized-snapshot-output-helper-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13o-sanitized-snapshot-output-helper-source-only"

test -f "$HELPER"
test -f "$BUILDER"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT_HELPER_R13O_SOURCE_ONLY" "$HELPER"
grep -Fq "prepareSanitizedSnapshotOutput" "$HELPER"
grep -Fq "buddies-who-study-local-backup-v2-" "$HELPER"
grep -Fq "Prepare only. No file download was started by this helper." "$HELPER"

grep -Fq "Sanitized Snapshot Output Helper Source-Only" "$DOC"
grep -Fq "No browser download action" "$DOC"
grep -Fq "No same-file write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$HELPER"; then
  echo "FAIL: helper contains forbidden network/write API"
  exit 1
fi

if grep -Eq "\\.write\\(|\\.close\\(|removeEntry\\(|move\\(|rename\\(" "$HELPER"; then
  echo "FAIL: helper contains file mutation API"
  exit 1
fi

if grep -Eq "Blob\\(|URL\\.createObjectURL|download\\s*=" "$HELPER"; then
  echo "FAIL: helper should prepare output only, not start browser download"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$HELPER"
  node --check "$BUILDER"
  node - <<'NODE'
const builder = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER = builder;
const helper = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js");

const input = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  privacy: {
    serverUpload: true,
    uploadsToServer: true,
    localOnly: false,
    ankiSourceMutation: true
  },
  docs: {
    "study/decks/v1": { decks: [{ id: "deck-1" }, { id: "deck-2" }] },
    "study/cards/v1": { cards: [{ id: "card-1" }, { id: "card-2" }] },
    "study/sessions/v1": { recentSessions: Array.from({ length: 16 }, (_, i) => ({ id: String(i + 1) })) },
    "study/media-manifest/v1": { mediaCount: 0, totalBytes: 0 },
    "study/store-state/v1": {
      state: {
        decks: [],
        cards: [],
        sessions: [],
        backendProgress: { ok: true },
        backendReviewSummary: { ok: true },
        backendSessions: { ok: true },
        backendSyncedAt: "2026-07-01T03:04:16.458Z"
      }
    }
  }
};

const result = helper.prepareSanitizedSnapshotOutput(input, {
  createdAt: "2026-07-02T03:15:00.000Z",
  updatedAt: "2026-07-02T03:15:00.000Z"
});

if (result.canWrite !== false) throw new Error("canWrite must be false");
if (result.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (result.sameFileWriteEnabled !== false) throw new Error("sameFileWriteEnabled must be false");
if (result.downloadPrepared !== true) throw new Error("downloadPrepared should be true");
if (result.fileName !== "buddies-who-study-local-backup-v2-2026-07-02T03-15-00-000Z.json") {
  throw new Error("unexpected filename: " + result.fileName);
}
if (result.removedFieldCount !== 4) throw new Error("expected 4 removed fields");
if (!result.jsonText.includes('"serverUpload": false')) throw new Error("privacy was not sanitized");
if (result.jsonText.includes("backendProgress")) throw new Error("jsonText still contains backendProgress");
if (result.jsonText.includes("backendReviewSummary")) throw new Error("jsonText still contains backendReviewSummary");
if (result.jsonText.includes("backendSessions")) throw new Error("jsonText still contains backendSessions");
if (result.jsonText.includes("backendSyncedAt")) throw new Error("jsonText still contains backendSyncedAt");
if (!Object.prototype.hasOwnProperty.call(input.docs["study/store-state/v1"].state, "backendProgress")) {
  throw new Error("original input was mutated");
}

const text = helper.formatSanitizedSnapshotOutputText(result);
if (!text.includes("Sanitized snapshot output")) throw new Error("missing heading");
if (!text.includes("Legacy fields removed: 4")) throw new Error("missing removal count");
if (!text.includes("Prepare only. No file download was started by this helper.")) throw new Error("missing safety text");

console.log("PASS node R13O sanitized snapshot output source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r13o sanitized snapshot output helper source-only smoke"
