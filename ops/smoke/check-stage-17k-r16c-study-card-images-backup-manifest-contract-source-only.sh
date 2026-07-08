#!/usr/bin/env bash
set -euo pipefail

BACKUP_CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-backup-manifest-contract.js"
IMAGE_CONTRACT="frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="docs/stage-17k-r16c-study-card-images-backup-manifest-contract-source-only.md"
OUT_DIR="docs/smoke/generated/stage-17k-r16c-study-card-images-backup-manifest-contract-source-only"

test -f "$BACKUP_CONTRACT"
test -f "$IMAGE_CONTRACT"
test -f "$INDEX"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT_R16C_SOURCE_ONLY" "$BACKUP_CONTRACT"
grep -Fq "createImageBackupEntry" "$BACKUP_CONTRACT"
grep -Fq "createCardImagesBackupSection" "$BACKUP_CONTRACT"
grep -Fq "validateCardImagesBackupSection" "$BACKUP_CONTRACT"
grep -Fq "createImportPlanFromBackupSection" "$BACKUP_CONTRACT"
grep -Fq "getSafetyFlags" "$BACKUP_CONTRACT"
grep -Fq "containsBlobBytesNow: false" "$BACKUP_CONTRACT"
grep -Fq "readsBlobBytesNow: false" "$BACKUP_CONTRACT"
grep -Fq "writesBackupNow: false" "$BACKUP_CONTRACT"
grep -Fq "writesIndexedDbNow: false" "$BACKUP_CONTRACT"
grep -Fq "uploadsNow: false" "$BACKUP_CONTRACT"
grep -Fq "serverSyncNow: false" "$BACKUP_CONTRACT"
grep -Fq "googleDriveSyncNow: false" "$BACKUP_CONTRACT"
grep -Fq "mutatesAnkiNow: false" "$BACKUP_CONTRACT"

grep -Fq "Study Card Images Backup Manifest Contract Source-Only" "$DOC"
grep -Fq "No backup write" "$DOC"
grep -Fq "No import write" "$DOC"
grep -Fq "No server image storage" "$DOC"
grep -Fq "No Anki file mutation" "$DOC"

if grep -Fq "/privatepages/study-card-images-backup-manifest-contract.js" "$INDEX"; then
  echo "FAIL: backup manifest contract must not be loaded by index.html"
  exit 1
fi

if grep -Eq "document\.|appendChild|insertAdjacentElement|addEventListener\([\"']click|onclick|fetch\(|XMLHttpRequest|sendBeacon|localStorage|sessionStorage|indexedDB|FileReader|createObjectURL|showOpenFilePicker|showSaveFilePicker|createWritable\(|\.write\(|\.close\(" "$BACKUP_CONTRACT"; then
  echo "FAIL: source-only backup contract contains forbidden DOM/network/storage/write API"
  exit 1
fi

node --check "$BACKUP_CONTRACT"

node - <<'NODE'
const imageApi = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js");
globalThis.APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT = imageApi;
const backupApi = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-backup-manifest-contract.js");

if (backupApi.MARKER !== "APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT_R16C_SOURCE_ONLY") throw new Error("marker mismatch");

const q = imageApi.createCardImageAttachment({
  side: "question",
  fileName: "question.png",
  mimeType: "image/png",
  sizeBytes: 1024,
  localBlobId: "local/blob/question/1",
  sha256: "abc",
  altText: "Question diagram"
});
const a = imageApi.createCardImageAttachment({
  side: "answer",
  fileName: "answer.webp",
  mimeType: "image/webp",
  sizeBytes: 2048,
  localBlobId: "local/blob/answer/1",
  sha256: "def",
  altText: "Answer diagram"
});
const card = imageApi.attachImagesToCardMetadata({ id: "card-1", question: "Q", answer: "A" }, { question: [q], answer: [a] });
const section = backupApi.createCardImagesBackupSection(card, { exportedAt: "2026-07-08T00:00:00Z" });

if (section.questionImageCount !== 1) throw new Error("question count mismatch");
if (section.answerImageCount !== 1) throw new Error("answer count mismatch");
if (section.totalImageCount !== 2) throw new Error("total count mismatch");
if (section.containsBlobBytesNow !== false) throw new Error("containsBlobBytesNow must be false");
if (section.readsBlobBytesNow !== false) throw new Error("readsBlobBytesNow must be false");
if (section.writesBackupNow !== false) throw new Error("writesBackupNow must be false");
if (section.writesIndexedDbNow !== false) throw new Error("writesIndexedDbNow must be false");
if (section.uploadsNow !== false) throw new Error("uploadsNow must be false");
if (section.mutatesAnkiNow !== false) throw new Error("mutatesAnkiNow must be false");
if (section.validation.isValid !== true) throw new Error("section validation should be valid");

const validation = backupApi.validateCardImagesBackupSection(section);
if (validation.isValid !== true) throw new Error("validation should be valid");

const importPlan = backupApi.createImportPlanFromBackupSection(section);
if (importPlan.totalImageCount !== 2) throw new Error("import plan total mismatch");
if (importPlan.writesCardMetadataNow !== false) throw new Error("writesCardMetadataNow must be false");
if (importPlan.writesImageBlobsNow !== false) throw new Error("writesImageBlobsNow must be false");
if (importPlan.writesIndexedDbNow !== false) throw new Error("writesIndexedDbNow must be false");
if (importPlan.mutatesAnkiNow !== false) throw new Error("mutatesAnkiNow must be false");
if (importPlan.uploadsNow !== false) throw new Error("uploadsNow must be false");

const flags = backupApi.getSafetyFlags();
if (flags.sourceOnly !== true) throw new Error("sourceOnly mismatch");
if (flags.loadedByIndexNow !== false) throw new Error("loadedByIndexNow must be false");
if (flags.uiMountedNow !== false) throw new Error("uiMountedNow must be false");
if (flags.writesBackupNow !== false) throw new Error("writesBackupNow must be false");
if (flags.writesIndexedDbNow !== false) throw new Error("writesIndexedDbNow must be false");
if (flags.uploadsNow !== false) throw new Error("uploadsNow must be false");

console.log("PASS node R16C study card images backup manifest contract source-only behavior smoke");
NODE

echo "PASS stage-17k-r16c study card images backup manifest contract source-only smoke"
