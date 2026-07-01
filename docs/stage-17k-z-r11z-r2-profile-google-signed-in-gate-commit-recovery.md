# Stage 17K-Z-R11Z-R2 — Profile Google Signed-In Gate Commit Recovery

## Status

Commit recovery checkpoint after interrupted R11Z.

R11Z already deployed the live VM200 static files and public/API smoke passed before timeout.

R11Z-R2 does not redeploy. It records and commits the already-live signed-in gate cache-bust and evidence.

## Live deploy already completed

R11Z deployed only:

- index.html
- privatepages/profile-google-sync-panel.js

Live backup created by R11Z:

- /var/www/apc-wrapper-local/apc-r11z-profile-google-signed-in-gate-backup-20260701T171628Z

## Live behavior intended

Signed-out public Profile should not show Google Drive sync.

Signed-in private Profile should still show Google Drive sync with Buddies Who Study local data wording.

## Safety boundary

No deploy in R11Z-R2.
No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
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
