# Stage 17K-R16A-R3 — Study Card Images Local-Only Contract Source-Only

## Status

Source-only contract. No deploy, no index load, no UI, no file picker, no image preview, no IndexedDB write, no backup migration, no backend upload, no Google Drive sync, and no Anki mutation.

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-local-only-contract.js

Marker:

- APC_STUDY_CARD_IMAGES_LOCAL_ONLY_CONTRACT_R16A_R3_SOURCE_ONLY

## Purpose

Defines a local-only metadata contract for optional flashcard images on both sides of a card:

- question-side images
- answer-side images

Proposed card metadata shape:

    images.question = []
    images.answer = []

Allowed initial MIME types:

- image/jpeg
- image/png
- image/webp
- image/gif

SVG is intentionally excluded for the first pass.

## Safety model

The contract keeps these false in R16A-R3:

- backendUploadAllowed
- serverSyncAllowed
- googleDriveSyncAllowedNow
- ankiMutationAllowed
- originalFileMutationAllowed
- blobStoredNow
- indexedDbWriteNow
- backupPayloadWriteNow
- mediaExtractionNow

## Future stages

Later stages should separately add a storage adapter contract, backup/export manifest rules, card editor UI plan, deployed/load helpers with no UI, then local IndexedDB image blob storage after schema and backup proof.

## Non-goals

No server image storage, no Anki file mutation, no APKG mutation, no Drive sync activation, no screenshot OCR, and no Companion model call.

Safety restatement:

- No Anki file mutation
