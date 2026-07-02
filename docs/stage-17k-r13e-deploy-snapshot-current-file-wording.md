# Stage 17K-R13E — Deploy Snapshot / Current-File Backup Wording

## Status

Narrow VM200 static deploy.

## User-facing change

The local backup card now separates the two backup ideas:

- Download snapshot: timestamped safety copy
- buddies-who-study-current.json: future normal current-file merge backup

The old button copy "Download backup file" is replaced with "Download snapshot".

## Still not included

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/profile-local-backups-panel.js

## Safety

Copy/wording only.

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
No Profile local backups mount change.
