# Stage 17K-R14N-R2 — Restore Index Tail and Load Disabled Save View Model

## Status

Narrow VM200 static index repair deploy.

## Recovery note

R14N-R1 accidentally removed the tail of index.html while adding the disabled save button view model script.

The removed tail included Profile local backup mount, Anki preview scripts, Companion/Admin scripts, closed-beta guard, queued chat deferred loader, and closing body/html tags.

R14N-R2 restores index.html from the R14M good checkpoint and safely inserts exactly one script:

- privatepages/local-backup-current-file-disabled-save-button-view-model.js

## Changed file

- index.html

## Loaded asset

- privatepages/local-backup-current-file-disabled-save-button-view-model.js

## Exact delta

Compared with the R14M good checkpoint:

- removed scripts: none
- added scripts: disabled save button view model only

## No UI binding

R14N-R2 does not modify:

- profile-local-backups-mount.js
- profile-local-backups-panel.js
- privatepages.js
- privatepages/pages/profile.html

## Safety

No button.
No click handler.
No executor call.
No file write.
No current-file save in live UI.
No same-file write path in live UI.
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
