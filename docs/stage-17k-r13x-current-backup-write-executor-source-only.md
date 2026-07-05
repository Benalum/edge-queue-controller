# Stage 17K-R13X — Current Backup Write Executor Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No script load.
No button.
No real file write.
No same-file write enablement.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-write-executor.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY

## Purpose

Adds the future guarded executor for updating:

- buddies-who-study-current.json

The executor requires writing a last-good copy first:

- buddies-who-study-current.previous.json

## Strict guards

The executor refuses unless all of the following are true:

- selected file name is buddies-who-study-current.json
- current file handle name is buddies-who-study-current.json
- directory handle can create/open buddies-who-study-current.previous.json
- sanitized payload text is prepared
- enableWrite is true
- enableToken matches R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE
- confirmSelectedFileName is buddies-who-study-current.json

## Write order

Future write sequence:

1. Read existing buddies-who-study-current.json.
2. Write existing contents to buddies-who-study-current.previous.json.
3. Write sanitized JSON to buddies-who-study-current.json.
4. Read back buddies-who-study-current.json.
5. Verify kind/version and absence of legacy backend cache fields.

## Sanitization

The executor depends on the R13S save writer plan, which depends on the sanitized snapshot output helper.

Legacy backend cache fields must be absent from final readback:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

## Smoke behavior

The smoke runs only against fake in-memory file handles.

No real user file is written.

## Safety

Source-only and not loaded by index.html.

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
No current-file save in live UI.
No same-file write path in live UI.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.
No backup panel source change.
No mount source change.
