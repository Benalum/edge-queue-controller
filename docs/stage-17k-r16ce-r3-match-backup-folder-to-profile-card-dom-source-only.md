# Stage 17K R16CE-R3 — Match backup folder to Profile card DOM

Purpose: make the Profile `Local backup folder` section visually mimic the existing `Local settings` and `Anki` boxes instead of relying on guessed standalone styling.

Changes:
- Adds `privatepages/profile-backup-folder-card-dom-match.js`.
- At runtime, the helper finds the `Local backup folder` card.
- It copies useful classes from the existing `Local settings` card, falling back to the `Anki` card.
- It adds a small scoped fallback style for cache/load-order safety.
- It keeps the folder backup logic unchanged.

Safety:
- Source-only.
- No deploy.
- No SSH.
- No sudo.
- No backend upload.
- No Google Drive sync.
- No Anki write behavior.
