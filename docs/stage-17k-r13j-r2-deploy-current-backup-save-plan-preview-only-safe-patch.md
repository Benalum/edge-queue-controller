# Stage 17K-R13J-R2 — Deploy Current Backup Save-Plan Preview Only, Safe Patch

## Status

Narrow VM200 static deploy.

## Recovery note

The first R13J attempt failed before deploy because the mount success-handler patch was too exact.

R13J-R2 restores the failed local patch and uses a safer insertion around the current backup preview output call.

## User-facing change

After opening buddies-who-study-current.json, the Profile local backup card appends a save-plan preview.

## Still not included

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/profile-local-backups-mount.js
- privatepages/local-backup-current-file-save-plan.js

## Safety

Preview only.

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
No Profile backup panel source change.
No save/write/overwrite helper.
