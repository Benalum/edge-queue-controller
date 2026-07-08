#!/usr/bin/env bash
set -euo pipefail

CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js"
ADAPTER="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-storage-adapter-contract.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="docs/stage-17k-r16b-study-card-images-local-storage-adapter-contract-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16b-study-card-images-local-storage-adapter-contract-source-only"

test -f "$CONTRACT"
test -f "$ADAPTER"
test -f "$INDEX"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT_R16B_SOURCE_ONLY" "$ADAPTER"
grep -Fq "createImageBlobStorageDescriptor" "$ADAPTER"
grep -Fq "createCardImageStoragePlan" "$ADAPTER"
grep -Fq "createBackupReferencePlan" "$ADAPTER"
grep -Fq "getSafetyFlags" "$ADAPTER"
grep -Fq "buddies_who_study_local_v1" "$ADAPTER"
grep -Fq "study_card_image_blobs_v1" "$ADAPTER"
grep -Fq "study/card-images/v1" "$ADAPTER"
grep -Fq "question" "$ADAPTER"
grep -Fq "answer" "$ADAPTER"
grep -Fq "backendUploadAllowed: false" "$ADAPTER"
grep -Fq "serverSyncAllowed: false" "$ADAPTER"
grep -Fq "googleDriveSyncAllowedNow: false" "$ADAPTER"
grep -Fq "ankiMutationAllowed: false" "$ADAPTER"
grep -Fq "blobStoredNow: false" "$ADAPTER"
grep -Fq "databaseOpenNow: false" "$ADAPTER"
grep -Fq "databaseWriteNow: false" "$ADAPTER"
grep -Fq "backupPayloadWriteNow: false" "$ADAPTER"

grep -Fq "Study Card Images Local Storage Adapter Contract Source-Only" "$DOC"
grep -Fq "No browser database open" "$DOC"
grep -Fq "No browser database write" "$DOC"
grep -Fq "No blob storage" "$DOC"
grep -Fq "No server image storage" "$DOC"
grep -Fq "No Anki file mutation" "$DOC"

if grep -Fq "/privatepages/study-card-images-local-storage-adapter-contract.js" "$INDEX"; then
  echo "FAIL: storage adapter contract must not be loaded by index.html"
  exit 1
fi

if grep -Eq "document\.|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|createWritable\(|\.write\(|\.close\(" "$ADAPTER"; then
  echo "FAIL: source-only adapter contract contains forbidden DOM/network/storage/write API"
  exit 1
fi

node --check "$ADAPTER"

node - <<'NODE'
const contract = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js");
globalThis.APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT = contract;
const api = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-storage-adapter-contract.js");

if (api.MARKER !== "APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT_R16B_SOURCE_ONLY") throw new Error("marker mismatch");
if (api.DB_NAME !== "buddies_who_study_local_v1") throw new Error("db name mismatch");
if (api.STORE_NAME !== "study_card_image_blobs_v1") throw new Error("store name mismatch");
if (api.METADATA_NAMESPACE !== "study/card-images/v1") throw new Error("namespace mismatch");

const descriptor = api.createImageBlobStorageDescriptor({
  cardId: "card-1",
  deckId: "deck-1",
  side: "question",
  fileName: "question.png",
  mimeType: "image/png",
  sizeBytes: 1024,
  sha256: "abc123"
});

if (descriptor.sourceOnly !== true) throw new Error("descriptor sourceOnly mismatch");
if (descriptor.localOnly !== true) throw new Error("descriptor localOnly mismatch");
if (descriptor.side !== "question") throw new Error("descriptor side mismatch");
if (descriptor.isValidAttachment !== true) throw new Error("descriptor should be valid");
if (descriptor.plannedOnly !== true) throw new Error("descriptor plannedOnly mismatch");
if (descriptor.databaseOpenNow !== false) throw new Error("databaseOpenNow must be false");
if (descriptor.databaseWriteNow !== false) throw new Error("databaseWriteNow must be false");
if (descriptor.blobStoredNow !== false) throw new Error("blobStoredNow must be false");
if (descriptor.backupPayloadWriteNow !== false) throw new Error("backupPayloadWriteNow must be false");
if (descriptor.backendUploadAllowed !== false) throw new Error("backendUploadAllowed must be false");
if (descriptor.ankiMutationAllowed !== false) throw new Error("ankiMutationAllowed must be false");

const card = {
  id: "card-1",
  deckId: "deck-1",
  images: {
    question: [{ fileName: "q.png", mimeType: "image/png", sizeBytes: 111, localBlobId: "q1" }],
    answer: [{ fileName: "a.webp", mimeType: "image/webp", sizeBytes: 222, localBlobId: "a1" }]
  }
};

const plan = api.createCardImageStoragePlan(card);
if (plan.questionImageCount !== 1) throw new Error("question count mismatch");
if (plan.answerImageCount !== 1) throw new Error("answer count mismatch");
if (plan.totalImageCount !== 2) throw new Error("total count mismatch");
if (plan.databaseOpenNow !== false) throw new Error("plan databaseOpenNow must be false");
if (plan.databaseWriteNow !== false) throw new Error("plan databaseWriteNow must be false");
if (plan.blobStoredNow !== false) throw new Error("plan blobStoredNow must be false");
if (plan.uploadsNow !== false) throw new Error("plan uploadsNow must be false");
if (plan.mutatesAnkiNow !== false) throw new Error("plan mutatesAnkiNow must be false");

const backup = api.createBackupReferencePlan(card);
if (backup.containsBlobBytesNow !== false) throw new Error("backup must not contain blob bytes now");
if (backup.backupPayloadWriteNow !== false) throw new Error("backupPayloadWriteNow must be false");
if (backup.databaseReadNow !== false) throw new Error("backup databaseReadNow must be false");
if (backup.uploadNow !== false) throw new Error("backup uploadNow must be false");
if (backup.ankiMutationNow !== false) throw new Error("backup ankiMutationNow must be false");
if (backup.references.length !== 2) throw new Error("backup reference count mismatch");

const flags = api.getSafetyFlags();
if (flags.sourceOnly !== true) throw new Error("sourceOnly flag mismatch");
if (flags.loadedByIndexNow !== false) throw new Error("loadedByIndexNow must be false");
if (flags.uiMountedNow !== false) throw new Error("uiMountedNow must be false");
if (flags.filePickerOpenedNow !== false) throw new Error("filePickerOpenedNow must be false");
if (flags.blobStoredNow !== false) throw new Error("blobStoredNow must be false");
if (flags.databaseOpenNow !== false) throw new Error("databaseOpenNow must be false");
if (flags.databaseWriteNow !== false) throw new Error("databaseWriteNow must be false");
if (flags.backendUploadAllowed !== false) throw new Error("backendUploadAllowed must be false");

console.log("PASS node R16B study card images local storage adapter contract source-only behavior smoke");
NODE

echo "PASS stage-17k-r16b study card images local storage adapter contract source-only smoke"
