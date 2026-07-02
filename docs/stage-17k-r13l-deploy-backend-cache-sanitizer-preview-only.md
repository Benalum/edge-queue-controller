# Stage 17K-R13L — Deploy Backend Cache Sanitizer Preview Only

## Status

Narrow VM200 static deploy.

## User-facing change

After opening buddies-who-study-current.json, the Profile local backup card now appends:

- current backup preview
- legacy backend cache sanitizer preview
- current backup save-plan preview

## Sanitizer preview

It detects legacy backend cache fields in study/store-state/v1.state:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

## Still not included

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/profile-local-backups-mount.js
- privatepages/local-backup-legacy-backend-cache-sanitizer.js

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
