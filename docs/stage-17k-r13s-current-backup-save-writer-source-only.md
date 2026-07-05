# Stage 17K-R13S — Current Backup Save Writer Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No file write.
No same-file write enablement.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-writer.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER_R13S_SOURCE_ONLY

## Purpose

Prepare the future guarded current backup save writer.

The helper creates a source-only plan for eventually updating:

- buddies-who-study-current.json

It also requires a last-good file to be prepared first:

- buddies-who-study-current.previous.json

## Guard rules

The plan refuses anything except:

- buddies-who-study-current.json

The future write sequence must be:

1. Refuse unless the selected file is buddies-who-study-current.json.
2. Prepare sanitized local-only backup JSON in memory.
3. Prepare buddies-who-study-current.previous.json first.
4. Replace buddies-who-study-current.json only after last-good preparation succeeds.
5. Verify readback JSON and absence of legacy backend cache fields.

## Sanitized payload

The helper uses the R13O sanitized snapshot output helper.

It verifies the future current backup output excludes:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

## Safety

Source-only and plan-only.

- canWrite false
- writesEnabled false
- sameFileWriteEnabled false
- currentFileWriteEnabled false
- previousFileWriteEnabled false
- serverUploadAllowed false
- ankiSourceMutationAllowed false
- localStudyRestoreWriteAllowed false
- currentBrowserDataMutationAllowed false

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
No current-file save.
No same-file write path.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.
