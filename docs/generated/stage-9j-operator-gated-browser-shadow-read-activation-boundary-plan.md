# Stage 9J Operator-Gated Browser Shadow-Read Activation Boundary Plan

Generated: 2026-06-12

## Stage purpose

Stage 9J prepares the operator-gated browser shadow-read activation boundary plan only.

Stage 9J does not modify frontend/wrapper-ui/app.js.
Stage 9J does not enable browser router traffic.
Stage 9J does not enable backend router dry-run.
Stage 9J does not restart live services.
Stage 9J does not send frontend router POST traffic.

## Current proven state

Stage 9G proved one controlled browser-surface request can pass through the live-served browser bridge and backend dry-run safely.

Stage 9H proved the Stage 9G rollback stayed stable after push.

Stage 9I recorded the user-facing browser shadow-read activation decision checkpoint and recommended keeping default browser router traffic disabled.

## Operator-gated boundary requirements

A future operator-gated activation boundary must:

- Keep browser router traffic disabled by default.
- Keep backend router dry-run disabled by default.
- Require explicit operator/admin approval before activation.
- Activate only one narrow browser surface at a time.
- Preserve dry_run = true.
- Preserve dispatch_requested = false.
- Preserve dispatch_performed = false.
- Cap smoke execution to exactly one request.
- Record evidence for before, during, and after activation.
- Roll back backend dry-run to POST /api/router/dry-run HTTP 404.
- Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent after rollback.
- Confirm queue remains clean before, during, and after activation.
- Confirm timers remain safe.
- Confirm port 7076 remains closed.
- Refuse activation when repo safety markers are missing.
- Refuse activation when app.js directly contains /api/router/dry-run.
- Refuse activation when router shadow-read flags are true by default.

## Required current live state

After Stage 9J:

- Stage 9G evidence final_result remains pass.
- Stage 9H evidence final_result remains pass.
- Stage 9I report exists.
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

## Future Stage 9K proposal

Stage 9K should add a disabled operator-gated activation boundary.

Stage 9K should not enable browser router traffic automatically.
Stage 9K should not enable backend router dry-run automatically.
Stage 9K should keep the operator gate false by default.
Stage 9K should require a later explicit activation stage before any user-facing browser shadow-read traffic runs.
