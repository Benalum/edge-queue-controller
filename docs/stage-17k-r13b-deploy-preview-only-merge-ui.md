# Stage 17K-R13B — Deploy Preview-Only Merge UI

## Status

Narrow VM200 static deploy.

## User-facing change

The existing Preview backup file button now uses the backup merge preview bridge.

The selected backup file should show:

- restore preview
- merge preview
- adds, updates, skips, and conflicts
- warnings and errors

## Still not included

No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/local-backup-merge-planner.js
- privatepages/profile-local-backups-merge-preview-bridge.js
- privatepages/profile-local-backups-mount.js

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
No Profile local backups panel change.
