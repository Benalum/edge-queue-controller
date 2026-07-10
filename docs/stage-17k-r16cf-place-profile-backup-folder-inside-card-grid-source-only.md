# stage-17k-r16cf-place-profile-backup-folder-inside-card-grid-source-only

Fixes the Profile local backup folder panel placement.

The backup folder workflow was functionally correct, but it was mounted outside the centered Profile card grid, so it rendered as a wide full-page block. This stage adds a small placement helper that moves the existing local backup folder panel into the same Profile card grid used by Local settings and Anki.

## Changes

- Added `privatepages/profile-backup-folder-card-placement-fix.js`.
- Loaded it after the backup folder/card DOM helpers.
- The helper finds the existing Local settings and Anki cards.
- The helper moves the Local backup folder panel into that same card container, before Anki when possible.
- Added scoped CSS to keep the panel width/buttons constrained once placed.

## Safety

Source-only. No deploy, no SSH, no sudo, no backend write, no Google Drive sync, no Anki write.
