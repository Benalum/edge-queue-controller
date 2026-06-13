# Stage 8L Disabled Study Router Shadow-Read Observation Call

Stage 8L adds one controlled disabled frontend observation call near the existing Study command path.

## Files Changed

- `frontend/wrapper-ui/app.js`
- `frontend/wrapper-ui/index.html`

## Purpose

Stage 8K loaded the disabled router shadow-read stub.

Stage 8L adds a passive observation wrapper in `app.js` and calls it before the first Study command API call.

## Safety

Stage 8L does not:

- enable router shadow-read
- call `/api/router/dry-run` from `app.js`
- change the Study command API path
- replace Study behavior
- dispatch based on router output
- enable the live router endpoint
- restart the live controller
- call models
- change Companion behavior

## Why It Is Safe

The wrapper checks:

- `window.EdgeRouterShadowRead.ROUTER_SHADOW_READ_ENABLED === true`

Because the stub still has:

- `ROUTER_SHADOW_READ_ENABLED = false`

the wrapper immediately returns a skipped object and does not call the router.

## Guard

Even if someone accidentally flips the loaded helper later, Stage 8L passes a guarded API function that throws instead of making a network request.

## Decision

Stage 8L proves the first controlled frontend observation call can exist without creating router traffic.

Stage 8M should inspect live browser behavior and network logs, then decide whether to keep the observation call or move toward a real disabled shadow-read feature flag.
