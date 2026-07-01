# Stage 17K-Z-R12N-R4 — Profile Google Sync Grid Placement

## Status

Narrow VM200 static deploy.

## Problem

The signed-in Profile Google Drive sync panel rendered as a full-width strip below the Profile cards instead of matching the card grid.

## Fix

Google Drive sync now appends to the private Profile grid by changing `findProfileAnchor()`.

Preferred host:

- `.private-shell[data-private-page="profile"] .private-grid`

Fallback host:

- `.private-shell[data-private-page="profile"]`

The private Profile render gate remains:

- `apc-private-page-rendered`
- `detail.page === "profile"`
- `detail.user`

## Deployed files

Only three files were deployed:

- index.html
- privatepages/profile-google-sync-panel.js
- privatepages/profile-private-polish.css

## Safety

No broad shell rewrite.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Google consent logic change.
No OAuth activation change.
No local backups logic change.
No Anki logic change.
No backend route addition.
No DB write.
No signup change.
No service restart.
