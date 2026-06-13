# Stage 8X Live-Served Frontend Router Shadow-Read Disabled Boundary Smoke

Generated: 2026-06-12

## Stage purpose

Stage 8X verifies that the frontend router shadow-read boundary remains disabled locally and, when available, in the live-served frontend stub.

Stage 8X does not enable browser router traffic.

## Strict scope

Stage 8X may:

- Inspect local frontend files.
- Fetch live-served static frontend JavaScript with GET only.
- Evaluate the local disabled stub in a Node VM.
- Evaluate the live-served disabled stub in a Node VM if the static file is available.
- Prove the disabled helper returns skipped.
- Prove the disabled helper does not call fetch while flags are false.
- Verify backend dry-run remains disabled.
- Verify queue/timer safety.

Stage 8X must not:

- Enable `ROUTER_SHADOW_READ_ENABLED`.
- Enable `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT`.
- Enable `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
- Restart live services.
- Send browser-originated router POST traffic.
- Wire `app.js` to `sendRouterDryRunShadowRead`.
- Change `/tick`.
- Change queue behavior.
- Change power automation.

## Required safety state after Stage 8X

After Stage 8X:

- `frontend/wrapper-ui/router_shadow_read_stub.js` contains `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` contains no `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` is not wired to `sendRouterDryRunShadowRead`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Local disabled helper returns `router_shadow_read_disabled`.
- Local disabled helper does not call fetch while flags are false.
- Live-served disabled helper returns `router_shadow_read_disabled` if the live static stub is reachable.
- Live-served disabled helper does not call fetch while flags are false if the live static stub is reachable.
- POST /api/router/dry-run remains HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` remains absent from the live controller environment.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Next recommended stage

Stage 8Y should prepare the controlled frontend shadow-read activation and rollback plan only.

Stage 8Y should not enable browser router traffic yet.
