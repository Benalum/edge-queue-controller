# Stage 17K-R16B — Study Card Images Local Storage Adapter Contract Source-Only

## Status

Source-only storage adapter contract.

No deploy.
No index load.
No UI.
No file picker.
No image preview.
No browser database open.
No browser database write.
No blob read.
No blob storage.
No backup migration.
No card schema migration.
No backend upload.
No Google Drive sync.
No Anki mutation.

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-storage-adapter-contract.js

Marker:

- APC_STUDY_CARD_IMAGES_LOCAL_STORAGE_ADAPTER_CONTRACT_R16B_SOURCE_ONLY

## Purpose

Defines the planned local-only storage adapter contract for future question-side and answer-side flashcard images.

R16B does not store blobs. It only defines inert descriptors and plans for a later IndexedDB-backed implementation.

## Planned local storage names

- DB name: buddies_who_study_local_v1
- Store name: study_card_image_blobs_v1
- Metadata namespace: study/card-images/v1

## Planned operations

The adapter can create source-only descriptions for:

- image blob storage descriptors
- per-card image storage plans
- backup reference plans
- safety flags

## Safety model

The adapter always keeps these false in R16B:

- filePickerOpenedNow
- blobReadNow
- blobStoredNow
- databaseOpenNow
- databaseWriteNow
- databaseDeleteNow
- backupPayloadWriteNow
- previewUrlCreatedNow
- previewRenderedNow
- backendUploadAllowed
- serverSyncAllowed
- googleDriveSyncAllowedNow
- ankiMutationAllowed
- originalFileMutationAllowed
- mediaExtractionNow

## Future stages

Later stages should add these separately:

1. Deploy adapter asset but do not load it.
2. Load adapter asset with no UI and no storage writes.
3. Define source-only backup/export rules for image references.
4. Define source-only editor UI plan for adding/removing question and answer images.
5. Add visible UI with writes disabled.
6. Enable local-only browser database writes after backup/export proof.

## Non-goals

No server image storage.
No Anki file mutation.
No APKG mutation.
No Drive sync activation.
No screenshot OCR.
No Companion model call.
