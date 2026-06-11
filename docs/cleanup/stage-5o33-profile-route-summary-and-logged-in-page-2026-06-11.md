# Stage 5O-33 Profile Route Summary and Logged-In Page Fix — 2026-06-11

## Result

Fixed Profile showing the Credits public summary while logged out.

Added a real logged-in Profile account surface.

## Changes

- Public feature gate now prefers the actual browser pathname when selecting summary content.
- Public `/profile` summary is explicitly Profile text.
- Logged-in `/profile` now renders account, plan, credits, security, permissions, preferences, and connected-provider cards.
- `/profile` has a direct render branch instead of falling through the generic feature summary renderer.

## Expected behavior

Logged out:

- `/profile` shows the Profile public summary.

Logged in:

- `/profile` shows account/profile cards instead of the old generic feature summary.
