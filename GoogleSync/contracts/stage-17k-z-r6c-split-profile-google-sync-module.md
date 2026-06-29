# Stage 17K-Z-R6C Split Profile GoogleSync UI Shell Into Clean Module

Status: source-only module split
Date: 2026-06-29
Baseline commit before this stage: ea83058

## Purpose

Move the Profile-only GoogleSync UI shell out of the Profile-adjacent Anki panel source and into a cleaner Profile GoogleSync module.

This stage also records the library decision: use official Google browser libraries later instead of custom OAuth or custom Drive protocol code.

## SAFETY_NON_ACTIVATION

- No backend deploy.
- No frontend deploy.
- No database writes.
- No Google OAuth activation.
- No Drive reads.
- No Drive writes.
- No model calls.
- No worker activation.
- No scheduler activation.
- No service restarts.
- No runtime feature flag changes.

## SOURCE_SPLIT

- Loader source: frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js
- New module source: frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js

The old Profile-adjacent source now acts as a small Profile-only loader.

The panel rendering, disabled controls, status copy, and official library decision now live in the cleaner Profile GoogleSync module.

## OFFICIAL_LIBRARY_DECISION

- Do not build custom OAuth.
- Future OAuth should use Google Identity Services JavaScript authorization.
- Future Drive operations should use the Google Drive REST API.
- Future user-selected files and folders should use Google Picker.
- Preferred Drive scope remains drive.file.
- appdata is reserved only for hidden app sync metadata if needed later.
- Broad Drive access is not part of the MVP direction.

## PROFILE_ONLY_RULE

- The module renders only when the current surface looks like Profile.
- Study must not render GoogleSync login controls.
- Companion must not render GoogleSync login controls.
- Admin must not render GoogleSync login controls.
- Global banner must not render GoogleSync login controls.
- Global navigation must not render GoogleSync login controls.

## UI_BEHAVIOR

- The Profile page shows Google Drive sync.
- Status is Not connected.
- Connect Google Drive is visible but disabled.
- Sync now is visible but disabled.
- The panel states that OAuth is not enabled yet.
- The panel states that no Drive reads or writes happen.

## FUTURE_LIVE_TEST_STAGE

The next stage that activates OAuth and Drive access must be separate from R6C.

That live stage must verify:

- Google Cloud OAuth client ID exists.
- Authorized JavaScript origin is configured.
- Test user consent works in browser.
- Token is kept in memory only for the first proof.
- Scope is narrow.
- First Drive test writes only a harmless APC test file after explicit consent.
- Rollback disables the Profile controls and removes any test file if requested.

## ACCEPTANCE_CRITERIA_FOR_THIS_STAGE

- New profile-google-sync-panel.js module exists.
- Old selected R6 source is reduced to a loader.
- Panel rendering code lives in the new module.
- New module contains official-library decision fields.
- No OAuth endpoints are called.
- No Drive API endpoints are called.
- No fetch calls are introduced.
- No Drive reads or writes are introduced.
- Existing GoogleSync validators pass.
- Changed files are limited to GoogleSync, the loader source, the new module, and the focused smoke.

## NEXT_RECOMMENDED_STAGE

Recommended next stage:

- Stage 17K-Z-R7 profile-only Google OAuth dev proof with explicit consent, narrow scope, one harmless Drive test file, and rollback.
