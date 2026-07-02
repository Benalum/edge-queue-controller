# Stage 17K-R13I — Current Backup Save Plan Source-Only

## Status

Source-only safety contract.

No deploy.
No live UI change.
No write path.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-save-plan.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN_R13I_SOURCE_ONLY

## Purpose

This defines the plan contract for a future same-file update flow for:

- buddies-who-study-current.json

It does not save anything.

## Required future behavior before writing is enabled

- User explicitly selects buddies-who-study-current.json.
- Browser creates or verifies a last-good copy plan for buddies-who-study-current.previous.json.
- Browser shows merge summary before any write.
- User confirms the exact file update.
- Write helper verifies current file role is stable-current immediately before writing.
- Write helper refuses timestamped snapshot files.
- Original Anki files are never modified.
- No server upload is performed.

## Safety

Source-only.

- canWrite false
- writesEnabled false
- writeMode plan-only
- sameFileWriteEnabled false
- createWritableAllowed false
- overwriteAllowed false
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
