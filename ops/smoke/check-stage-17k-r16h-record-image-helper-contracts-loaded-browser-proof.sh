#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r16h-record-image-helper-contracts-loaded-browser-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16h-record-image-helper-contracts-loaded-browser-proof"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$INDEX"

grep -Fq "Record Image Helper Contracts Loaded Browser Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R16G_R3_IMAGE_HELPER_CONTRACTS_LOADED_NO_UI_NO_BINDING" "$DOC"

grep -Fq "profileControlsPresent true" "$DOC"
grep -Fq "hasUnsafeImageUiButton false" "$DOC"
grep -Fq "hasUnsafeBackupButton false" "$DOC"
grep -Fq "fileInputCount 1" "$DOC"
grep -Fq "imageRelatedFileInputCount 0" "$DOC"
grep -Fq "imageUiNodeCount 0" "$DOC"

grep -Fq "allAssetsOk true" "$DOC"
grep -Fq "allSafetyOk true" "$DOC"

grep -Fq "status 200" "$DOC"
grep -Fq "markerPresent true" "$DOC"
grep -Fq "loadedByScript true" "$DOC"
grep -Fq "windowPresent true" "$DOC"
grep -Fq "returnedHtmlFallback false" "$DOC"
grep -Fq "hasForbiddenWriteOrDom false" "$DOC"
grep -Fq "safetyOk true" "$DOC"
grep -Fq "badSafetyValues empty" "$DOC"

grep -Fq "no image UI button" "$DOC"
grep -Fq "no image-related file input" "$DOC"
grep -Fq "no image UI node" "$DOC"
grep -Fq "no unsafe backup/save button" "$DOC"
grep -Fq "no blob write" "$DOC"
grep -Fq "no IndexedDB write" "$DOC"
grep -Fq "no backup write" "$DOC"
grep -Fq "no backend upload" "$DOC"
grep -Fq "no Google Drive sync" "$DOC"
grep -Fq "no Anki mutation" "$DOC"

grep -Fq "study-card-images-local-only-contract.js?v=stage17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding-20260708" "$INDEX"
grep -Fq "study-card-images-local-storage-adapter-contract.js?v=stage17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding-20260708" "$INDEX"
grep -Fq "study-card-images-backup-manifest-contract.js?v=stage17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding-20260708" "$INDEX"
grep -Fq "study-card-images-card-editor-ui-plan.js?v=stage17k-r16g-load-study-card-image-helper-contracts-no-ui-no-binding-20260708" "$INDEX"

echo "PASS stage-17k-r16h record image helper contracts loaded browser proof smoke"
