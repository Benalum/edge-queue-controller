# Stage 17K-Z-R12D — Profile Local Backups Panel Source, No Mount

## Status

Source-only module addition.

No mount.
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

Add a separate Profile source module for:

- Buddies Who Study local backups

This is separate from:

- Anki source files
- Google Drive sync
- server storage

## User-facing design

The Profile card should explain:

- Save a copy of your Buddies Who Study local data to a folder you choose on this device.
- This does not upload anything.
- This does not modify Anki files.
- This does not browse your other files.
- Do not choose your Anki profile folder. Use a separate backup folder.

## Technical design

Primary data authority remains browser-local data.

The module can build a backup payload for known Study docs:

- study/cards/v1
- study/decks/v1
- study/progress/v1
- study/sessions/v1
- study/store-state/v1

The module supports:

- File System Access folder writes when `showDirectoryPicker` exists
- download JSON fallback helpers

## Safety rules

The backup payload declares:

- uploadsToServer: false
- modifiesAnkiSourceFiles: false
- includesAnkiSourceFileBytes: false

## Files changed

Added:

- privatepages/profile-local-backups-panel.js

This stage intentionally does not change:

- index.html
- privatepages.js
- pages/profile.html
- anki-manifest-panel.js
- profile-google-sync-panel.js
- profile-anki-preview-mount.js

## Next stage

After source proof, mount this panel on signed-in private Profile only.
