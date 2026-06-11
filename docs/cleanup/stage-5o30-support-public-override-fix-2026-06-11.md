# Stage 5O-30 Support Public Override Fix — 2026-06-11

## Result

Fixed Support still showing its old logged-out support panel.

## Cause

The clean Support renderer was still overriding the unified public feature gate and rendering:

- "Need help?"
- "Log in to send a message..."
- page-body login button

## Change

Logged-out `/support` now uses the shared public summary behavior.

Header owns login/create-account actions.

Support page body is informational only until the user logs in.
