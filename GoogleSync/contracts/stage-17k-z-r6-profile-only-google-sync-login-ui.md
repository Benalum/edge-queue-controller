# Stage 17K-Z-R6 Profile-Only GoogleSync Login UI Contract

Status: source-only UI shell
Date: 2026-06-29
Baseline commit before this stage: 5e5a506

## Purpose

Add Google Drive sync and login visibility to the Profile page only.

This stage adds a Profile-only UI shell. It does not activate OAuth, does not call Google APIs, does not read Drive, and does not write Drive.

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

## PROFILE_ONLY_RULE

- GoogleSync login and sync controls belong on the Profile page only.
- A shared privatepages router source may contain the guarded code if the runtime guard only renders on Profile.
- Study page must not render GoogleSync login controls in this stage.
- Companion page must not render GoogleSync login controls in this stage.
- Admin page must not render GoogleSync login controls in this stage.
- Global navigation must not render GoogleSync login controls in this stage.
- Global banner must not render GoogleSync login controls in this stage.

## UI_BEHAVIOR

- The Profile page shows a Google Drive sync panel.
- The panel shows Not connected.
- The panel includes Connect Google Drive and Sync now controls.
- The controls are disabled in this stage.
- The panel explains that OAuth is not enabled yet.
- The panel explains that no Drive reads or writes happen in this build.

## SOURCE_BOUNDARY

- The selected source file is recorded in GoogleSync/contracts/stage-17k-z-r6-profile-ui-source-path.txt.
- The source may be Profile-specific or a shared privatepages router.
- The runtime guard must keep rendering Profile-only.
- The GoogleSync contract documentation stays under GoogleSync/contracts.
- The only smoke file is under ops/smoke.
- No backend files are changed.
- No Study-specific source files are changed.
- No Companion-specific source files are changed.

## FUTURE_WIRING

A later approved stage may replace the disabled Profile controls with real OAuth wiring.

That later stage must separately define:

- OAuth client configuration.
- Exact Google scopes.
- Token handling.
- Consent copy.
- Drive folder picker behavior.
- Drive read/write smoke boundaries.
- Rollback plan.

## ACCEPTANCE_CRITERIA_FOR_THIS_STAGE

- Selected source contains the unique GoogleSync Profile-only marker.
- No Study-specific or Companion-specific source contains the unique marker.
- The UI block contains no Google API calls.
- The UI block contains no OAuth endpoint calls.
- The UI block contains no fetch calls.
- The UI block contains no Drive write calls.
- Changed files are limited to GoogleSync, the selected source, and the focused smoke.
- Existing GoogleSync validators still pass.

## NEXT_RECOMMENDED_STAGE

Recommended next stage:

- Stage 17K-Z-R7 profile-only disabled Google OAuth consent copy and state machine, no OAuth activation, no Drive writes.
