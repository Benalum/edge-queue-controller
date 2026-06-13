# Stage 8W Frontend Router Shadow-Read Disabled Call Boundary

Generated: 2026-06-12

## Stage purpose

Stage 8W implements a frontend shadow-read call boundary without enabling browser router traffic.

This stage intentionally adds `/api/router/dry-run` only to `frontend/wrapper-ui/router_shadow_read_stub.js`.

## Strict scope

Stage 8W may:

- Add a disabled helper in `router_shadow_read_stub.js`.
- Add the backend dry-run endpoint string to the disabled stub only.
- Add a request builder that marks requests as dry-run and non-dispatching.
- Add a send helper that returns skipped while flags are false.
- Verify the helper does not call fetch while disabled.
- Verify `app.js` is not wired to call the helper.
- Verify backend dry-run remains disabled live.

Stage 8W must not:

- Add `/api/router/dry-run` to `frontend/wrapper-ui/app.js`.
- Enable `ROUTER_SHADOW_READ_ENABLED`.
- Enable `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT`.
- Enable live backend dry-run.
- Restart live services.
- Send browser-originated router traffic.
- Change `/tick`.
- Change queue behavior.
- Change power automation.

## Implemented boundary

The disabled stub now exposes:

- `ROUTER_DRY_RUN_ENDPOINT`
- `buildRouterDryRunShadowReadRequest`
- `sendRouterDryRunShadowRead`

The send helper must return skipped when either flag is false:

- `ROUTER_SHADOW_READ_ENABLED = false`
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`

## Required safety state after Stage 8W

After Stage 8W:

- `frontend/wrapper-ui/router_shadow_read_stub.js` contains `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` contains no `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` is not wired to `sendRouterDryRunShadowRead`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Disabled helper returns `router_shadow_read_disabled`.
- Disabled helper does not call fetch while flags are false.
- Live backend dry-run remains disabled.
- POST /api/router/dry-run remains HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` remains absent from the live controller environment.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Next recommended stage

Stage 8X should add a frontend disabled-boundary browser/runtime smoke that loads the live-served stub and proves no network request is sent while disabled.

Stage 8X should not enable browser router traffic.
## Exact smoke markers

- This stage intentionally adds /api/router/dry-run only to frontend/wrapper-ui/router_shadow_read_stub.js.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js is not wired to sendRouterDryRunShadowRead.

