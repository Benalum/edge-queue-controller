# Stage 17K-R13D — Deploy Stable Current Backup Preview Wording

## Status

Narrow VM200 static deploy.

## User-facing change

The Preview backup file output now explains the stable backup filename plan.

It should tell users:

- the normal file to keep using is buddies-who-study-current.json
- timestamped downloads are manual snapshots
- normal browser downloads may create duplicate files
- updating the same file later requires a user-selected file or folder
- no data was restored or overwritten

## Deployed files

- index.html
- privatepages/local-backup-stable-file-plan.js
- privatepages/profile-local-backups-merge-preview-bridge.js

## Still not included

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Safety

Preview wording only.

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
No Profile local backups panel change.
No Profile local backups mount change.
