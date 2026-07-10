# Stage 17K R16BW — Profile-only companion picker and Support-only session gate

This stage is source-only.

## What changed

- Companion preset selection now lives only in Profile.
- The Companion page no longer shows the duplicated "Choose companion" / companion name / video URL settings block.
- Companion still reads the saved local Profile companion settings and reflects the selected name/media.
- The session-check overlay is restricted to Support/Admin routes.
- Study, Companion, and Profile no longer show the "Checking session..." overlay as part of normal local-first navigation.

## Intended product behavior

- Users configure companion choice in Profile.
- Built-in list currently contains Sol.
- Users can still use custom media through Profile settings.
- Study, Companion, and Profile remain local-first.
- Support remains the account-gated route where session checks are useful.

## Safety rails

- No VM deploy.
- No SSH.
- No sudo.
- No backend mutation.
- No database mutation.
- No Google Drive sync activation.
- No Anki mutation.
- No private user data copied.
