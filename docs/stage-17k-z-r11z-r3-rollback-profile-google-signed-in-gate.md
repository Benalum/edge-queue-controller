# Stage 17K-Z-R11Z-R3 — Rollback Profile Google Signed-In Gate

## Status

Emergency rollback of the R11Y/R11Z Profile Google signed-in gate.

The gate was too strict in live browser behavior and removed Google Drive sync from signed-in Profile as well.

## Live rollback

Restored from VM200 backup:

- /var/www/apc-wrapper-local/apc-r11z-profile-google-signed-in-gate-backup-20260701T171628Z

Restored live files:

- index.html
- privatepages/profile-google-sync-panel.js

## Source rollback

The same two source files were restored from the VM200 backup:

- frontend/wrapper-ui/apc-wrapper-local/index.html
- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js

## Safety boundary

No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No APKG mount change.
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

## Result

Google Drive sync is restored to the previous behavior.

The bad marker is absent:

- PROFILE_GOOGLE_SYNC_SIGNED_IN_PRIVATE_PROFILE_ONLY_R11Y_R2

## Next fix direction

Do not reapply the strict `APC_PRIVATEPAGES.me()` timing gate.

The next attempt must be proven in browser first and should likely use the actual private render event detail or a safer mount lifecycle, not just synchronous global state timing.
