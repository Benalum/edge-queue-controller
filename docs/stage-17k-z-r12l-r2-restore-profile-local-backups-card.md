# Stage 17K-Z-R12L-R2 — Restore Profile Local Backups Card

## Status

Narrow restore/fix and VM200 static deploy.

## Problem

After R12K, the signed-in private Profile page no longer showed the Buddies Who Study local backups card.

## Fix

The local backups card rendering was rewritten plainly:

- title: Buddies Who Study local backups
- copy: Save your data locally.
- buttons remain:
  - Choose local backup folder
  - Download backup file

The initial status text remains hidden until there is a user-triggered status or error.

The mount script now mounts when the private Profile shell exists, including cases where the direct-loaded script misses the initial private render event.

## Deployed files

Only four files were deployed:

- index.html
- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js
- privatepages/profile-private-polish.css

## Safety

No wrapper.
No broad shell rewrite.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Anki logic change.
No Google Drive sync logic change.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No server private Study persistence.
No Anki source file mutation.
No real SQLite collection parsing.
No media extraction.
No service restart.
