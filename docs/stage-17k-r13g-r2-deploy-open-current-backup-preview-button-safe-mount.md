# Stage 17K-R13G-R2 — Deploy Open Current Backup File Preview Button, Safe Mount

## Status

Narrow VM200 static deploy.

## Recovery note

The first R13G attempt failed before deploy because it inserted raw HTML into the panel JavaScript string builder.

R13G-R2 avoids editing the panel source and injects the button from the mount layer.

## User-facing change

The local backups card should now show:

- Download snapshot
- Preview backup file
- Open current backup file

Open current backup file is read/preview only.

It is intended for:

- buddies-who-study-current.json

## Still not included

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/profile-local-backups-mount.js
- privatepages/local-backup-current-file-access.js

## Safety

Read/preview only.

No backend deploy.
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
No Profile Google sync change.
No Anki panel change.
No panel source edit.
