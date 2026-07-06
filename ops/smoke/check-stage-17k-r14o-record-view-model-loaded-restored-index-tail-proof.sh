#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14o-record-view-model-loaded-restored-index-tail-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14o-record-view-model-loaded-restored-index-tail-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record View Model Loaded Restored Index Tail Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R14N_R2_VIEW_MODEL_LOADED_RESTORED_INDEX_TAIL_NO_UI_NO_BINDING" "$DOC"

grep -Fq "viewModelLoadedByScript true" "$DOC"
grep -Fq "viewModelWindowPresent true" "$DOC"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY" "$DOC"

grep -Fq "controllerWindowPresent true" "$DOC"
grep -Fq "executorWindowPresent true" "$DOC"
grep -Fq "panelWindowPresent true" "$DOC"

grep -Fq "profileLocalBackupsMount true" "$DOC"
grep -Fq "ankiManifestPanel true" "$DOC"
grep -Fq "studySourceSelector true" "$DOC"
grep -Fq "ankiReadonlySession true" "$DOC"
grep -Fq "companionLocalAnkiBridge true" "$DOC"
grep -Fq "companion true" "$DOC"
grep -Fq "adminUsers true" "$DOC"
grep -Fq "closedBetaGuard true" "$DOC"
grep -Fq "ankiImportLocal true" "$DOC"
grep -Fq "profileAnkiImportBridge true" "$DOC"
grep -Fq "profileAnkiPreviewPanel true" "$DOC"
grep -Fq "profileAnkiPreviewMount true" "$DOC"

grep -Fq "assetStatus 200" "$DOC"
grep -Fq "mountStatus 200" "$DOC"
grep -Fq "panelStatus 200" "$DOC"
grep -Fq "assetHasMarker true" "$DOC"
grep -Fq "assetHasForbiddenWriteCode false" "$DOC"
grep -Fq "mountReferencesViewModel false" "$DOC"
grep -Fq "panelReferencesViewModel false" "$DOC"

grep -Fq "hasVisibleStatusPreview true" "$DOC"
grep -Fq "statusStillNoWrite true" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"

grep -Fq "buttonVisibleNow false" "$DOC"
grep -Fq "buttonDisabledNow true" "$DOC"
grep -Fq "actionBoundToUi false" "$DOC"
grep -Fq "clickHandlerAdded false" "$DOC"
grep -Fq "writeExecutorCalled false" "$DOC"
grep -Fq "canWriteNow false" "$DOC"
grep -Fq "writesEnabledNow false" "$DOC"
grep -Fq "currentFileSaveEnabledNow false" "$DOC"
grep -Fq "sameFileWriteEnabledNow false" "$DOC"
grep -Fq "requiresLaterDeployStage true" "$DOC"

grep -Fq "Legacy backend cache fields removed: 4" "$DOC"
grep -Fq "After legacy backend cache fields: none" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

echo "PASS stage-17k-r14o record view model loaded restored index tail proof smoke"
