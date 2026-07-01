# Stage 17K-Z-R12H-R2 — Anki Private Profile Event Source

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

## Problem

Signed-out hard refresh of `/profile` briefly showed the old Anki chooser before public routing finished.

Diagnosis confirmed the Anki chooser still mounted from URL/path/Profile DOM hints and hard-refresh lifecycle events.

## Fix

`privatepages/anki-manifest-panel.js` now mounts only from the private Profile render event:

- `apc-private-page-rendered`
- `detail.page === "profile"`
- `detail.user` exists

Non-private lifecycle events only run cleanup:

- `DOMContentLoaded`
- `popstate`
- `hashchange`
- `apc-auth-changed`

The mount host is limited to:

- `.private-shell[data-private-page='profile'] .private-grid`
- `.private-shell[data-private-page='profile']`

## Changed file

Only one existing source file changed:

- privatepages/anki-manifest-panel.js

## Not changed

This does not touch:

- index.html
- privatepages.js
- pages/profile.html
- profile-google-sync-panel.js
- profile-local-backups-panel.js
- profile-local-backups-mount.js
- profile-anki-preview-mount.js
- backend/runtime

## Expected behavior after deploy

Signed-out hard refresh `/profile`:

- no Anki chooser flash

Signed-in private `/profile`:

- Anki chooser remains visible
- copy says Buddies Who Study
