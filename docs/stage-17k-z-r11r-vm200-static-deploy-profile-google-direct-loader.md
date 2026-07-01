# Stage 17K-Z-R11R — VM200 Static Deploy Profile Google Direct Loader

## Status

Controlled narrow VM200 static frontend deploy checkpoint.

This deploys the R11Q source fix only.

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
- privatepages/anki-manifest-panel.js
- privatepages/profile-google-sync-panel.js

## What changed live

The stale indirect Google sync loader was removed from anki-manifest-panel.js.

index.html now loads profile-google-sync-panel.js directly.

profile-google-sync-panel.js now listens to apc-private-page-rendered, the event privatepages.js already dispatches.

## Expected browser behavior

Header Profile navigation and hard-refresh Profile should now both show the same Profile content.

The old Anki chooser may still appear.

Google Drive sync should appear consistently in both navigation paths.

## Rollback

A narrow VM200 backup was created under:

- /var/www/apc-wrapper-local/apc-r11r-profile-google-direct-loader-backup-<timestamp>

Rollback only needs to restore the same three files.
