#!/usr/bin/env bash
set -euo pipefail

CONTROLLER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-action-controller.js"
EXECUTOR="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js"
WRITER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js"
BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"
SNAPSHOT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-r14d-save-action-controller-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14d-save-action-controller-source-only"

test -f "$CONTROLLER"
test -f "$EXECUTOR"
test -f "$WRITER"
test -f "$BUILDER"
test -f "$SNAPSHOT"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY" "$CONTROLLER"
grep -Fq "createSaveCurrentBackupActionState" "$CONTROLLER"
grep -Fq "createDisabledActionViewModel" "$CONTROLLER"
grep -Fq "executorCallAllowedNow: false" "$CONTROLLER"
grep -Fq "executorCalled: false" "$CONTROLLER"
grep -Fq "writesEnabledNow: false" "$CONTROLLER"
grep -Fq "canWriteNow: false" "$CONTROLLER"
grep -Fq "requiresLaterDeployStage: true" "$CONTROLLER"
grep -Fq "buddies-who-study-current.json" "$CONTROLLER"
grep -Fq "buddies-who-study-current.previous.json" "$CONTROLLER"
grep -Fq "R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE" "$CONTROLLER"

grep -Fq "Save Action Controller Source-Only" "$DOC"
grep -Fq "No deploy" "$DOC"
grep -Fq "No live UI change" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No file write" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

if grep -Fq "/privatepages/local-backup-current-file-save-action-controller.js" "$INDEX"; then
  echo "FAIL: action controller must not be loaded by index.html"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER" "$MOUNT" "$PANEL"; then
  echo "FAIL: action controller must not be referenced by live mount/panel"
  exit 1
fi

if grep -Fq ".executeCurrentBackupWrite(" "$CONTROLLER"; then
  echo "FAIL: action controller must not call executor write function"
  exit 1
fi

if grep -Eq "createWritable\\(|\\.write\\(|\\.close\\(|showSaveFilePicker|showDirectoryPicker" "$CONTROLLER"; then
  echo "FAIL: action controller must not contain write picker/stream code"
  exit 1
fi

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|localStorage\\.setItem|sessionStorage\\.setItem|indexedDB" "$CONTROLLER"; then
  echo "FAIL: action controller contains forbidden network/storage API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$CONTROLLER"
  node --check "$EXECUTOR"
  node --check "$WRITER"
  node --check "$BUILDER"
  node --check "$SNAPSHOT"
  node - <<'NODE'
const builder = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER = builder;

const snapshot = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js");
globalThis.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT = snapshot;

const writer = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js");
globalThis.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER = writer;

const executor = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js");
globalThis.APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR = executor;

const controller = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-action-controller.js");

const directoryHandle = {
  getFileHandle: async () => ({ name: "buddies-who-study-current.previous.json" })
};

const currentFileHandle = {
  name: "buddies-who-study-current.json"
};

const payload = {
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
        activeDeckId: "deck-1",
        decks: [],
        cards: [],
        sessions: [],
        runtime: null,
        backendProgress: { legacy: true },
        backendReviewSummary: { legacy: true },
        backendSessions: { legacy: true },
        backendSyncedAt: "2026-07-01T03:04:16.458Z"
      }
    }
  }
};

const state = controller.createSaveCurrentBackupActionState({
  selectedFileName: "buddies-who-study-current.json",
  currentFileHandle,
  directoryHandle,
  payload
}, {
  createdAt: "2026-07-06T00:30:00.000Z"
});

if (state.marker !== "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY") throw new Error("marker mismatch");
if (state.sourceOnly !== true) throw new Error("sourceOnly should be true");
if (state.deployed !== false) throw new Error("deployed should be false");
if (state.uiLoaded !== false) throw new Error("uiLoaded should be false");
if (state.uiButtonAdded !== false) throw new Error("uiButtonAdded should be false");
if (state.actionBoundToUi !== false) throw new Error("actionBoundToUi should be false");
if (state.executorCallAllowedNow !== false) throw new Error("executorCallAllowedNow should be false");
if (state.executorCalled !== false) throw new Error("executorCalled should be false");
if (state.writesEnabledNow !== false) throw new Error("writesEnabledNow should be false");
if (state.canWriteNow !== false) throw new Error("canWriteNow should be false");
if (state.requiresLaterDeployStage !== true) throw new Error("requiresLaterDeployStage should be true");
if (state.selectedFileAllowed !== true) throw new Error("selectedFileAllowed should be true");
if (state.currentFileHandleAllowed !== true) throw new Error("currentFileHandleAllowed should be true");
if (state.directoryHandlePresent !== true) throw new Error("directoryHandlePresent should be true");
if (state.sanitizedPlanReady !== true) throw new Error("sanitizedPlanReady should be true");
if (state.removedFieldCount !== 4) throw new Error("removedFieldCount should be 4");
if (state.afterLegacyFieldPaths.length !== 0) throw new Error("afterLegacyFieldPaths should be empty");
if (state.executorLoaded !== true) throw new Error("executorLoaded should be true");
if (state.executorMarker !== "APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY") throw new Error("executorMarker mismatch");
if (state.executorHasPlanningFunction !== true) throw new Error("executorHasPlanningFunction should be true");
if (state.executorHasWriteFunction !== true) throw new Error("executorHasWriteFunction should be true");
if (state.eligibleForFutureEnablement !== true) throw new Error("eligibleForFutureEnablement should be true");
if (state.canShowFutureSaveButton !== true) throw new Error("canShowFutureSaveButton should be true");
if (state.blockers.length !== 0) throw new Error("expected no blockers");
if (!state.warnings.some((msg) => msg.includes("Legacy backend cache fields will be excluded"))) {
  throw new Error("expected sanitization warning");
}

const view = controller.createDisabledActionViewModel({
  selectedFileName: "buddies-who-study-current.json",
  currentFileHandle,
  directoryHandle,
  payload
}, {
  createdAt: "2026-07-06T00:30:00.000Z"
});

if (view.label !== "Save current backup") throw new Error("wrong label");
if (view.visible !== false) throw new Error("view should not be visible");
if (view.disabled !== true) throw new Error("view should be disabled");
if (!view.reason.includes("source-only")) throw new Error("view should explain source-only state");

const wrong = controller.createSaveCurrentBackupActionState({
  selectedFileName: "buddies-who-study-local-backup-v2-test.json",
  currentFileHandle,
  directoryHandle,
  payload
}, {
  createdAt: "2026-07-06T00:30:00.000Z"
});

if (wrong.eligibleForFutureEnablement !== false) throw new Error("wrong selected file should not be eligible");
if (wrong.canShowFutureSaveButton !== false) throw new Error("wrong selected file should not show future button");
if (!wrong.blockers.some((msg) => msg.includes("Selected file must be buddies-who-study-current.json"))) {
  throw new Error("missing wrong selected file blocker");
}

console.log("PASS node R14D save action controller source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r14d save action controller source-only smoke"
