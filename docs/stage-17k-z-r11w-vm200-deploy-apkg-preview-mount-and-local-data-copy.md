# Stage 17K-Z-R11W — VM200 Deploy APKG Preview Mount and Local Data Copy

## Status

Controlled narrow VM200 static frontend deploy checkpoint.

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

## Deployed files

Only these three files were deployed:

- index.html
- privatepages/profile-anki-preview-mount.js
- privatepages/profile-google-sync-panel.js

index.html changed only to cache-bust the two changed JavaScript files.

## Live changes

R11U APKG preview mount fix is live:

- profile-anki-preview-mount.js recognizes the stable Profile DOM
- .private-shell[data-private-page="profile"] .private-grid

R11V-R2 copy change is live:

- Buddies Who Study local data
- Create hidden Buddies Who Study local data database
- Read Buddies Who Study local data metadata
- Rollback/delete Buddies Who Study local data proof files

## Expected browser behavior

Profile should remain stable across hard refresh and header navigation.

Profile should show:

- Account
- Google Drive sync with Buddies Who Study local data wording
- old Anki chooser
- Anki package preview panel

## Rollback

A narrow VM200 backup was created under:

- /var/www/apc-wrapper-local/apc-r11w-apkg-preview-local-data-copy-backup-<timestamp>

Rollback only needs to restore the same three files.
