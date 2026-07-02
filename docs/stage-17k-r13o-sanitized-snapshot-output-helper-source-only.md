# Stage 17K-R13O — Sanitized Snapshot Output Helper Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No browser download action.
No same-file write path.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-snapshot-output-helper.js

Marker:

- APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT_HELPER_R13O_SOURCE_ONLY

## Purpose

Prepare sanitized JSON text and a timestamped snapshot filename for future Download snapshot behavior.

It uses the R13M sanitized payload builder so future snapshot output can exclude legacy backend cache fields:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

## Safety

Source-only and prepare-only.

- canWrite false
- writesEnabled false
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
