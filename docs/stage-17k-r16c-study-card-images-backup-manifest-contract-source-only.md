# Stage 17K-R16C — Study Card Images Backup Manifest Contract Source-Only

## Status

Source-only backup manifest contract.

No deploy.
No index load.
No UI.
No file picker.
No image preview.
No IndexedDB write.
No backup write.
No import write.
No backend upload.
No Google Drive sync.
No Anki mutation.

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-backup-manifest-contract.js

Marker:

- APC_STUDY_CARD_IMAGES_BACKUP_MANIFEST_CONTRACT_R16C_SOURCE_ONLY

## Purpose

Defines metadata-only backup/export/import planning rules for optional study card images.

This stage does not integrate with the live backup writer, the card editor, IndexedDB, Google Drive, or Anki.

## Scope

The contract can describe:

- question-side image backup entries
- answer-side image backup entries
- card image backup sections
- validation results
- import plans

The contract cannot and does not read, write, upload, sync, or restore image bytes.

## Safety model

The contract always keeps these false in R16C:

- containsBlobBytesNow
- readsBlobBytesNow
- writesBackupNow
- writesIndexedDbNow
- uploadsNow
- serverSyncNow
- googleDriveSyncNow
- mutatesAnkiNow

## Future stages

Later stages should add these separately:

1. Deploy backup manifest contract as a static asset, not loaded.
2. Load backup manifest contract, no UI and no binding.
3. Add source-only backup payload integration plan.
4. Add no-write browser proof for image backup metadata.
5. Only then add local IndexedDB image blob storage with explicit write proof.

## Non-goals

No server image storage.
No Anki file mutation.
No APKG mutation.
No Drive sync activation.
No screenshot OCR.
No Companion model call.
