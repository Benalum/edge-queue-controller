# Stage 9C Narrow Browser-Surface Shadow-Read Wiring Plan

Generated: 2026-06-12

## Stage purpose

Stage 9C prepares the narrow browser-surface router shadow-read wiring plan only.

Stage 9C does not modify frontend/wrapper-ui/app.js.
Stage 9C does not enable browser router traffic.
Stage 9C does not enable backend router dry-run.
Stage 9C does not restart live services.
Stage 9C does not send frontend router POST traffic.

## Current proven state

Stage 9A proved one controlled full-stack frontend shadow-read request can be sent safely through the live-served stub while backend dry-run is temporarily enabled.

Stage 9B proved the Stage 9A rollback stayed stable after push.

## Required current live state

After Stage 9C:

- Stage 9A evidence final_result remains pass.
- Stage 9B evidence final_result remains pass.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js is not wired to sendRouterDryRunShadowRead.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false
- Live-served app.js contains no /api/router/dry-run.
- Live-served app.js is not wired to sendRouterDryRunShadowRead.
- Live-served router shadow-read stub remains disabled.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 9D proposal

Stage 9D may add disabled browser-surface wiring behind strict guards.

Stage 9D should add one narrow frontend call site only.

The future wiring should require all of these before any request can happen:

1. `window.EdgeRouterShadowRead.ROUTER_SHADOW_READ_ENABLED === true`
2. `window.EdgeRouterShadowRead.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT === true`
3. A local surface allowlist includes the active surface.
4. The helper is called with `dry_run: true`.
5. The payload includes `dispatch_requested: false`.
6. The payload includes `dispatch_performed: false`.
7. The backend is in dry-run mode.
8. The request count is capped during smoke.

Stage 9D should keep default browser traffic disabled.

Stage 9D should not enable backend dry-run by default.

Stage 9D should not make `/api/router/dry-run` appear directly in frontend/wrapper-ui/app.js.

Stage 9D should only call `sendRouterDryRunShadowRead` through the existing router shadow-read stub boundary.

## Future Stage 9D no-go triggers

Stage 9D must stop or roll back if:

- `app.js` directly contains `/api/router/dry-run`.
- Browser traffic is enabled by default.
- Backend dry-run is enabled persistently.
- More than one controlled request can be sent in a smoke test.
- The response indicates dispatch.
- Queue changes unexpectedly.
- POST `/api/router/dry-run` remains HTTP 200 after rollback.
- Timers change unexpectedly.
- Port 7076 becomes active.
## Exact smoke markers

- Stage 9D should not make /api/router/dry-run appear directly in frontend/wrapper-ui/app.js.
- Stage 9D should only call sendRouterDryRunShadowRead through the existing router shadow-read stub boundary.

