#!/usr/bin/env bash
set -euo pipefail

ADAPTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-access.js"
DOC="docs/stage-17k-r13f-current-backup-file-access-adapter-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13f-current-backup-file-access-adapter-source-only"

test -f "$ADAPTER"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS_ADAPTER_R13F_SOURCE_ONLY" "$ADAPTER"
grep -Fq "buddies-who-study-current.json" "$ADAPTER"
grep -Fq "read-and-preview-only" "$ADAPTER"
grep -Fq "canWrite: false" "$ADAPTER"
grep -Fq "writesEnabled: false" "$ADAPTER"
grep -Fq "No data was restored." "$ADAPTER"
grep -Fq "No file was overwritten." "$ADAPTER"

grep -Fq "Current Backup File Access Adapter Source-Only" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "R13G" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$ADAPTER"; then
  echo "FAIL: current file adapter contains forbidden network/write API"
  exit 1
fi

if grep -Eq "saveCurrent|writeCurrent|mergeCurrent|restoreCurrent|overwriteCurrent|createWritable|\\.write\\(" "$ADAPTER"; then
  echo "FAIL: current file adapter exposes write-like function"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$ADAPTER"
  node - <<'NODE'
globalThis.APC_LOCAL_BACKUP_STABLE_FILE_PLAN = {
  classifyBackupFileName: function classifyBackupFileName(name) {
    if (name === "buddies-who-study-current.json") {
      return {
        fileName: name,
        role: "stable-current",
        canBeMainMergeFile: true,
        shouldCreateNewSnapshot: false,
        recommendation: "stable"
      };
    }
    if (String(name || "").startsWith("buddies-who-study-local-backup-v2-")) {
      return {
        fileName: name,
        role: "manual-snapshot",
        canBeMainMergeFile: false,
        shouldCreateNewSnapshot: false,
        recommendation: "snapshot"
      };
    }
    return {
      fileName: name,
      role: "unknown-json",
      canBeMainMergeFile: false,
      shouldCreateNewSnapshot: true,
      recommendation: "unknown"
    };
  }
};

globalThis.APC_LOCAL_BACKUP_RESTORE_PREVIEW = {
  createRestorePreview: function createRestorePreview() {
    return {
      ok: true,
      canWrite: false,
      writesEnabled: false,
      writeMode: "preview-only",
      warnings: [],
      errors: []
    };
  }
};

const adapter = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-access.js");

if (adapter.CURRENT_FILE_NAME !== "buddies-who-study-current.json") {
  throw new Error("current filename mismatch");
}

const stable = adapter.classifyFileName("buddies-who-study-current.json");
if (stable.role !== "stable-current") throw new Error("stable current role mismatch");

const snapshot = adapter.classifyFileName("buddies-who-study-local-backup-v2-2026-07-02T01-24-27-180Z.json");
if (snapshot.role !== "manual-snapshot") throw new Error("snapshot role mismatch");

const payload = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  createdAt: "2026-07-02T01:24:27.180Z",
  docs: {
    "study/cards/v1": { cards: [{ id: "card-1" }, { id: "card-2" }] },
    "study/decks/v1": { decks: [{ id: "deck-1" }] },
    "study/progress/v1": { totals: { totalCards: 2 } },
    "study/sessions/v1": { recentSessions: [{ id: "session-1" }] },
    "study/store-state/v1": { state: {} },
    "study/media/v1": { items: [] },
    "study/media-blobs/v1": { blobs: [] },
    "study/card-media-refs/v1": { refs: [] },
    "study/media-manifest/v1": { mediaCount: 0, totalBytes: 0, items: [] }
  }
};

const result = adapter.createCurrentFileReadResult(
  "buddies-who-study-current.json",
  JSON.stringify(payload),
  { createdAt: "2026-07-02T01:24:27.180Z" }
);

if (result.canWrite !== false) throw new Error("canWrite must be false");
if (result.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (result.summary.cardCount !== 2) throw new Error("card count mismatch");
if (result.summary.deckCount !== 1) throw new Error("deck count mismatch");
if (result.summary.sessionCount !== 1) throw new Error("session count mismatch");
if (result.summary.hasMediaDocs !== true) throw new Error("media docs not detected");

const text = adapter.formatReadResultText(result);
if (!text.includes("Current backup file preview")) throw new Error("missing heading");
if (!text.includes("No data was restored.")) throw new Error("missing no restore text");
if (!text.includes("No file was overwritten.")) throw new Error("missing no overwrite text");

const html = adapter.formatReadResultHtml(result);
if (!html.includes("data-apc-local-backup-current-file-read-preview")) {
  throw new Error("missing html marker");
}

console.log("PASS node R13F current backup file access adapter behavior smoke");
NODE
fi

echo "PASS stage-17k-r13f current backup file access adapter source-only smoke"
