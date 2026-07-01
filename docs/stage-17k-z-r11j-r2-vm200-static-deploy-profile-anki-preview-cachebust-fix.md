# Stage 17K-Z-R11J-R2 — VM200 Static Deploy Profile Anki Preview Cache-Bust Fix

## Status

Controlled VM200 static frontend deploy repair checkpoint.

This stage repairs the failed R11J evidence by replacing the pre-probed cache-bust URL with a new cache-bust string and redeploying the same Profile Anki preview static files.

No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.
No service restart.
No nginx reload.
No cloudflared mutation.

## Why R11J-R2 was needed

R11J deployed files to VM200, but the postdeploy public script smoke timed out after the first script URL still returned a 10611-byte HTML fallback.

The likely cause was that R11J pre-probed the future script URLs before the files existed, caching fallback HTML at those exact cache-bust URLs.

R11J-R2 fixes this by updating index.html to a new cache-bust string and only requesting the new URLs after deployment.

## Deployed files

Static root:

- /var/www/apc-wrapper-local

Files deployed:

- index.html
- privatepages/anki-import-local.js
- privatepages/profile-anki-import-bridge.js
- privatepages/profile-anki-preview-panel.js
- privatepages/profile-anki-preview-mount.js

## Smoke proof

The repair smoke verifies:

- VM200 local HTTP serves each script as JavaScript, not HTML fallback
- public root returns 200
- public index contains the R11J-R2 cache-bust marker
- public Anki preview scripts return JavaScript, not HTML fallback
- each public script exposes the expected marker
- system status remains 200
- signed-out /api/me remains 401
- signup remains 403
- private Study decks route does not return 200

## Rollback safety

The run probes the pre-R11J backup index before deploy and installs an error trap. If postdeploy smoke fails, it attempts to restore the safe pre-R11J index on VM200.
