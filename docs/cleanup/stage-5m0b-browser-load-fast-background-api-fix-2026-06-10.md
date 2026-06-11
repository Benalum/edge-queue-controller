# Stage 5M-0B Browser Load Fast Background API Fix — 2026-06-10

## Result

Fixed slow browser page-load background API behavior before continuing Companion-only work.

## Problem

/api/system/public-status, /api/presence/web, and /api/presence/apply-power-policy could route into slow gateway/controller paths and return Cloudflare-style 502 behavior after about 30 seconds.

That slowed page load, confused login behavior, and surfaced raw gateway-style failures for non-critical background calls.

## Changes

- Made /api/system/public-status return a fast controlled wrapper response before generic API proxy routing.
- Made /api/presence/web return a fast controlled wrapper response before generic API proxy routing.
- Made /api/presence/apply-power-policy return a fast controlled wrapper response before generic API proxy routing.
- Preserved the Stage 5M-0A auth background failure guard so login success is not reversed by non-critical refresh failures.
- Kept full /api/system/status out of normal page startup behavior.

## Smoke

- /chat returned 200 in about 0.014 seconds.
- /companion returned 200 in about 0.001 seconds.
- /styles.css returned 200 in about 0.001 seconds.
- /app.js returned 200 in about 0.002 seconds.
- /queued_chat_config.js returned 200 in about 0.001 seconds.
- /queued_chat_status.js returned 200 in about 0.001 seconds.
- /api/system/public-status returned 200 in about 0.001 seconds.
- /api/presence/web returned 200 in about 0.001 seconds.
- /api/presence/apply-power-policy returned 200 in about 0.001 seconds.

## Boundary

This stage does not build new Companion features.
It makes browser load and login stable before Companion-only conversion.
