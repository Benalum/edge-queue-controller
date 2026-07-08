#!/usr/bin/env bash
set -euo pipefail

UI_PLAN="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-card-editor-ui-plan.js"
CARD_CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js"
STORAGE_CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-storage-adapter-contract.js"
BACKUP_CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-backup-manifest-contract.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="docs/stage-17k-r16d-study-card-images-card-editor-ui-plan-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16d-study-card-images-card-editor-ui-plan-source-only"

test -f "$UI_PLAN"
test -f "$CARD_CONTRACT"
test -f "$STORAGE_CONTRACT"
test -f "$BACKUP_CONTRACT"
test -f "$INDEX"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN_R16D_SOURCE_ONLY" "$UI_PLAN"
grep -Fq "createSideImageUiPlan" "$UI_PLAN"
grep -Fq "createCardEditorImageUiPlan" "$UI_PLAN"
grep -Fq "createCardEditorImageUiPlanText" "$UI_PLAN"
grep -Fq "validateCardEditorImageUiPlan" "$UI_PLAN"
grep -Fq "Add question image" "$UI_PLAN"
grep -Fq "Add answer image" "$UI_PLAN"
grep -Fq "below-question-text-editor" "$UI_PLAN"
grep -Fq "below-answer-text-editor" "$UI_PLAN"
grep -Fq "image/jpeg" "$UI_PLAN"
grep -Fq "image/png" "$UI_PLAN"
grep -Fq "image/webp" "$UI_PLAN"
grep -Fq "image/gif" "$UI_PLAN"
grep -Fq "uiMountedNow: false" "$UI_PLAN"
grep -Fq "domElementCreatedNow: false" "$UI_PLAN"
grep -Fq "filePickerOpenedNow: false" "$UI_PLAN"
grep -Fq "imagePreviewRenderedNow: false" "$UI_PLAN"
grep -Fq "objectUrlCreatedNow: false" "$UI_PLAN"
grep -Fq "blobStoredNow: false" "$UI_PLAN"
grep -Fq "indexedDbWriteNow: false" "$UI_PLAN"
grep -Fq "backupPayloadWriteNow: false" "$UI_PLAN"
grep -Fq "backendUploadAllowed: false" "$UI_PLAN"
grep -Fq "ankiMutationAllowed: false" "$UI_PLAN"

grep -Fq "Study Card Images Card Editor UI Plan Source-Only" "$DOC"
grep -Fq "Add question image" "$DOC"
grep -Fq "Add answer image" "$DOC"
grep -Fq "No UI mount" "$DOC"
grep -Fq "No DOM creation" "$DOC"
grep -Fq "No file picker" "$DOC"
grep -Fq "No image preview" "$DOC"
grep -Fq "No IndexedDB write" "$DOC"
grep -Fq "No backend upload" "$DOC"
grep -Fq "No Anki file mutation" "$DOC"

if grep -Fq "/privatepages/study-card-images-card-editor-ui-plan.js" "$INDEX"; then
  echo "FAIL: UI plan must not be loaded by index.html"
  exit 1
fi

if grep -Eq "document\.|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|createWritable\(|\.write\(|\.close\(" "$UI_PLAN"; then
  echo "FAIL: source-only UI plan contains forbidden DOM/network/storage/write API"
  exit 1
fi

node --check "$UI_PLAN"

node - <<'NODE'
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-card-editor-ui-plan.js");

if (api.MARKER !== "APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN_R16D_SOURCE_ONLY") throw new Error("marker mismatch");
if (!api.SIDES.includes("question")) throw new Error("missing question side");
if (!api.SIDES.includes("answer")) throw new Error("missing answer side");
if (!api.ACCEPT_ATTRIBUTE.includes("image/png")) throw new Error("accept missing png");
if (api.ACCEPT_ATTRIBUTE.includes("image/svg+xml")) throw new Error("svg must remain excluded");

const card = {
  id: "card-1",
  images: {
    question: [{ id: "q1", fileName: "q.png", mimeType: "image/png", sizeBytes: 1234, localBlobId: "blob/q1" }],
    answer: [{ id: "a1", fileName: "a.webp", mimeType: "image/webp", sizeBytes: 2345, localBlobId: "blob/a1" }]
  }
};

const plan = api.createCardEditorImageUiPlan(card, {});
const text = api.createCardEditorImageUiPlanText(plan);
const validation = api.validateCardEditorImageUiPlan(plan);
const flags = api.getSafetyFlags();

if (plan.sourceOnly !== true) throw new Error("sourceOnly mismatch");
if (plan.localOnly !== true) throw new Error("localOnly mismatch");
if (plan.question.side !== "question") throw new Error("question side mismatch");
if (plan.answer.side !== "answer") throw new Error("answer side mismatch");
if (plan.question.addButtonText !== "Add question image") throw new Error("question button mismatch");
if (plan.answer.addButtonText !== "Add answer image") throw new Error("answer button mismatch");
if (plan.question.existingImages.length !== 1) throw new Error("question existing image count mismatch");
if (plan.answer.existingImages.length !== 1) throw new Error("answer existing image count mismatch");
if (plan.editorPlacement.questionSidePlacement !== "below-question-text-editor") throw new Error("question placement mismatch");
if (plan.editorPlacement.answerSidePlacement !== "below-answer-text-editor") throw new Error("answer placement mismatch");

for (const key of [
  "loadedByIndexNow",
  "uiMountedNow",
  "domElementCreatedNow",
  "buttonInsertedNow",
  "fileInputInsertedNow",
  "filePickerOpenedNow",
  "imagePreviewRenderedNow",
  "objectUrlCreatedNow",
  "fileBytesReadNow",
  "blobStoredNow",
  "indexedDbWriteNow",
  "backupPayloadWriteNow",
  "backendUploadAllowed",
  "serverSyncAllowed",
  "googleDriveSyncAllowedNow",
  "ankiMutationAllowed",
  "originalFileMutationAllowed",
  "mediaExtractionNow",
  "companionModelCallNow"
]) {
  if (flags[key] !== false) throw new Error(`${key} must be false`);
  if (plan.uiPolicy[key] !== false) throw new Error(`plan.uiPolicy.${key} must be false`);
}

if (validation.valid !== true) throw new Error("validation should pass");
if (validation.noUiNow !== true) throw new Error("noUiNow should be true");
if (validation.noWritesNow !== true) throw new Error("noWritesNow should be true");
if (validation.noExternalMutationNow !== true) throw new Error("noExternalMutationNow should be true");
if (!text.includes("Study card image editor UI plan")) throw new Error("text missing title");
if (!text.includes("Add question image")) throw new Error("text missing question button");
if (!text.includes("Add answer image")) throw new Error("text missing answer button");
if (!text.includes("IndexedDB write now: false")) throw new Error("text missing IndexedDB false");
if (!text.includes("Anki mutation allowed: false")) throw new Error("text missing Anki false");

console.log("PASS node R16D study card images card editor UI plan source-only behavior smoke");
NODE

echo "PASS stage-17k-r16d study card images card editor ui plan source-only smoke"
