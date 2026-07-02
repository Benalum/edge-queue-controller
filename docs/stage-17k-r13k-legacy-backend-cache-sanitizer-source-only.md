# Stage 17K-R13K — Legacy Backend Cache Sanitizer Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No write path.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-legacy-backend-cache-sanitizer.js

Marker:

- APC_LOCAL_BACKUP_LEGACY_BACKEND_CACHE_SANITIZER_R13K_SOURCE_ONLY

## Purpose

Detect legacy backend cache fields inside:

- study/store-state/v1.state.backendProgress
- study/store-state/v1.state.backendReviewSummary
- study/store-state/v1.state.backendSessions
- study/store-state/v1.state.backendSyncedAt

Future local-only backup output should exclude these fields before any same-file update path is enabled.

## Safety

Source-only.

- canWrite false
- writesEnabled false
- writeMode preview-only
- sameFileWriteEnabled false
- serverUploadAllowed false
- ankiSourceMutationAllowed false
- localStudyRestoreWriteAllowed false

No backend deploy.
No frontend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study restore write.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.
