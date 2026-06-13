# Stage 9M Operator-Gated Controlled Activation Plan

Generated: 2026-06-12

## Stage purpose

Stage 9M prepares the operator-gated controlled browser shadow-read activation plan only.

Stage 9M does not modify frontend/wrapper-ui/app.js.
Stage 9M does not enable browser router traffic.
Stage 9M does not enable backend router dry-run.
Stage 9M does not restart live services.
Stage 9M does not send frontend router POST traffic.

## Current proven state

Stage 9K added the disabled operator-gated browser shadow-read activation boundary.

Stage 9L proved the pushed/live-served disabled operator gate skips without fetch or stub calls.

## Required current live state

After Stage 9M:

- Stage 9K evidence final_result remains pass.
- Stage 9L evidence final_result remains pass.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate.
- frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- frontend/wrapper-ui/app.js contains operator_browser_shadow_read_activation_disabled.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- Live-served app.js contains EdgeRouterShadowReadSurface.
- Live-served app.js contains EdgeRouterShadowReadOperatorGate.
- Live-served app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- Live-served app.js contains operator_browser_shadow_read_activation_disabled.
- Live-served app.js contains no /api/router/dry-run.
- Live-served router shadow-read stub remains disabled.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 9N proposal

Stage 9N may perform one controlled operator-gated browser shadow-read activation and rollback.

Stage 9N should only run after Stage 9M is committed, tagged, and pushed.

Stage 9N may temporarily:

1. Enable backend dry-run with a temporary systemd drop-in.
2. Restart edge-queue-controller.
3. Confirm POST /api/router/dry-run returns HTTP 200.
4. Load live-served router_shadow_read_stub.js.
5. Load the live-served Stage 9D browser-surface bridge block.
6. Load the live-served Stage 9K operator gate block.
7. Enable browser shadow-read flags only inside a Node VM.
8. Enable the operator gate only inside a Node VM.
9. Call requestBrowserSurfaceRouterShadowRead exactly once.
10. Confirm exactly one request is sent.
11. Confirm dry_run = true.
12. Confirm dispatch_requested = false.
13. Confirm dispatch_performed = false.
14. Confirm the backend response does not indicate dispatch.
15. Confirm queue remains clean during activation.
16. Roll browser flags and operator gate back to false inside the test harness.
17. Remove backend dry-run drop-in.
18. Restart edge-queue-controller.
19. Confirm POST /api/router/dry-run returns HTTP 404.
20. Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent.
21. Confirm queue, timers, and port 7076 remain safe.

## Stage 9N no-go triggers

Stage 9N must roll back immediately if:

- More than one request is sent.
- The request is not dry-run only.
- dispatch_requested is not false.
- dispatch_performed is not false.
- The backend response indicates dispatch.
- Queue changes unexpectedly.
- POST /api/router/dry-run remains HTTP 200 after rollback.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains present after rollback.
- Browser shadow-read flags remain enabled after rollback.
- Operator gate remains enabled after rollback.
- Timers change unexpectedly.
- Port 7076 becomes active.

## Activation default

Stage 9N should not enable browser router traffic automatically.

Stage 9N requires explicit operator approval before activation.
