# Stage 7X-2 Wrapper System UI Full Status Endpoint

Stage 7X-2 fixes the browser-facing System UI status source.

## Problem

The frontend `loadSystemStatus()` function was loading:

- `api("/system/public-status")`

Through the wrapper API helper, this maps to the lightweight public heartbeat route:

- `/api/system/public-status`

That route intentionally reports:

- `overall_state: unknown`

It only proves the wrapper is reachable. It is not the full platform status.

Because the System UI was using the lightweight heartbeat as `lastStatus`, the System page and drawer could show unknown/offline-looking fallback values even while the backend, server, CT101, and worker were online.

## Correct status source

The public wrapper exposes the full JSON status at:

- `/api/system/status`

In frontend code, the wrapper API helper should call:

- `api("/system/status")`

This keeps browser-facing routing correct because `api(...)` maps system API paths through the wrapper `/api/...` route.

## Verified behavior

The direct public route:

- `/system/status`

serves the SPA HTML page through the wrapper and should not be used as a browser fetch JSON endpoint.

The browser-facing JSON route is:

- `/api/system/status`

## Safety boundary

This stage does not restart the controller.

This stage does not call `/tick`.

This stage does not re-enable the legacy scheduler timer.

This stage does not change router dispatch behavior.
