#!/usr/bin/env bash
set -euo pipefail

PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-plan.js"
DOC="docs/stage-17k-r13i-current-backup-save-plan-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13i-current-backup-save-plan-source-only"

test -f "$PLAN"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN_R13I_SOURCE_ONLY" "$PLAN"
grep -Fq "buddies-who-study-current.json" "$PLAN"
grep -Fq "buddies-who-study-current.previous.json" "$PLAN"
grep -Fq "plan-only" "$PLAN"
grep -Fq "sameFileWriteEnabled: false" "$PLAN"
grep -Fq "createWritableAllowed: false" "$PLAN"
grep -Fq "Plan only. No file was saved, merged, restored, or overwritten." "$PLAN"

grep -Fq "Current Backup Save Plan Source-Only" "$DOC"
grep -Fq "No write path" "$DOC"
grep -Fq "No local Study restore write" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker|createWritable\\(" "$PLAN"; then
  echo "FAIL: save plan contains forbidden network/write API"
  exit 1
fi

if grep -Eq "\\.write\\(|\\.close\\(|removeEntry\\(|move\\(|rename\\(" "$PLAN"; then
  echo "FAIL: save plan contains file mutation API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$PLAN"
  node - <<'NODE'
const planApi = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-plan.js");

const incoming = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  docs: {
    "study/decks/v1": { decks: [{ id: "deck-1" }, { id: "deck-2" }] },
    "study/cards/v1": { cards: [{ id: "card-1" }, { id: "card-2" }] },
    "study/sessions/v1": { recentSessions: Array.from({ length: 16 }, (_, i) => ({ id: String(i + 1) })) },
    "study/media-manifest/v1": { mediaCount: 0, totalBytes: 0 }
  }
};

const current = JSON.parse(JSON.stringify(incoming));

const good = planApi.createSavePlan({
  selectedFileName: "buddies-who-study-current.json",
  incomingPayload: incoming,
  currentPayload: current,
  mergePreview: {
    adds: 0,
    updates: 0,
    skipped: 20,
    conflicts: 0,
    canWrite: false,
    writeMode: "preview-only"
  },
  createdAt: "2026-07-02T01:45:00.000Z"
});

if (good.canWrite !== false) throw new Error("canWrite must be false");
if (good.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (good.sameFileWriteEnabled !== false) throw new Error("sameFileWriteEnabled must be false");
if (good.createWritableAllowed !== false) throw new Error("createWritableAllowed must be false");
if (good.errors.length !== 0) throw new Error("stable current file should not create errors");
if (good.incomingSummary.deckCount !== 2) throw new Error("deck count mismatch");
if (good.incomingSummary.cardCount !== 2) throw new Error("card count mismatch");
if (good.incomingSummary.sessionCount !== 16) throw new Error("session count mismatch");

const text = planApi.formatSavePlanText(good);
if (!text.includes("Current backup save plan")) throw new Error("missing heading");
if (!text.includes("Plan only. No file was saved, merged, restored, or overwritten.")) throw new Error("missing safety line");

const bad = planApi.createSavePlan({
  selectedFileName: "buddies-who-study-local-backup-v2-2026-07-02T01-32-21-912Z.json",
  incomingPayload: incoming,
  currentPayload: current,
  createdAt: "2026-07-02T01:45:00.000Z"
});

if (bad.errors.length < 1) throw new Error("snapshot file should create stable filename error");
if (!bad.errors.join(" ").includes("buddies-who-study-current.json")) {
  throw new Error("missing stable filename error");
}

console.log("PASS node R13I save plan source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r13i current backup save plan source-only smoke"
