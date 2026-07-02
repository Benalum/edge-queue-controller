#!/usr/bin/env bash
set -euo pipefail

MERGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-merge-planner.js"
DOC="docs/stage-17k-z-r12z-backup-set-merge-planner-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12z-backup-set-merge-planner-source-only"

test -f "$MERGE"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_MERGE_PLANNER_R12Z_SOURCE_ONLY" "$MERGE"
grep -Fq "createMergePlan" "$MERGE"
grep -Fq "writeMode: WRITE_MODE" "$MERGE"
grep -Fq "canWrite: false" "$MERGE"
grep -Fq "writesEnabled: false" "$MERGE"
grep -Fq "overwriteExistingLocalData: false" "$MERGE"
grep -Fq "recompute-from-cards-and-sessions-before-write" "$MERGE"

grep -Fq "Backup-Set Merge Planner Source-Only" "$DOC"
grep -Fq "preview-only" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No frontend deploy" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker" "$MERGE"; then
  echo "FAIL: merge planner contains forbidden IO API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$MERGE"
  node - <<'NODE'
const planner = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-merge-planner.js");

const current = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  docs: {
    "study/decks/v1": {
      decks: [
        { id: "deck-1", title: "Old deck", updatedAt: "2026-01-01T00:00:00.000Z" }
      ]
    },
    "study/cards/v1": {
      cards: [
        { id: "card-1", deckId: "deck-1", front: "old", updatedAt: "2026-01-01T00:00:00.000Z" }
      ]
    },
    "study/sessions/v1": {
      recentSessions: [
        { id: "session-1", startedAt: "2026-01-01T00:00:00.000Z" }
      ]
    },
    "study/media/v1": {
      items: [
        { id: "media-1", sha256: "aaa", updatedAt: "2026-01-01T00:00:00.000Z" }
      ]
    }
  }
};

const incoming = {
  kind: "buddies-who-study-local-backup",
  version: 2,
  docs: {
    "study/decks/v1": {
      decks: [
        { id: "deck-1", title: "New deck", updatedAt: "2026-02-01T00:00:00.000Z" },
        { id: "deck-2", title: "Added deck", updatedAt: "2026-02-01T00:00:00.000Z" }
      ]
    },
    "study/cards/v1": {
      cards: [
        { id: "card-1", deckId: "deck-1", front: "new", updatedAt: "2026-02-01T00:00:00.000Z" },
        { id: "card-2", deckId: "deck-2", front: "added", updatedAt: "2026-02-01T00:00:00.000Z" }
      ]
    },
    "study/sessions/v1": {
      recentSessions: [
        { id: "session-1", startedAt: "2026-01-01T00:00:00.000Z" },
        { id: "session-2", startedAt: "2026-02-01T00:00:00.000Z" }
      ]
    },
    "study/media/v1": {
      items: [
        { id: "media-1", sha256: "aaa", updatedAt: "2026-01-01T00:00:00.000Z" },
        { id: "media-2", sha256: "bbb", updatedAt: "2026-02-01T00:00:00.000Z" }
      ]
    },
    "study/media-manifest/v1": {
      items: []
    },
    "study/card-media-refs/v1": {
      refs: [
        { id: "ref-1", cardId: "card-2", mediaId: "media-2", updatedAt: "2026-02-01T00:00:00.000Z" }
      ]
    },
    "study/anki-imports/v1": {
      imports: [
        { id: "import-1", sourceHash: "hash-1", updatedAt: "2026-02-01T00:00:00.000Z" }
      ]
    }
  }
};

const plan = planner.createMergePlan(current, incoming, { createdAt: "2026-07-02T00:00:00.000Z" });

if (!plan.ok) throw new Error("plan should be ok: " + plan.errors.join(", "));
if (plan.canWrite !== false) throw new Error("plan canWrite must be false");
if (plan.writesEnabled !== false) throw new Error("writesEnabled must be false");
if (plan.writeMode !== "preview-only") throw new Error("writeMode must be preview-only");
if (plan.decks.addCount !== 1) throw new Error("expected one deck add");
if (plan.decks.updateCount !== 1) throw new Error("expected one deck update");
if (plan.cards.addCount !== 1) throw new Error("expected one card add");
if (plan.cards.updateCount !== 1) throw new Error("expected one card update");
if (plan.sessions.addCount !== 1) throw new Error("expected one session add");
if (plan.media.addCount !== 1) throw new Error("expected one media add");
if (plan.cardMediaRefs.addCount !== 1) throw new Error("expected one card media ref add");
if (plan.ankiImports.addCount !== 1) throw new Error("expected one Anki import add");

const text = planner.formatMergePlanText(plan);
if (!text.includes("Backup merge preview")) throw new Error("missing preview text heading");
if (!planner.formatMergePlanHtml(plan).includes("data-apc-local-backup-merge-plan-preview")) {
  throw new Error("missing preview html marker");
}

console.log("PASS node R12Z merge planner behavior smoke");
NODE
fi

echo "PASS stage-17k-z-r12z backup-set merge planner source-only smoke"
