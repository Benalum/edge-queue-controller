#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r14t-record-render-spec-loaded-no-ui-no-binding-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r14t-record-render-spec-loaded-no-ui-no-binding-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Render Spec Loaded No UI/Binding Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R14S_RENDER_SPEC_LOADED_NO_UI_NO_BINDING" "$DOC"

grep -Fq "renderSpecLoadedByScript true" "$DOC"
grep -Fq "renderSpecWindowPresent true" "$DOC"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY" "$DOC"

grep -Fq "viewModelLoadedByScript true" "$DOC"
grep -Fq "viewModelWindowPresent true" "$DOC"
grep -Fq "controllerWindowPresent true" "$DOC"
grep -Fq "executorWindowPresent true" "$DOC"
grep -Fq "panelWindowPresent true" "$DOC"

grep -Fq "profileLocalBackupsMount true" "$DOC"
grep -Fq "ankiManifestPanel true" "$DOC"
grep -Fq "companion true" "$DOC"
grep -Fq "closedBetaGuard true" "$DOC"
grep -Fq "profileAnkiPreviewMount true" "$DOC"

grep -Fq "assetStatus 200" "$DOC"
grep -Fq "mountStatus 200" "$DOC"
grep -Fq "panelStatus 200" "$DOC"
grep -Fq "assetHasMarker true" "$DOC"
grep -Fq "assetHasForbiddenDomOrWriteCode false" "$DOC"

grep -Fq "mountReferencesRenderSpec false" "$DOC"
grep -Fq "panelReferencesRenderSpec false" "$DOC"
grep -Fq "hasVisibleStatusPreview true" "$DOC"
grep -Fq "statusStillNoWrite true" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"

grep -Fq "sourceOnly true" "$DOC"
grep -Fq "deployed false" "$DOC"
grep -Fq "uiLoaded false" "$DOC"
grep -Fq "renderSpecOnly true" "$DOC"
grep -Fq "domElementCreated false" "$DOC"
grep -Fq "elementInserted false" "$DOC"
grep -Fq "buttonElementCreated false" "$DOC"
grep -Fq "buttonVisibleNow false" "$DOC"
grep -Fq "buttonDisabledNow true" "$DOC"
grep -Fq "renderAllowedNow false" "$DOC"
grep -Fq "actionBoundToUi false" "$DOC"
grep -Fq "clickHandlerAdded false" "$DOC"
grep -Fq "writeExecutorCalled false" "$DOC"
grep -Fq "canWriteNow false" "$DOC"
grep -Fq "writesEnabledNow false" "$DOC"
grep -Fq "currentFileSaveEnabledNow false" "$DOC"
grep -Fq "sameFileWriteEnabledNow false" "$DOC"
grep -Fq "requiresLaterDeployStage true" "$DOC"
grep -Fq "requiresLaterUiMountStage true" "$DOC"

grep -Fq "No source mutation" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

echo "PASS stage-17k-r14t record render spec loaded no ui/no binding proof smoke"
