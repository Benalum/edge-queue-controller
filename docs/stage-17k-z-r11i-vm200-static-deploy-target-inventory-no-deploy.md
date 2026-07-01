# Stage 17K-Z-R11I — VM200 Static Deploy Target Inventory, No Deploy

## Status

Read-only deploy target inventory checkpoint.

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

Inventory the exact Profile Anki preview source files and live/static target clues before any controlled VM200 static deploy.

## Source files that would need static deployment

- frontend/wrapper-ui/apc-wrapper-local/index.html
- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-panel.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js

## Expected source script order

- privatepages/anki-import-local.js
- privatepages/profile-anki-import-bridge.js
- privatepages/profile-anki-preview-panel.js
- privatepages/profile-anki-preview-mount.js

## Read-only probes recorded

This stage records:

- local source file sizes and SHA-256 hashes
- local index.html script load order
- repo deploy/static reference scan
- public live pre-deploy static status codes
- public live pre-deploy marker scan
- best-effort VM200 SSH read-only static path probe

## Safety boundary

This stage does not:

- copy files
- rsync files
- restart services
- reload nginx
- mutate VM200
- mutate CT203
- deploy frontend assets
- activate backend routes
- store private Study or Anki data

## Recommended R11J

If the live target path is clear, run a controlled VM200 static frontend deploy of only the five listed files, then smoke:

- root still returns 200
- api me still returns 401 signed out
- signup remains 403
- private Study routes remain removed
- the four Anki preview scripts return 200
- live index contains the R11G cache-bust marker
