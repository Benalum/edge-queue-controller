# Stage 9D Disabled Narrow Browser-Surface Shadow-Read Wiring

Generated: 2026-06-12

## Stage purpose

Stage 9D adds disabled narrow browser-surface shadow-read wiring behind strict guards.

Stage 9D keeps default browser router traffic disabled.
Stage 9D does not enable backend router dry-run.
Stage 9D does not restart live services.
Stage 9D does not send frontend router POST traffic during smoke.
Stage 9D does not put /api/router/dry-run directly in frontend/wrapper-ui/app.js.

## Implementation boundary

Stage 9D adds `window.EdgeRouterShadowReadSurface` in `frontend/wrapper-ui/app.js`.

The new browser-surface bridge:

- Uses `window.EdgeRouterShadowRead` from `frontend/wrapper-ui/router_shadow_read_stub.js`.
- Calls `sendRouterDryRunShadowRead` only through the existing router shadow-read stub boundary.
- Requires `ROUTER_SHADOW_READ_ENABLED === true`.
- Requires `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT === true`.
- Requires a narrow surface allowlist match.
- Builds dry-run-only payloads.
- Forces `dispatch_requested: false`.
- Forces `dispatch_performed: false`.
- Returns `router_shadow_read_surface_disabled` while disabled.
- Does not call fetch while disabled.

## Required current live state

After Stage 9D:

- Stage 9A evidence final_result remains pass.
- Stage 9B evidence final_result remains pass.
- Stage 9C plan exists.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains requestBrowserSurfaceRouterShadowRead.
- frontend/wrapper-ui/app.js references sendRouterDryRunShadowRead only through the stub namespace.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false
- Disabled browser-surface bridge returns router_shadow_read_surface_disabled.
- Disabled browser-surface bridge does not call fetch.
- Live-served app.js contains no /api/router/dry-run.
- Live-served router shadow-read stub remains disabled.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Next recommended stage

Stage 9E should verify the live-served disabled browser-surface bridge after static deployment.

Stage 9E should not enable browser router traffic by default.
