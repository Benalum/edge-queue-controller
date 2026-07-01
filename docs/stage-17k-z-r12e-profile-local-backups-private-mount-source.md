# Stage 17K-Z-R12E — Profile Local Backups Private Mount Source

## Status

Source-only mount module addition.

No deploy.
No frontend live mutation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No email send.
No Anki source file mutation.
No local Study doc write during source smoke.
No real SQLite collection parsing.
No media extraction.
No service restart.
No nginx reload.
No cloudflared mutation.

## Purpose

Add the source-only mount script for the Profile card:

- Buddies Who Study local backups

## Mount rule

The local backups card mounts only from the private page event:

- apc-private-page-rendered
- detail.page === "profile"
- detail.user exists

Non-private lifecycle events only run cleanup.

## User actions

The mounted card supports:

- Choose local backup folder
- Download backup file

Folder saving uses the R12D source module and the browser File System Access API when supported.

Download backup uses a browser Blob URL and does not upload anything.

## Files changed

Added:

- privatepages/profile-local-backups-mount.js

This stage intentionally does not change:

- index.html
- privatepages.js
- pages/profile.html
- anki-manifest-panel.js
- profile-google-sync-panel.js
- profile-anki-preview-mount.js
- profile-local-backups-panel.js

## Safety

This mount does not call fetch, XMLHttpRequest, sendBeacon, or backend APIs.

It does not read, write, or mutate Anki source files.

It does not store a selected folder handle yet.

## Next stage

Deploy by loading:

- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js

from index.html with a fresh cache-bust.
