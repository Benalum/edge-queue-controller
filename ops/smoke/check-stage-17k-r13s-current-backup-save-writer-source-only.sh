#!/usr/bin/env bash
set -euo pipefail

HELPER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js"
BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"
SNAPSHOT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"
DOC="docs/stage-17k-r13s-current-backup-save-writer-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13s-current-backup-save-writer-source-only"

test -f "$HELPER"
test -f "$BUILDER"
test -f "$SNAPSHOT"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER_R13S_SOURCE_ONLY" "$HELPER"
grep -Fq "buddies-who-study-current.json" "$HELPER"
grep -Fq "buddies-who-study-current.previous.json" "$HELPER"
grep -Fq "createCurrentBackupSaveWriterPlan" "$HELPER"
grep -Fq "sameFileWriteEnabled: false" "$HELPER"
grep -Fq "currentFileWriteEnabled: false" "$HELPER"
grep -Fq "previousFileWriteEnabled: false" "$HELPER"
grep -Fq "Source-only plan. No file was saved, replaced, merged, restored, or overwritten." "$HELPER"

grep -Fq "Current Backup Save Writer Source-Only" "$DOC"
grep -Fq "No file write" "$DOC"
grep -Fq "No same-file write enablement" "$DOC"
grep -Fq "No current-file save" "$DOC"
grep -Fq "No same-file write path" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$HELPER"; then
  echo "FAIL: helper contains forbidden network/write API"
  exit 1
fi

if grep -Eq "\\.write\\(|\\.close\\(|removeEntry\\(|move\\(|rename\\(" "$HELPER"; then
  echo "FAIL: helper contains file mutation API"
  exit 1
fi

if grep -Eq "FileSystemWritableFileStream|requestPermission\\(|queryPermission\\(" "$HELPER"; then
  echo "FAIL: helper contains file permission/write stream API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$HELPER"
  node --check "$BUILDER"
  node --check "$SNAPSHOT"
  node - <<'NODE'
const builder = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER = builder;
const snapshot = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT = snapshot;
const writer = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js");

const inputPayload = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  privacy: {
    serverUpload: true,
    uploadsToServer: true,
    localOnly: false,
    ankiSourceMutation: true,
    sourceMutation: true
  },
  docs: {
    "study/decks/v1": { decks: [{ id: "deck-1" }, { id: "deck-2" }] },
    "study/cards/v1": { cards: [{ id: "card-1" }, { id: "card-2" }] },
    "study/sessions/v1": { recentSessions: Array.from({ length: 16 }, (_, i) => ({ id: String(i + 1) })) },
    "study/media-manifest/v1": { mediaCount: 0, totalBytes: 0 },
    "study/store-state/v1": {
      state: {
        version: "study-store-v2",
        decks: [],
        cards: [],
        sessions: [],
        runtime: null,
        backendProgress: { ok: true },
        backendReviewSummary: { ok: true },
        backendSessions: { ok: true },
        backendSyncedAt: "2026-07-01T03:04:16.458Z"
      }
    }
  }
};

const plan = writer.createCurrentBackupSaveWriterPlan({
  selectedFileName: "buddies-who-study-current.json",
  payload: inputPayload
}, {
  createdAt: "2026-07-05T23:45:00.000Z"
});

if (plan.canWrite !== false) throw new Error("canWrite must be false");
if (plan.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (plan.sameFileWriteEnabled !== false) throw new Error("sameFileWriteEnabled must be false");
if (plan.currentFileWriteEnabled !== false) throw new Error("currentFileWriteEnabled must be false");
if (plan.previousFileWriteEnabled !== false) throw new Error("previousFileWriteEnabled must be false");
if (plan.selectedFileAllowed !== true) throw new Error("selected current file should be allowed");
if (plan.readyForFutureWriteEnablement !== true) throw new Error("plan should be ready for future enablement");
if (plan.previousFileName !== "buddies-who-study-current.previous.json") throw new Error("wrong previous file");
if (plan.removedFieldCount !== 4) throw new Error("expected 4 removed fields");
if (plan.afterLegacyFieldPaths.length !== 0) throw new Error("sanitized output still has legacy fields");
if (!plan.sanitizedJsonText || !plan.sanitizedJsonText.includes('"serverUpload": false')) throw new Error("sanitized JSON missing privacy");
if (plan.sanitizedJsonText.includes("backendProgress")) throw new Error("sanitized JSON still contains backendProgress");
if (plan.sanitizedJsonText.includes("backendReviewSummary")) throw new Error("sanitized JSON still contains backendReviewSummary");
if (plan.sanitizedJsonText.includes("backendSessions")) throw new Error("sanitized JSON still contains backendSessions");
if (plan.sanitizedJsonText.includes("backendSyncedAt")) throw new Error("sanitized JSON still contains backendSyncedAt");
if (!Object.prototype.hasOwnProperty.call(inputPayload.docs["study/store-state/v1"].state, "backendProgress")) {
  throw new Error("original payload was mutated");
}

const refused = writer.createCurrentBackupSaveWriterPlan({
  selectedFileName: "buddies-who-study-local-backup-v2-2026-07-05T23-33-14-803Z.json",
  payload: inputPayload
}, {
  createdAt: "2026-07-05T23:45:00.000Z"
});

if (refused.selectedFileAllowed !== false) throw new Error("timestamped snapshot should be refused");
if (!refused.errors.some((msg) => msg.includes("selected file is not buddies-who-study-current.json"))) {
  throw new Error("refusal reason missing");
}
if (refused.readyForFutureWriteEnablement !== false) throw new Error("refused plan cannot be ready");

const text = writer.formatCurrentBackupSaveWriterPlanText(plan);
if (!text.includes("Current backup save writer plan")) throw new Error("missing heading");
if (!text.includes("Same-file write enabled: false")) throw new Error("missing safety flag");
if (!text.includes("Legacy backend cache fields removed: 4")) throw new Error("missing removal count");
if (!text.includes("Source-only plan. No file was saved, replaced, merged, restored, or overwritten.")) {
  throw new Error("missing safety text");
}

console.log("PASS node R13S current backup save writer source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r13s current backup save writer source-only smoke"
