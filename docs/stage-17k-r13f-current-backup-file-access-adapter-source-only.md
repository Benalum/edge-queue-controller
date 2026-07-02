# Stage 17K-R13F — Current Backup File Access Adapter Source-Only

## Status

Source-only checkpoint.

No deploy.
No live UI change.

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-access.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS_ADAPTER_R13F_SOURCE_ONLY

## Purpose

This adds the read/recognition helper for the future stable current backup file:

- buddies-who-study-current.json

It can also classify timestamped files as manual snapshots:

- buddies-who-study-local-backup-v2-*.json

## Behavior

The adapter can:

- classify file names
- parse backup JSON text
- summarize backup contents
- create a restore-preview-only result
- read a user-selected File object after explicit user action
- create browser file chooser flow for read/preview only

## Safety

Read/preview only.

- canWrite false
- writesEnabled false
- writeMode preview-only
- no save helper
- no merge helper
- no restore helper
- no overwrite helper

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

## Next recommended stage

R13G should deploy this helper and add a preview-only button:

- Open current backup file

It should read and preview buddies-who-study-current.json, but still not save, merge, restore, or overwrite.
