# Stage 5O-27 Generic Public Page Gates — 2026-06-11

## Result

Added public logged-out gates for generic wrapper pages.

## Why

Study and Companion/Chat have direct render branches, but Profile, Calendar, and Credits are rendered through the generic `pages[path]` branch.

## Expected behavior

Logged-out users should see public summaries for:

- `/profile`
- `/calendar`
- `/credits`

Logged-in users should see the usable pages.

Credits preloading is also guarded so logged-out users do not trigger private account credit calls.
