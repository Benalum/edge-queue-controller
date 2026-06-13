# Stage 9I User-Facing Browser Shadow-Read Activation Decision Checkpoint

Generated: 2026-06-12

## Stage purpose

Stage 9I records the user-facing browser shadow-read activation decision checkpoint.

Stage 9I does not modify frontend/wrapper-ui/app.js.
Stage 9I does not enable browser router traffic.
Stage 9I does not enable backend router dry-run.
Stage 9I does not restart live services.
Stage 9I does not send frontend router POST traffic.

## Current proven state

Stage 9G proved one controlled browser-surface request can pass through the live-served browser bridge and backend dry-run safely.

Stage 9H proved the Stage 9G rollback stayed stable after push.

## Required current live state

After Stage 9I:

- Stage 9G evidence final_result remains pass.
- Stage 9H evidence final_result remains pass.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains requestBrowserSurfaceRouterShadowRead.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false
- Live-served app.js contains EdgeRouterShadowReadSurface.
- Live-served app.js contains requestBrowserSurfaceRouterShadowRead.
- Live-served app.js contains no /api/router/dry-run.
- Live-served router shadow-read stub remains disabled.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Decision checkpoint

The system is ready for a future operator-gated user-facing shadow-read stage, but it should not be enabled by default.

Recommended decision:

- Keep default browser router traffic disabled.
- Keep backend router dry-run disabled by default.
- Add an explicit operator/admin activation boundary before any persistent browser shadow-read traffic.
- Add request counting and rollback checks before any broader surface is activated.
- Keep one-request smoke tests as the standard for future activation steps.

## Future Stage 9J proposal

Stage 9J should prepare the operator-gated activation boundary plan only.

Stage 9J should not enable browser router traffic automatically.
Stage 9J should not enable backend router dry-run automatically.
Stage 9J should require explicit approval before any user-facing activation.
Stage 9J should define how an admin/operator switch would activate a narrow surface.
Stage 9J should preserve no-dispatch behavior.
Stage 9J should preserve rollback to POST /api/router/dry-run HTTP 404.
