#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r16f-record-image-helper-assets-not-loaded-browser-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16f-record-image-helper-assets-not-loaded-browser-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Image Helper Assets Not Loaded Browser Proof" "$DOC"
grep -Fq "Browser proof passed" "$DOC"
grep -Fq "PASS_R16E_IMAGE_HELPER_ASSETS_NOT_LOADED_NO_UI_NO_BINDING" "$DOC"

grep -Fq "profileControlsPresent true" "$DOC"
grep -Fq "hasUnsafeImageUiButton false" "$DOC"
grep -Fq "hasUnsafeBackupButton false" "$DOC"
grep -Fq "Folder picker not supported" "$DOC"

grep -Fq "study-card-images-local-only-contract.js | 200 | true | false | false | false | false" "$DOC"
grep -Fq "study-card-images-local-storage-adapter-contract.js | 200 | true | false | false | false | false" "$DOC"
grep -Fq "study-card-images-backup-manifest-contract.js | 200 | true | false | false | false | false" "$DOC"
grep -Fq "study-card-images-card-editor-ui-plan.js | 200 | true | false | false | false | false" "$DOC"

grep -Fq "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT_R16A_R3_SOURCE_ONLY" "$DOC"
grep -Fq "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT_R16B_SOURCE_ONLY" "$DOC"
grep -Fq "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT_R16C_SOURCE_ONLY" "$DOC"
grep -Fq "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN_R16D_SOURCE_ONLY" "$DOC"

grep -Fq "No source mutation" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No current-file save in live UI" "$DOC"
grep -Fq "No same-file write path in live UI" "$DOC"
grep -Fq "No media blob persistence" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"

echo "PASS stage-17k-r16f record image helper assets-not-loaded browser proof smoke"
