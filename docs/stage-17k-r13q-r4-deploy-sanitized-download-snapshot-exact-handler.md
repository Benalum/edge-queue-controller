# Stage 17K-R13Q-R4 — Deploy Sanitized Download Snapshot Exact Handler

## Status

Narrow VM200 static deploy.

## Recovery

R13Q and R13Q-R2 failed before deploy because they assumed the download handler directly used JSON.stringify(payload).

R13Q-R3 proved the active R12Y handler calls:

- panelApi.createDownloadUrl(payload)
- panelApi.backupFileName(payload && payload.createdAt)

R13Q-R4 patches that exact handler.

## User-facing change

The Download snapshot button now routes the backup JSON through the sanitized snapshot output helper before starting the browser download.

## Sanitized output

The downloaded snapshot should exclude legacy backend cache fields from the output payload:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

## Still not included

No current-file save.
No File System Access API write.
No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
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
No Profile backup panel source change.
No same-file write path.
