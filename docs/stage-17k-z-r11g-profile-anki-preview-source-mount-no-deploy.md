# Stage 17K-Z-R11G — Profile Anki Preview Source Mount, No Deploy

## Status

Source-only implementation checkpoint.

No deploy.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.
No live frontend mutation.

## Goal

Wire the Profile-local Anki APKG preview source into the local wrapper source so the Profile tab can later show the APKG preview panel after deployment approval.

## Added source

- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js

## Updated source

- frontend/wrapper-ui/apc-wrapper-local/index.html

The local wrapper source now loads these browser-local Anki preview scripts in order:

- privatepages/anki-import-local.js
- privatepages/profile-anki-import-bridge.js
- privatepages/profile-anki-preview-panel.js
- privatepages/profile-anki-preview-mount.js

## Updated historical smokes

R11E and R11F originally asserted that the bridge and panel were not mounted.

R11G intentionally supersedes that no-mount boundary in source, so those smokes now accept the R11G source mount marker instead of failing future smoke runs.

## Safety boundary

The Profile Anki preview source mount does not:

- fetch network resources
- call backend routes
- write APC_LOCAL_SAVE docs
- write localStorage
- open IndexedDB
- mutate original Anki files
- parse SQLite rows
- extract media files
- deploy live UI

## User-facing result after a future deploy

The Profile tab should be able to show a local-only APKG preview panel.

The preview should allow a user to choose an APKG file and inspect only ZIP/package metadata locally:

- file name
- file size
- APKG container yes/no
- collection.anki2 present yes/no
- collection.anki21 present yes/no
- media manifest present yes/no
- numeric media entry count
- warnings
- entry summaries

## Recommended R11H

Do a source/package smoke for the Profile Anki preview mount, then perform a controlled VM200 static deploy only if explicitly approved.
