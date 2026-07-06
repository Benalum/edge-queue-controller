# Stage 17K-R14D — Save Action Controller Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No script load.
No button.
No executor call.
No file write.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-action-controller.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY

## Purpose

Adds a future action controller that decides whether a later "Save current backup" action may become eligible.

The helper reports eligibility only. It does not execute the write executor.

## Future eligibility requirements

Future eligibility requires:

- selected file name buddies-who-study-current.json
- current file handle name buddies-who-study-current.json
- directory handle available for buddies-who-study-current.previous.json preparation
- save writer plan helper loaded
- sanitized writer plan ready
- no legacy backend cache fields after sanitization
- write executor loaded
- write executor marker matches APC_LOCAL_BACKUP_CURRENT_FILE_WRITE_EXECUTOR_R13X_SOURCE_ONLY
- write executor enable token matches R13X_EXPLICIT_CURRENT_BACKUP_WRITE_ENABLE
- write executor planning function present
- write executor write function present

## Always disabled in R14D

R14D returns:

- sourceOnly true
- deployed false
- uiLoaded false
- uiButtonAdded false
- actionBoundToUi false
- executorCallAllowedNow false
- executorCalled false
- writesEnabledNow false
- canWriteNow false
- requiresLaterDeployStage true

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
