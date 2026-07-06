#!/usr/bin/env bash
set -euo pipefail

VIEWMODEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-view-model.js"
CONTROLLER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-action-controller.js"
EXECUTOR="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js"
WRITER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js"
BUILDER="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js"
SNAPSHOT="frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-r14k-disabled-save-button-view-model-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14k-disabled-save-button-view-model-source-only"

test -f "$VIEWMODEL"
test -f "$CONTROLLER"
test -f "$EXECUTOR"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY" "$VIEWMODEL"
grep -Fq "createDisabledSaveButtonViewModel" "$VIEWMODEL"
grep -Fq "createDisabledSaveButtonStatusText" "$VIEWMODEL"
grep -Fq "buttonElementCreated: false" "$VIEWMODEL"
grep -Fq "buttonVisibleNow: false" "$VIEWMODEL"
grep -Fq "buttonDisabledNow: true" "$VIEWMODEL"
grep -Fq "actionBoundToUi: false" "$VIEWMODEL"
grep -Fq "clickHandlerAdded: false" "$VIEWMODEL"
grep -Fq "writeExecutorCalled: false" "$VIEWMODEL"
grep -Fq "canWriteNow: false" "$VIEWMODEL"
grep -Fq "writesEnabledNow: false" "$VIEWMODEL"
grep -Fq "currentFileSaveEnabledNow: false" "$VIEWMODEL"
grep -Fq "sameFileWriteEnabledNow: false" "$VIEWMODEL"
grep -Fq "requiresLaterDeployStage: true" "$VIEWMODEL"
grep -Fq "Save current backup" "$VIEWMODEL"
grep -Fq "No file is saved, replaced, merged, restored, or overwritten" "$VIEWMODEL"

grep -Fq "Disabled Save Button View Model Source-Only" "$DOC"
grep -Fq "No deploy" "$DOC"
grep -Fq "No live UI change" "$DOC"
grep -Fq "No button" "$DOC"
grep -Fq "No click handler" "$DOC"
grep -Fq "No executor call" "$DOC"
grep -Fq "No file write" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

if grep -Fq "/privatepages/local-backup-current-file-disabled-save-button-view-model.js" "$INDEX"; then
  echo "FAIL: disabled save button view model must not be loaded by index.html"
  exit 1
fi

if grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL" "$MOUNT" "$PANEL"; then
  echo "FAIL: disabled save button view model must not be referenced by live mount/panel"
  exit 1
fi

if grep -Eq "document\\.createElement\\([\"']button|<button|addEventListener\\([\"']click|onclick|executeCurrentBackupWrite\\(" "$VIEWMODEL"; then
  echo "FAIL: view model must not create buttons, click handlers, or write calls"
  exit 1
fi

if grep -Eq "createWritable\\(|\\.write\\(|\\.close\\(|showSaveFilePicker|showDirectoryPicker" "$VIEWMODEL"; then
  echo "FAIL: view model must not contain write picker/stream code"
  exit 1
fi

if grep -Eq "fetch\\(|XMLHttpRequest|sendBeacon|localStorage\\.setItem|sessionStorage\\.setItem|indexedDB" "$VIEWMODEL"; then
  echo "FAIL: view model contains forbidden network/storage API"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$VIEWMODEL"
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
globalThis.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER = controller;

const viewApi = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-view-model.js");

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

const vm = viewApi.createDisabledSaveButtonViewModel({
  selectedFileName: "buddies-who-study-current.json",
  currentFileHandle: { name: "buddies-who-study-current.json" },
  directoryHandle: { getFileHandle: async () => ({ name: "buddies-who-study-current.previous.json" }) },
  payload
}, {
  createdAt: "2026-07-06T00:55:00.000Z"
});

if (vm.marker !== "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY") throw new Error("marker mismatch");
if (vm.sourceOnly !== true) throw new Error("sourceOnly should be true");
if (vm.deployed !== false) throw new Error("deployed should be false");
if (vm.uiLoaded !== false) throw new Error("uiLoaded should be false");
if (vm.domElementCreated !== false) throw new Error("domElementCreated should be false");
if (vm.buttonElementCreated !== false) throw new Error("buttonElementCreated should be false");
if (vm.buttonVisibleNow !== false) throw new Error("buttonVisibleNow should be false");
if (vm.buttonDisabledNow !== true) throw new Error("buttonDisabledNow should be true");
if (vm.buttonMayBeShownInFutureStage !== true) throw new Error("button may be shown later should be true");
if (vm.futureEligible !== true) throw new Error("futureEligible should be true");
if (vm.actionBoundToUi !== false) throw new Error("actionBoundToUi should be false");
if (vm.clickHandlerAdded !== false) throw new Error("clickHandlerAdded should be false");
if (vm.clickHandlerCallsWriteExecutor !== false) throw new Error("clickHandlerCallsWriteExecutor should be false");
if (vm.writeExecutorCalled !== false) throw new Error("writeExecutorCalled should be false");
if (vm.canWriteNow !== false) throw new Error("canWriteNow should be false");
if (vm.writesEnabledNow !== false) throw new Error("writesEnabledNow should be false");
if (vm.currentFileSaveEnabledNow !== false) throw new Error("currentFileSaveEnabledNow should be false");
if (vm.sameFileWriteEnabledNow !== false) throw new Error("sameFileWriteEnabledNow should be false");
if (vm.requiresLaterDeployStage !== true) throw new Error("requiresLaterDeployStage should be true");
if (vm.label !== "Save current backup") throw new Error("wrong label");
if (!vm.disabledReason.includes("source-only")) throw new Error("disabled reason should mention source-only");
if (vm.selectedFileAllowed !== true) throw new Error("selectedFileAllowed should be true");
if (vm.currentFileHandleAllowed !== true) throw new Error("currentFileHandleAllowed should be true");
if (vm.directoryHandlePresent !== true) throw new Error("directoryHandlePresent should be true");
if (vm.sanitizedPlanReady !== true) throw new Error("sanitizedPlanReady should be true");
if (vm.removedFieldCount !== 4) throw new Error("removedFieldCount should be 4 for dirty fixture");
if (vm.afterLegacyFieldPaths.length !== 0) throw new Error("afterLegacyFieldPaths should be empty");
if (vm.controllerLoaded !== true) throw new Error("controllerLoaded should be true");
if (vm.executorLoaded !== true) throw new Error("executorLoaded should be true");
if (vm.executorHasPlanningFunction !== true) throw new Error("executorHasPlanningFunction should be true");
if (vm.executorHasWriteFunction !== true) throw new Error("executorHasWriteFunction should be true");
if (vm.blockers.length !== 0) throw new Error("expected no blockers");

const status = viewApi.createDisabledSaveButtonStatusText(vm);
if (!status.includes("Save current backup button view model")) throw new Error("status missing title");
if (!status.includes("Visible now: false")) throw new Error("status missing visible false");
if (!status.includes("Disabled now: true")) throw new Error("status missing disabled true");
if (!status.includes("Can write now: false")) throw new Error("status missing write false");
if (!status.includes("Write executor called: false")) throw new Error("status missing executor called false");
if (!status.includes("Legacy backend cache fields removed: 4")) throw new Error("status missing removed 4");
if (!status.includes("After legacy backend cache fields: none")) throw new Error("status missing after none");
if (!status.includes("No file is saved, replaced, merged, restored, or overwritten.")) throw new Error("status missing safety text");

const wrong = viewApi.createDisabledSaveButtonViewModel({
  selectedFileName: "buddies-who-study-local-backup-v2-test.json",
  currentFileHandle: { name: "buddies-who-study-current.json" },
  directoryHandle: { getFileHandle: async () => ({ name: "buddies-who-study-current.previous.json" }) },
  payload
}, {
  createdAt: "2026-07-06T00:55:00.000Z"
});

if (wrong.futureEligible !== false) throw new Error("wrong selected file should not be future eligible");
if (wrong.buttonMayBeShownInFutureStage !== false) throw new Error("wrong selected file should not show later");
if (wrong.buttonVisibleNow !== false) throw new Error("wrong selected file should still be invisible now");
if (wrong.buttonDisabledNow !== true) throw new Error("wrong selected file should still be disabled");
if (!wrong.blockers.some((msg) => msg.includes("Selected file must be buddies-who-study-current.json"))) {
  throw new Error("missing selected file blocker");
}

console.log("PASS node R14K disabled save button view model source-only behavior smoke");
NODE
fi

echo "PASS stage-17k-r14k disabled save button view model source-only smoke"
