# Stage 7W-1 Fix Legacy Tick Web Presence Pause NameError

Stage 7W-1 fixes a runtime crash in the legacy scheduler route:

- `POST /tick`

## Problem

The active scheduler timer was calling:

- `POST /tick`

The route was failing with:

- `NameError: name 'web_presence_start_pause_minutes' is not defined`

The modern power automation route was not the problem:

- `POST /power/auto/tick` returned HTTP 200

Worker remediation was also not the problem:

- `POST /workers/remediation/tick` returned HTTP 200

## Root cause

The legacy `/tick` route entered direct Ollama mode and attempted to call the guarded wake/start readiness path with:

- `pause_after_start_minutes=web_presence_start_pause_minutes`

But `web_presence_start_pause_minutes` was not defined in that function scope.

## Fix

The legacy `/tick` function now defines `web_presence_start_pause_minutes` locally using `_parse_int_env`:

- env: `WEB_POWER_START_PAUSE_MINUTES`
- default: `10`
- minimum: `1`
- maximum: `120`

## Browser safety

The first validation for this stage is source-only.

The live controller is not restarted during the source-only validation because restarting the controller can interrupt the browser session.

## Safety boundary

This stage does not enable router dispatch.

This stage does not enable model calls by itself.

This stage does not change the modern `/power/auto/tick` route.

This stage only prevents the legacy scheduler tick from crashing after the controller is restarted later.
