# Stage 17K-Z-R12F — VM200 Deploy Profile Local Backups

## Status

Narrow VM200 static deploy.

## Deployed files

Only three files were deployed:

- index.html
- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js

index.html changed only to load:

- profile-local-backups-panel.js
- profile-local-backups-mount.js

with a fresh cache-bust.

## Live feature

Adds a signed-in private Profile card:

- Buddies Who Study local backups

The card mounts only from:

- apc-private-page-rendered
- detail.page === "profile"
- detail.user exists

## Actions

The card offers:

- Choose local backup folder
- Download backup file

Folder save uses the browser File System Access API only if the browser supports it.

Download backup uses a browser Blob URL fallback.

## Safety

No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Google Drive or OAuth activation.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No server private Study persistence.
No Anki source file mutation.
No local Study doc mutation beyond user-triggered browser-local backup export.
No real SQLite collection parsing.
No media extraction.
No service restart.
