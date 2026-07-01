# Stage 17K-Z-R11N — VM200 Static Deploy Canonical Profile Render Path

## Status

Controlled VM200 static frontend deploy checkpoint.

Deployed the R11M-R2 canonical Profile source fix to VM200.

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

## Deployed files

Static root:

- /var/www/apc-wrapper-local

Files deployed:

- index.html
- privatepages/privatepages.js
- privatepages/pages/profile.html
- privatepages/anki-manifest-panel.js
- privatepages/profile-google-sync-panel.js
- privatepages/profile-anki-preview-mount.js

## Expected live behavior

Header Profile navigation and hard-refresh Profile should now show the same canonical Profile surface.

The duplicate Profile path was removed by:

- removing the legacy Google sync loader from anki-manifest-panel.js
- loading profile-google-sync-panel.js directly from index.html
- using explicit Profile feature hosts
- making Profile modules listen to apc-private-page-rendered

## Smoke proof

The deploy smoke verifies:

- VM200 local HTTP serves canonical Profile source files
- public static source files are not HTML fallbacks
- public index references the R11M-R2 cache-bust
- anki-manifest-panel.js no longer serves the legacy Google sync loader
- system status remains 200
- signed-out /api/me remains 401
- signup remains 403
- private Study decks route does not return 200

## Rollback

The deploy created a VM200 backup directory under:

- /var/www/apc-wrapper-local/apc-r11n-canonical-profile-backup-<timestamp>

Restore can copy those backed-up files back into /var/www/apc-wrapper-local.
