# Stage 17K-Z-R7D VM200 Deploy appDataFolder Profile GoogleSync Proof

Status: VM200 frontend static deploy with generated runtime Google client ID config
Date: 2026-06-29
Baseline commit before this stage: 75204ab

## Purpose

Deploy the Profile-only GoogleSync proof to VM200 using Google Drive appDataFolder hidden app data mode.

The real Google OAuth client ID is not committed to git. It is generated into the VM200 live static root as `/privatepages/google-sync-config.js`.

## Runtime Boundary

- Scope: `https://www.googleapis.com/auth/drive.appdata`.
- Storage: `appDataFolder`.
- Profile page only.
- No browsing normal Drive files or folders.
- No visible Drive folder is created.
- Access token remains memory-only in the browser.
- No backend token storage.

## Deployment Boundary

- VM200 frontend static deploy only.
- No backend deploy.
- No database writes.
- No model calls.
- No worker or scheduler activation.
- No service restarts.

## Browser Smoke

1. Open Profile.
2. Confirm GoogleSync appears only on Profile.
3. Confirm status is `Ready for explicit consent`.
4. Check the explicit consent checkbox.
5. Click `Connect Google Drive`.
6. Complete Google consent.
7. Click `Create hidden APC sync database`.
8. Confirm manifest and database file IDs are displayed.
9. Click `Read APC app data metadata`.
10. Click `Rollback/delete APC proof files`.
11. Confirm rollback success.
