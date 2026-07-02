#!/usr/bin/env bash
set -euo pipefail

BRIDGE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-merge-preview-bridge.js"
DOC="docs/stage-17k-r13a-backup-merge-preview-bridge-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13a-backup-merge-preview-bridge-source-only"

test -f "$BRIDGE"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE_R13A_SOURCE_ONLY" "$BRIDGE"
grep -Fq "previewMergeBackupText" "$BRIDGE"
grep -Fq "previewMergeBackupFile" "$BRIDGE"
grep -Fq "chooseBackupFileForMergePreview" "$BRIDGE"
grep -Fq "canWrite: false" "$BRIDGE"
grep -Fq "writesEnabled: false" "$BRIDGE"
grep -Fq "overwriteExistingLocalData: false" "$BRIDGE"

grep -Fq "Backup Merge Preview Bridge Source-Only" "$DOC"
grep -Fq "No local Study restore write" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "R13B" "$DOC"

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|indexedDB|localStorage\\.setItem|sessionStorage\\.setItem|showSaveFilePicker|showDirectoryPicker" "$BRIDGE"; then
  echo "FAIL: merge preview bridge contains forbidden IO API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$BRIDGE"
  node - <<'NODE'
(async () => {
  globalThis.APC_LOCAL_SAVE = {
    listDocs: async function listDocs() {
      return [
        { key: "study/cards/v1", value: { cards: [{ id: "card-current", deckId: "deck-current", front: "current", updatedAt: "2026-01-01T00:00:00.000Z" }] } },
        { key: "study/decks/v1", value: { decks: [{ id: "deck-current", title: "Current", updatedAt: "2026-01-01T00:00:00.000Z" }] } },
        { key: "study/progress/v1", value: { totals: { totalCards: 1 } } },
        { key: "study/sessions/v1", value: { recentSessions: [{ id: "session-current", startedAt: "2026-01-01T00:00:00.000Z" }] } },
        { key: "study/store-state/v1", value: { state: { activeDeckId: "deck-current" } } }
      ];
    }
  };

  require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js");
  require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js");
  require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js");
  require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js");
  require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-merge-planner.js");
  const bridge = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-merge-preview-bridge.js");

  const incoming = {
    kind: "buddies-who-study-local-backup",
    version: 2,
    createdAt: "2026-07-02T00:00:00.000Z",
    privacy: {
      serverUpload: false,
      ankiSourceMutation: false,
      sourceMutation: false,
      localOnly: true,
      originalAnkiBytesIncluded: false
    },
    docs: {
      "study/cards/v1": {
        cards: [
          { id: "card-current", deckId: "deck-current", front: "incoming newer", updatedAt: "2026-02-01T00:00:00.000Z" },
          { id: "card-added", deckId: "deck-added", front: "added", updatedAt: "2026-02-01T00:00:00.000Z" }
        ]
      },
      "study/decks/v1": {
        decks: [
          { id: "deck-current", title: "Current newer", updatedAt: "2026-02-01T00:00:00.000Z" },
          { id: "deck-added", title: "Added", updatedAt: "2026-02-01T00:00:00.000Z" }
        ]
      },
      "study/progress/v1": {
        totals: { totalCards: 2 }
      },
      "study/sessions/v1": {
        recentSessions: [
          { id: "session-current", startedAt: "2026-01-01T00:00:00.000Z" },
          { id: "session-added", startedAt: "2026-02-01T00:00:00.000Z" }
        ]
      },
      "study/store-state/v1": {
        state: { activeDeckId: "deck-added" }
      },
      "study/media/v1": {
        items: []
      },
      "study/media-blobs/v1": {
        blobs: []
      },
      "study/card-media-refs/v1": {
        refs: []
      },
      "study/media-manifest/v1": {
        items: []
      },
      "study/anki-media/v1": {
        items: [],
        imports: []
      },
      "study/anki-imports/v1": {
        imports: []
      }
    }
  };

  const preview = await bridge.previewMergeBackupText(JSON.stringify(incoming), {
    explicitUserAction: true,
    createdAt: "2026-07-02T00:00:00.000Z"
  });

  if (!preview.ok) throw new Error("preview should be ok: " + preview.errors.join(", "));
  if (preview.canWrite !== false) throw new Error("canWrite must be false");
  if (preview.writesEnabled !== false) throw new Error("writesEnabled must be false");
  if (preview.writeMode !== "preview-only") throw new Error("writeMode must be preview-only");
  if (!preview.restorePreview) throw new Error("missing restore preview");
  if (!preview.mergePlan) throw new Error("missing merge plan");
  if (preview.mergePlan.cards.addCount !== 1) throw new Error("expected one card add");
  if (preview.mergePlan.cards.updateCount !== 1) throw new Error("expected one card update");
  if (preview.mergePlan.decks.addCount !== 1) throw new Error("expected one deck add");
  if (preview.mergePlan.decks.updateCount !== 1) throw new Error("expected one deck update");
  if (preview.mergePlan.sessions.addCount !== 1) throw new Error("expected one session add");

  const text = bridge.formatMergePreviewText(preview);
  if (!text.includes("Profile backup preview")) throw new Error("missing profile preview heading");
  if (!text.includes("Backup merge preview")) throw new Error("missing merge preview heading");
  if (!bridge.formatMergePreviewHtml(preview).includes("data-apc-local-backup-profile-merge-preview")) {
    throw new Error("missing html marker");
  }

  console.log("PASS node R13A merge preview bridge behavior smoke");
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE
fi

echo "PASS stage-17k-r13a backup merge preview bridge source-only smoke"
