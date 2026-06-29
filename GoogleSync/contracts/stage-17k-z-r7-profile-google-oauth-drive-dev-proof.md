# Stage 17K-Z-R7 Profile Google OAuth and Drive Dev Proof

Status: profile-only dev proof source
Date: 2026-06-29
Baseline commit before this stage: 8451db8

## Purpose

Add a Profile-only developer proof for Google OAuth consent and one harmless Google Drive test file.

This stage adds browser code that can run only after a Google OAuth web client ID is configured and the user explicitly consents in the Profile page.

PPB smoke does not perform OAuth, does not read Drive, and does not write Drive.

## Library Direction

- Do not build custom OAuth.
- Use Google Identity Services JavaScript authorization.
- Use Google Drive REST API for the harmless test file.
- Use Google Picker later when users choose existing files or folders.
- Use narrow drive.file access.
- Do not request broad Drive access.

## Explicit Consent

- The Profile UI includes a checkbox explaining that the test can create one harmless APC test file in Google Drive.
- Connect remains disabled until the checkbox is checked and a client ID is configured.
- Write test file remains disabled until a token is available.
- Rollback remains disabled until there is a created test file ID.

## Rollback

- Rollback is a Profile button that deletes the test file by file ID.
- The file ID is kept in browser session storage.
- The access token is kept in memory only.
- No refresh token is stored.

## Setup Required Before Browser Test

- Create or reuse a Google Cloud OAuth web client.
- Add the site origin as an authorized JavaScript origin.
- Configure the client ID in window.APC_GOOGLE_SYNC_CONFIG.googleClientId or a meta tag named apc-google-client-id.
- Open Profile.
- Check the explicit consent box.
- Click Connect Google Drive.
- Click Write harmless test file.
- Click Read test file metadata.
- Click Rollback/delete test file.

## Safety Boundary

- Profile page only.
- No backend deployment in this stage.
- No frontend deployment in this stage.
- No backend DB writes.
- No backend queue writes.
- No worker or scheduler activation.
- No model calls.
- No broad Drive scope.

## Acceptance Criteria

- Profile GoogleSync module contains the R7 dev proof marker.
- Profile GoogleSync module uses Google Identity Services token client.
- Profile GoogleSync module uses only narrow drive.file scope.
- Profile GoogleSync module can create one harmless APC test file after explicit consent.
- Profile GoogleSync module can read that test file metadata.
- Profile GoogleSync module can delete that test file as rollback.
- No token is stored in localStorage.
- No refresh token or client secret appears in source.
- Existing GoogleSync validators still pass.
- Smoke performs static verification only and does not call Google.

## Next Recommended Stage

- Stage 17K-Z-R7B configure local/dev Google client ID and browser-smoke the Profile OAuth flow.
