# Stage 17K-R13M — Sanitized Backup Payload Builder Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No write path.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-sanitized-payload-builder.js

Marker:

- APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER_R13M_SOURCE_ONLY

## Purpose

Build a cloned sanitized backup payload for future backup output.

It strips legacy backend cache fields from the cloned output payload:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

It does not mutate current browser Study data.

## Future use

This helper should be used before:

- future Download snapshot output
- future buddies-who-study-current.json same-file save

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
