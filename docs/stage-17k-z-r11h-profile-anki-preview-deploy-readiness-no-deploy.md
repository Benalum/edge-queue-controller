# Stage 17K-Z-R11H — Profile Anki Preview Deploy Readiness, No Deploy

## Status

Source-only deploy-readiness checkpoint.

No deploy.
No frontend live mutation.
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

## Goal

Prove the Profile Anki APKG preview source is ready for a later controlled static deploy.

This stage does not deploy. It only checks source consistency, script load order, smoke compatibility, and privacy boundaries.

## Source chain

The local wrapper source now loads these files in order:

- privatepages/anki-import-local.js
- privatepages/profile-anki-import-bridge.js
- privatepages/profile-anki-preview-panel.js
- privatepages/profile-anki-preview-mount.js

## Expected behavior after a later deploy

The Profile tab should be able to show a local-only APKG preview panel.

A user can select an APKG file. The browser inspects ZIP/package metadata locally and shows:

- file name
- file size
- APKG container yes/no
- collection.anki2 present yes/no
- collection.anki21 present yes/no
- media manifest present yes/no
- numeric media entry count
- warnings
- entry summaries

## Safety boundary

The Profile Anki preview chain does not:

- fetch network resources
- call backend routes
- write APC_LOCAL_SAVE docs
- write localStorage
- open IndexedDB
- mutate original Anki files
- parse SQLite rows
- extract media files
- upload private Study or Anki data

## Deployment note

A later deploy stage should copy only VM200 static frontend assets, then smoke public static asset availability and browser behavior.

Do not deploy from this stage.
