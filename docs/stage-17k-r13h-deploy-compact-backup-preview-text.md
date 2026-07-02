# Stage 17K-R13H — Deploy Compact Backup Preview Text

## Status

Narrow VM200 static deploy.

## User-facing change

Backup previews are now shorter and easier to read.

Current backup preview keeps:

- selected file name
- selected file role
- compact counts for decks/cards/sessions/media
- safety text

Merge preview keeps:

- merge plan summary
- file naming guidance
- safety text
- warnings/errors only when present

## Still not included

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## Deployed files

- index.html
- privatepages/profile-local-backups-merge-preview-bridge.js
- privatepages/local-backup-current-file-access.js

## Safety

Text formatting only.

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
No backup panel or mount behavior change.
