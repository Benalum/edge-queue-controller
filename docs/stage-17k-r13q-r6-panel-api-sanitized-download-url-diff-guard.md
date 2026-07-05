# Stage 17K-R13Q-R6 — Panel API Sanitized Download URL Diff Guard

## Status

Narrow VM200 static deploy.

## Why

R13Q-R4 patched the mount download handler, but the uploaded proof file still contained legacy backend cache fields.

R13Q-R5 then correctly targeted `panelApi.createDownloadUrl(payload)` but failed before deploy because the safety grep matched older existing folder-write code in `profile-local-backups-panel.js`.

R13Q-R6 uses a diff-only write-API guard and hardens the panel API source of truth.

## User-facing behavior

Download snapshot should now produce a JSON file that excludes:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

## Still not included

No current-file save.
No File System Access API same-file write.
No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js
- privatepages/local-backup-sanitized-snapshot-output-helper.js

## Safety

Browser download only.

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
No same-file write path.
