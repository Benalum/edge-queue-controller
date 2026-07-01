# Stage 17K-Z-R11U — APKG Preview Mount Stable Profile DOM, Source Only

## Status

Source-only narrow APKG preview mount fix.

No deploy.
No frontend live mutation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.
No service restart.
No nginx reload.
No cloudflared mutation.

## Root cause

R11T showed the APKG preview scripts are loaded and served as real JavaScript, but the preview panel is not visible.

The stable private Profile DOM is:

- .private-shell[data-private-page="profile"]
- .private-grid

The old Anki chooser mounts because anki-manifest-panel.js targets .private-grid.

The R11G APKG preview mount did not target the current stable private Profile DOM, so the APKG preview panel did not attach.

## What changed

Only one source file changed:

- privatepages/profile-anki-preview-mount.js

The mount now recognizes the stable private Profile shell and uses the current Profile .private-grid as a mount target.

## What did not change

This does not touch:

- index.html
- privatepages.js
- pages/profile.html
- anki-manifest-panel.js
- profile-google-sync-panel.js
- session/auth gate
- private shell rendering
- Google Drive sync logic

## Why this is not a wrapper or bandage

This does not add a new Profile shell.

This does not change routing.

This does not duplicate Profile rendering.

It only points the existing APKG preview mount at the actual stable Profile DOM that already exists.

## Expected follow-up

If this source-only proof passes, deploy only:

- privatepages/profile-anki-preview-mount.js
