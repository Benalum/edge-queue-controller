# Stage 9G Controlled Browser-Surface Activation and Rollback

Generated: 2026-06-12

## Stage purpose

Stage 9G performs one controlled browser-surface router shadow-read activation and rollback.

Stage 9G temporarily enables backend router dry-run.
Stage 9G restarts edge-queue-controller for activation and rollback.
Stage 9G loads live-served router_shadow_read_stub.js.
Stage 9G loads the live-served Stage 9D app.js bridge block.
Stage 9G enables browser-surface flags only inside a Node VM.
Stage 9G calls requestBrowserSurfaceRouterShadowRead exactly once.
Stage 9G confirms exactly one request is sent.
Stage 9G confirms the request is dry-run only.
Stage 9G confirms dispatch_requested = false.
Stage 9G confirms dispatch_performed = false.
Stage 9G rolls backend dry-run back to disabled.

## Required pre-activation state

Before activation:

- Stage 9D evidence final_result remains pass.
- Stage 9E evidence final_result remains pass.
- Stage 9F plan exists.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains requestBrowserSurfaceRouterShadowRead.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false
- Live-served app.js contains EdgeRouterShadowReadSurface.
- Live-served app.js contains requestBrowserSurfaceRouterShadowRead.
- Live-served app.js contains no /api/router/dry-run.
- POST /api/router/dry-run returns HTTP 404 before activation.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent before activation.
- Queue is clean before activation.

## Required activated state

During activation:

- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is present.
- POST /api/router/dry-run returns HTTP 200.
- requestBrowserSurfaceRouterShadowRead is called exactly once.
- Exactly one frontend fetch is sent.
- The browser-surface request uses manual-diagnostic.
- The request is dry-run only.
- dispatch_requested = false.
- dispatch_performed = false.
- The backend response does not indicate dispatch.
- Queue remains clean during activation.

## Required rollback state

After rollback:

- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent.
- POST /api/router/dry-run returns HTTP 404 after rollback.
- Browser-surface flags remain disabled in repo/static files.
- frontend/wrapper-ui/app.js still contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js still contains ROUTER_SHADOW_READ_ENABLED = false.
- frontend/wrapper-ui/router_shadow_read_stub.js still contains ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- Queue remains clean after rollback.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## No-go and rollback triggers

Stage 9G must roll back immediately if:

- More than one request is sent.
- The request is not dry-run only.
- dispatch_requested is not false.
- dispatch_performed is not false.
- The backend response indicates dispatch.
- Queue changes unexpectedly.
- POST /api/router/dry-run remains HTTP 200 after rollback.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains present after rollback.
- Timers change unexpectedly.
- Port 7076 becomes active.
