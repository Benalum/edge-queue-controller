# Stage 17K-Z-R12V — Deploy Profile Backup Preview Button

## Status

Narrow VM200 static deploy.

## User-facing change

The signed-in Profile local backups card now includes:

- Choose local backup folder
- Download backup file
- Preview backup file

Preview backup file lets the user select a backup JSON file and see a summary.

## Restore safety

Preview only.

No restore write path exists in this stage.

The preview path preserves:

- canWrite false
- writesEnabled false
- writeMode preview-only
- requiresExplicitConfirmation true
- overwriteExistingLocalData false

## Deployed files

- index.html
- privatepages/local-backup-media-schema.js
- privatepages/local-media-vault.js
- privatepages/local-backup-media-export.js
- privatepages/local-backup-restore-preview.js
- privatepages/profile-local-backups-restore-preview-bridge.js
- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js

## Safety

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
