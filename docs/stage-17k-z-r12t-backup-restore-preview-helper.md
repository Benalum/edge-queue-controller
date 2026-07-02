# Stage 17K-Z-R12T — Backup Restore Preview Helper

## Status

Source-only helper checkpoint.

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

## Added source

Added:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-restore-preview.js

This file is not loaded by index.html yet.

## Purpose

Add a preview-only restore helper for local backup files before any restore write path exists.

The helper can parse backup JSON text, validate the backup envelope, validate privacy flags, check required Study and media doc keys, and return a summary.

## Current behavior

The helper can:

- parse backup JSON text
- create a restore preview from a backup object
- summarize Study docs
- summarize media docs
- report required primary Study doc keys
- report required media doc keys
- assert the preview is write-disabled

The helper does not:

- read a user file directly
- write browser storage
- write IndexedDB
- overwrite local data
- persist media blobs
- parse Anki
- parse APKG
- mount UI
- deploy live

## Restore safety

Every preview returns:

- canWrite false
- writesEnabled false
- writeMode preview-only
- requiresExplicitConfirmation true
- overwriteExistingLocalData false

## Privacy checks

The helper rejects or warns on unsafe privacy flags:

- serverUpload must be false
- ankiSourceMutation must be false
- sourceMutation must be false when present
- localOnly should be true

## Next recommended stage

R12U should wire the backup panel to load schema, media export, and restore preview helpers behind the existing Profile card, but only expose a preview button or hidden test entry first.
