# Stage 9F Controlled Browser-Surface Activation and Rollback Plan

Generated: 2026-06-12

## Stage purpose

Stage 9F prepares the controlled browser-surface router shadow-read activation and rollback plan only.

Stage 9F does not modify frontend/wrapper-ui/app.js.
Stage 9F does not enable browser router traffic.
Stage 9F does not enable backend router dry-run.
Stage 9F does not restart live services.
Stage 9F does not send frontend router POST traffic.

## Current proven state

Stage 9A proved one controlled full-stack router shadow-read can be sent safely through the live-served stub while backend dry-run is temporarily enabled.

Stage 9B proved rollback stability after Stage 9A.

Stage 9D added the disabled browser-surface bridge in frontend/wrapper-ui/app.js.

Stage 9E proved the live-served disabled browser-surface bridge skips without fetch or stub calls.

## Required Stage 9E evidence

Stage 9E evidence must show:

- final_result = pass
- live_app_code = 200
- live_stub_code = 200
- live_disabled_runtime = pass
- post_code = 404
- env_absent = true
- queue_clean = true

## Required current live state

After Stage 9F:

- Stage 9D evidence final_result remains pass.
- Stage 9E evidence final_result remains pass.
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

## Future Stage 9G proposal

Stage 9G may perform one controlled browser-surface activation and rollback.

Stage 9G should only run after Stage 9F is committed, tagged, and pushed.

Stage 9G may temporarily:

1. Enable backend dry-run with a temporary systemd drop-in.
2. Restart edge-queue-controller.
3. Confirm POST /api/router/dry-run returns HTTP 200.
4. Load live-served router_shadow_read_stub.js.
5. Load the live-served Stage 9D app.js bridge block.
6. Enable browser-surface flags only inside a Node VM or controlled browser test harness.
7. Call requestBrowserSurfaceRouterShadowRead exactly once.
8. Confirm exactly one request is sent.
9. Confirm the request is dry-run only.
10. Confirm dispatch_requested = false.
11. Confirm dispatch_performed = false.
12. Confirm the queue remains clean.
13. Disable the browser-surface flags again.
14. Remove backend dry-run drop-in.
15. Restart edge-queue-controller.
16. Confirm POST /api/router/dry-run returns HTTP 404.
17. Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent.
18. Confirm queue, timers, and port 7076 remain safe.

## Stage 9G no-go triggers

Stage 9G must roll back immediately if:

- More than one request is sent.
- The request is not dry-run only.
- dispatch_requested is not false.
- dispatch_performed is not false.
- The backend response indicates dispatch.
- Queue changes unexpectedly.
- POST /api/router/dry-run remains HTTP 200 after rollback.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains present after rollback.
- Browser-surface flags remain enabled after rollback.
- Timers change unexpectedly.
- Port 7076 becomes active.

## Activation default

Stage 9G should not enable browser router traffic automatically.

Stage 9G requires explicit operator approval before activation.
