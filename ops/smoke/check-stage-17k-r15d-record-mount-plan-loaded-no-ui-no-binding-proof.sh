#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r15d-record-mount-plan-loaded-no-ui-no-binding-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r15d-record-mount-plan-loaded-no-ui-no-binding-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Mount Plan Loaded No UI/Binding Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R15C_R2_MOUNT_PLAN_LOADED_NO_UI_NO_BINDING" "$DOC"

grep -Fq "folderControlPresent true" "$DOC"
grep -Fq "profileButtonsPresent true" "$DOC"
grep -Fq "Folder picker not supported" "$DOC"

grep -Fq "mountPlanLoadedByScript true" "$DOC"
grep -Fq "mountPlanWindowPresent true" "$DOC"
grep -Fq "mountPlanMarker APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY" "$DOC"

grep -Fq "assetStatus 200" "$DOC"
grep -Fq "mountStatus 200" "$DOC"
grep -Fq "panelStatus 200" "$DOC"
grep -Fq "assetHasMarker true" "$DOC"
grep -Fq "assetHasDisabledFlags true" "$DOC"
grep -Fq "assetHasForbiddenDomOrWriteCode false" "$DOC"

grep -Fq "mountReferencesMountPlan false" "$DOC"
grep -Fq "panelReferencesMountPlan false" "$DOC"

grep -Fq "hasVisibleStatusPreview true" "$DOC"
grep -Fq "statusStillNoWrite true" "$DOC"
grep -Fq "insertedPreviewButtonPresent false" "$DOC"
grep -Fq "mountedButtonPresent false" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"

grep -Fq "sourceOnly true" "$DOC"
grep -Fq "deployed false" "$DOC"
grep -Fq "uiLoaded false" "$DOC"
grep -Fq "mountPlanOnly true" "$DOC"
grep -Fq "domElementCreated false" "$DOC"
grep -Fq "elementInserted false" "$DOC"
grep -Fq "buttonVisibleNow false" "$DOC"
grep -Fq "buttonDisabledNow true" "$DOC"
grep -Fq "clickHandlerAdded false" "$DOC"
grep -Fq "actionBoundToUI: false" "$DOC" || grep -Fq "actionBoundToUi false" "$DOC"
grep -Fq "canWriteNow false" "$DOC"
grep -Fq "writesEnabledNow false" "$DOC"
grep -Fq "writeExecutorCalled false" "$DOC"
grep -Fq "currentFileSaveEnabledNow false" "$DOC"
grep -Fq "sameFileWriteEnabledNow false" "$DOC"

grep -Fq "No source mutation" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

echo "PASS stage-17k-r15d record mount plan loaded no ui/no binding proof smoke"
