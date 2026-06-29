# Stage 17K-Z-R7B Google OAuth Client ID Injection Contract and Deploy-Gated Browser Test Plan

Status: contract and deploy-gated test plan only
Date: 2026-06-29
Baseline commit before this stage: 4543675

## Purpose

Define how the Google OAuth Web client ID is injected for the Profile-only GoogleSync dev proof without committing a real client ID to source.

This stage does not deploy, does not execute OAuth, does not read Drive, and does not write Drive.

## Current R7 Source Hooks

R7 already supports two client ID sources:

- `window.APC_GOOGLE_SYNC_CONFIG.googleClientId`.
- `<meta name="apc-google-client-id" content="...">`.

R7B chooses the runtime generated config script as the preferred deploy method.

## Recommended Runtime Injection

At deploy time, generate a public runtime config file outside committed source:

- Runtime URL: `/privatepages/google-sync-config.js`.
- Body shape: `window.APC_GOOGLE_SYNC_CONFIG = Object.freeze({ googleClientId: '<web-client-id>.apps.googleusercontent.com' });`.
- Add a cache-busted script tag before `profile-google-sync-panel.js` is loaded.
- Never commit the real client ID to repository source.

OAuth client IDs are public identifiers, not client secrets, but keeping them out of source lets us rotate or disable test config without changing code.

## Google Cloud Setup Gate

Before browser testing:

- Enable Google Drive API in the Google Cloud project.
- Configure the OAuth consent screen.
- Create an OAuth Client ID with application type `Web application`.
- Add the deployed origin as an authorized JavaScript origin.
- Add test users while the app is in testing mode, if applicable.
- Keep scope to `https://www.googleapis.com/auth/drive.file`.

## Deploy Gate

R7B does not deploy.

A later deploy-gated stage must:

- Generate `/privatepages/google-sync-config.js` on the deployed host.
- Inject the config script only into the private/Profile-capable wrapper page.
- Preserve Profile-only runtime rendering.
- Run static smokes before deploy.
- Run browser proof after deploy.
- Capture rollback evidence.

## Browser Test Plan

After deploy and client ID config:

1. Open the Profile page.
2. Confirm GoogleSync panel appears only on Profile.
3. Confirm the status is no longer `Google client ID not configured`.
4. Check the explicit consent checkbox.
5. Click `Connect Google Drive`.
6. Complete Google consent.
7. Click `Write harmless test file`.
8. Confirm a file named `APC GoogleSync Dev Proof ... .apc-test.json` was created.
9. Click `Read test file metadata`.
10. Click `Rollback/delete test file`.
11. Confirm rollback success.
12. Confirm no backend DB or queue write was needed for this proof.

## Rollback Plan

- Remove or disable the generated runtime config file.
- Remove the config script injection from deployed HTML if added.
- Use the Profile rollback button to delete the test file.
- If the Profile rollback button is unavailable, manually delete files named `APC GoogleSync Dev Proof` from Drive.
- Revert the deploy to the previous frontend artifact if the Profile page breaks.

## Explicit Non-Goals

- No real client ID committed.
- No broad Drive scope.
- No backend token storage.
- No localStorage token storage.
- No refresh token storage.
- No Study page GoogleSync controls.
- No Companion page GoogleSync controls.
- No Admin page GoogleSync controls.
- No production personal data sync yet.

## Acceptance Criteria

- R7 Profile module still supports both client ID injection hooks.
- Example config contains only placeholders.
- Contract records no OAuth or Drive execution in this stage.
- Contract records deploy-gated browser test plan.
- Smoke verifies no real Google client ID was committed.
- Smoke verifies the only Drive scope remains `drive.file`.
- Existing GoogleSync validators still pass.

## Next Recommended Stage

- Stage 17K-Z-R7C deploy Profile GoogleSync dev proof with generated client ID config and browser-smoke connect/write/read/rollback.
