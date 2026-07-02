# Stage 17K-Z-R12U — Profile Backup Restore Preview Bridge

## Status

Source-only bridge checkpoint.

No frontend deploy.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study doc write.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No UI mount.
No index.html loader change.
No Profile card mutation.

## Added source

Added:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-restore-preview-bridge.js

This file is not loaded by index.html yet.

## Purpose

Bridge the Profile local backups card to the restore preview helper in a safe, preview-only way.

This prepares a future Profile button that lets the user choose a backup JSON file and see what would be restored before any write path exists.

## Current behavior

The bridge can:

- validate a backup file-like object
- read a user-selected JSON file only after explicit user action
- call the R12T restore preview helper
- assert that the preview remains write-disabled
- format a plain-text preview summary
- format a safe HTML preview output
- choose a backup file through a temporary file input when called by future UI

The bridge does not:

- load automatically
- mount UI
- add a Profile button
- write browser storage
- write IndexedDB
- overwrite local data
- persist media blobs
- parse Anki
- parse APKG
- deploy live

## Restore safety

Every path preserves:

- canWrite false
- writesEnabled false
- writeMode preview-only
- requiresExplicitConfirmation true
- overwriteExistingLocalData false

## Next recommended stage

R12V should load the schema/export/restore/bridge helpers and add a Profile card button for previewing a backup file, still with no restore write path.
