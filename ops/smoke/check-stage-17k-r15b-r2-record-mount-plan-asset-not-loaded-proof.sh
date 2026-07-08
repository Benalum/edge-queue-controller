#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r15b-r2-record-mount-plan-asset-not-loaded-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r15b-r2-record-mount-plan-asset-not-loaded-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Mount Plan Asset Not Loaded Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "Recovery note" "$DOC"
grep -Fq "PASS_R15A_MOUNT_PLAN_ASSET_NOT_LOADED_NO_UI_NO_BINDING" "$DOC"

grep -Fq "profileButtonsPresent true" "$DOC"
grep -Fq "mountPlanLoadedByScript false" "$DOC"
grep -Fq "mountPlanWindowPresent false" "$DOC"

grep -Fq "htmlRendererLoadedByScript true" "$DOC"
grep -Fq "htmlRendererWindowPresent true" "$DOC"
grep -Fq "renderSpecLoadedByScript true" "$DOC"
grep -Fq "renderSpecWindowPresent true" "$DOC"
grep -Fq "viewModelLoadedByScript true" "$DOC"
grep -Fq "viewModelWindowPresent true" "$DOC"
grep -Fq "controllerWindowPresent true" "$DOC"
grep -Fq "executorWindowPresent true" "$DOC"
grep -Fq "panelWindowPresent true" "$DOC"

grep -Fq "assetStatus 200" "$DOC"
grep -Fq "assetHasMarker true" "$DOC"
grep -Fq "assetHasPlanFunction true" "$DOC"
grep -Fq "assetHasPlanTextFunction true" "$DOC"
grep -Fq "assetHasDisabledFlags true" "$DOC"
grep -Fq "assetHasForbiddenDomOrWriteCode false" "$DOC"

grep -Fq "mountStatus 200" "$DOC"
grep -Fq "panelStatus 200" "$DOC"
grep -Fq "mountReferencesMountPlan false" "$DOC"
grep -Fq "panelReferencesMountPlan false" "$DOC"

grep -Fq "hasVisibleStatusPreview true" "$DOC"
grep -Fq "statusStillNoWrite true" "$DOC"
grep -Fq "insertedPreviewButtonPresent false" "$DOC"
grep -Fq "mountedButtonPresent false" "$DOC"
grep -Fq "hasUnsafeButton false" "$DOC"

grep -Fq "Choose local backup folder" "$DOC"
grep -Fq "Download snapshot" "$DOC"
grep -Fq "Preview backup file" "$DOC"
grep -Fq "Open current backup file" "$DOC"

grep -Fq "No source mutation" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"

echo "PASS stage-17k-r15b-r2 record mount plan asset-not-loaded proof smoke"
