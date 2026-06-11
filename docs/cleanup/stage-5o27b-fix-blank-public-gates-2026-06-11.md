# Stage 5O-27B Fix Blank Public Gates — 2026-06-11

## Result

Fixed blank logged-out public feature pages.

## Cause

The previous public gate could treat stale localStorage/cookie tokens as an active session, letting logged-out users fall through into private page renderers. The renderer also depended on helper functions that could fail before filling the page.

## Change

- `hasActiveWrapperSession()` now requires both `authState.token` and `authState.user`.
- `renderPublicFeatureGate()` is self-contained and does not depend on `$()` or `escapeHtml`.
- Added an early public route gate for Study, Chat, Companion, Profile, Calendar, and Credits.

## Expected behavior

Logged-out users see public summaries.
Logged-in users see the actual usable pages after `/me` populates account state.
