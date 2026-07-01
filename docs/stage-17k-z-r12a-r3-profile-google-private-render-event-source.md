# Stage 17K-Z-R12A-R3 — Profile Google Private Render Event Source

## Status

Source-only narrow fix.

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

## Goal

Google Drive sync should appear only on the signed-in private Profile page.

It should not appear on the signed-out public Profile page.

## Fix

profile-google-sync-panel.js no longer creates the panel from URL path, title, DOMContentLoaded, hashchange, or popstate alone.

It creates the panel only from the existing private page event:

- apc-private-page-rendered
- detail.page === "profile"
- detail.user exists

Non-private lifecycle events only run cleanup.

## Changed file

Only one source file changed:

- privatepages/profile-google-sync-panel.js

## Not changed

This does not touch:

- index.html
- privatepages.js
- pages/profile.html
- anki-manifest-panel.js
- profile-anki-preview-mount.js
- session/auth gate
- private shell rendering
- Google OAuth behavior
- backend/runtime

## Not a wrapper or bandage

This does not create a second Profile page.

This does not add another auth layer.

This does not change routing.

It uses the existing private page render event that already carries the signed-in user and page identity.
