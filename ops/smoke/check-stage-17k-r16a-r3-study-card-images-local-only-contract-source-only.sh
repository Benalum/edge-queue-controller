#!/usr/bin/env bash
set -Eeuo pipefail
CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="docs/stage-17k-r16a-r3-study-card-images-local-only-contract-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16a-r3-study-card-images-local-only-contract-source-only"

test -f "$CONTRACT"
test -f "$INDEX"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT_R16A_R3_SOURCE_ONLY" "$CONTRACT"
grep -Fq "createCardImageAttachment" "$CONTRACT"
grep -Fq "normalizeCardImages" "$CONTRACT"
grep -Fq "attachImagesToCardMetadata" "$CONTRACT"
grep -Fq "createBackupManifestForCardImages" "$CONTRACT"
grep -Fq "getSafetyFlags" "$CONTRACT"
grep -Fq "question" "$CONTRACT"
grep -Fq "answer" "$CONTRACT"
grep -Fq "image/jpeg" "$CONTRACT"
grep -Fq "image/png" "$CONTRACT"
grep -Fq "image/webp" "$CONTRACT"
grep -Fq "image/gif" "$CONTRACT"
grep -Fq "backendUploadAllowed: false" "$CONTRACT"
grep -Fq "serverSyncAllowed: false" "$CONTRACT"
grep -Fq "googleDriveSyncAllowedNow: false" "$CONTRACT"
grep -Fq "ankiMutationAllowed: false" "$CONTRACT"
grep -Fq "blobStoredNow: false" "$CONTRACT"
grep -Fq "indexedDbWriteNow: false" "$CONTRACT"
grep -Fq "backupPayloadWriteNow: false" "$CONTRACT"

grep -Fq "Study Card Images Local-Only Contract Source-Only" "$DOC"
grep -Fq "question-side images" "$DOC"
grep -Fq "answer-side images" "$DOC"
grep -Fq "SVG is intentionally excluded" "$DOC"
grep -Fq "No server image storage" "$DOC"
grep -Fq "No Anki file mutation" "$DOC"

if grep -Fq "/privatepages/study-card-images-local-only-contract.js" "$INDEX"; then
  echo "FAIL: image contract must not be loaded by index.html"
  exit 1
fi

if grep -Eq "document\.|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|createWritable\(|\.write\(|\.close\(" "$CONTRACT"; then
  echo "FAIL: source-only contract contains forbidden DOM/network/storage/write API"
  exit 1
fi

node --check "$CONTRACT"
node - <<'NODE'
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js");
if (api.MARKER !== "APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT_R16A_R3_SOURCE_ONLY") throw new Error("marker mismatch");
if (!api.SIDES.includes("question") || !api.SIDES.includes("answer")) throw new Error("missing side");
if (!api.isAllowedMimeType("image/png")) throw new Error("png should be allowed");
if (api.isAllowedMimeType("image/svg+xml")) throw new Error("svg should not be allowed");
const q = api.createCardImageAttachment({side:"question", fileName:"question.png", mimeType:"image/png", sizeBytes:1024, localBlobId:"local/blob/question/1"});
const a = api.createCardImageAttachment({side:"answer", fileName:"answer.webp", mimeType:"image/webp", sizeBytes:2048, localBlobId:"local/blob/answer/1"});
if (!q.isValid || !a.isValid) throw new Error("attachments should be valid");
if (q.storagePolicy.backendUploadAllowed !== false) throw new Error("backend upload must stay false");
if (a.storagePolicy.ankiMutationAllowed !== false) throw new Error("anki mutation must stay false");
const card = api.attachImagesToCardMetadata({id:"card-1", question:"Q", answer:"A"}, {question:[q], answer:[a]});
if (card.images.question.length !== 1 || card.images.answer.length !== 1) throw new Error("card image counts mismatch");
const manifest = api.createBackupManifestForCardImages(card);
if (manifest.questionImageCount !== 1 || manifest.answerImageCount !== 1 || manifest.totalImageCount !== 2) throw new Error("manifest counts mismatch");
if (manifest.containsBlobBytesNow !== false || manifest.uploadsNow !== false || manifest.mutatesAnkiNow !== false) throw new Error("manifest safety mismatch");
const flags = api.getSafetyFlags();
if (flags.sourceOnly !== true || flags.loadedByIndexNow !== false || flags.uiMountedNow !== false || flags.backendUploadAllowed !== false) throw new Error("safety flags mismatch");
console.log("PASS node R16A-R3 study card images local-only contract source-only behavior smoke");
NODE

echo "PASS stage-17k-r16a-r3 study card images local-only contract source-only smoke"
