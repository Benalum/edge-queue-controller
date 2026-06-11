# Stage 5O-32 Profile After-Login Gate Fix — 2026-06-11

## Result

Fixed Profile staying on the public summary after login.

## Cause

The public page gate requires confirmed auth state. Profile could render before `/me` populated `authState.user`, then stay on the logged-out summary.

## Change

- Added explicit auth-ready helpers.
- Re-render current gated route after `/me` confirms the user.
- Kept stale token protection so logged-out users do not hit private loaders.

## Expected behavior

Logged out:

- Profile shows public summary.

Logged in:

- Profile switches to the real Profile page after auth state is confirmed.
