# Stage 17K-R16D — Study Card Images Card Editor UI Plan Source-Only

## Status

Source-only UI plan contract.

No deploy.
No index load.
No UI mount.
No DOM creation.
No button insertion.
No file input insertion.
No file picker.
No image preview.
No FileReader use.
No object URL creation.
No blob storage write.
No IndexedDB write.
No backup write.
No backend upload.
No Google Drive sync.
No Anki mutation.

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-card-editor-ui-plan.js

Marker:

- APC_STUDY_CARD_IMAGES_CARD_EDITOR_UI_PLAN_R16D_SOURCE_ONLY

## Purpose

Defines the source-only UI plan for optional flashcard images on both sides of a card:

- question-side image controls
- answer-side image controls

This stage plans future controls only. It does not render or mount them.

## Planned future controls

Question side:

- Add question image
- Replace image
- Remove image
- Image alt text
- Image caption

Answer side:

- Add answer image
- Replace image
- Remove image
- Image alt text
- Image caption

## Allowed initial image types

- image/jpeg
- image/png
- image/webp
- image/gif

SVG remains excluded for the first pass.

## Safety model

The UI plan always keeps these false in R16D:

- loadedByIndexNow
- uiMountedNow
- domElementCreatedNow
- buttonInsertedNow
- fileInputInsertedNow
- filePickerOpenedNow
- imagePreviewRenderedNow
- objectUrlCreatedNow
- fileBytesReadNow
- blobStoredNow
- indexedDbWriteNow
- backupPayloadWriteNow
- backendUploadAllowed
- serverSyncAllowed
- googleDriveSyncAllowedNow
- ankiMutationAllowed
- originalFileMutationAllowed
- mediaExtractionNow
- companionModelCallNow

## Non-goals

No server image storage.
No server private Study persistence.
No Anki file mutation.
No APKG mutation.
No Google Drive sync activation.
No Companion model call.
No screenshot OCR.
