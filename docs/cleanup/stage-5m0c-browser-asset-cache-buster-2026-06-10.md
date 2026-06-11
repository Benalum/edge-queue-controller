# Stage 5M-0C Browser Asset Cache Buster — 2026-06-10

## Result

Bumped the wrapper app.js asset version so browsers load the Stage 5M-0B background API speed fixes instead of a stale cached app.js URL.

## Problem

The browser was still loading app.js?v=20260609200419 after the fast background API fix.

That made browser-console testing confusing because old and new background API behavior could appear mixed together.

## Changes

- Updated frontend/wrapper-ui/index.html from app.js?v=20260609200419 to app.js?v=20260610225000.

## Smoke

- Local /chat served app.js?v=20260610225000.
- Public /chat served app.js?v=20260610225000.
- Public /api/system/public-status returned 200 in about 0.158 seconds.
- Public /api/presence/web returned 200 in about 0.159 seconds.
- Public /api/presence/apply-power-policy returned 200 in about 0.181 seconds.

## Boundary

This stage does not build new Companion features.
It makes sure browsers load the already-fixed wrapper JavaScript before Companion-only conversion continues.
