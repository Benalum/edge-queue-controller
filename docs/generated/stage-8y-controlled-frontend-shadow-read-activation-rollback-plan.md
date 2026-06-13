# Stage 8Y Controlled Frontend Shadow-Read Activation and Rollback Plan

Generated: 2026-06-12

## Stage purpose

Stage 8Y prepares the controlled frontend shadow-read activation and rollback plan only.

Stage 8Y does not enable browser router traffic.
Stage 8Y does not enable backend router dry-run.
Stage 8Y does not restart live services.

## Current proven state

Stage 8T proved backend dry-run can be enabled, called directly, and rolled back safely.

Stage 8W added a disabled frontend stub boundary that knows `/api/router/dry-run` but does not call it while disabled.

Stage 8X proved both local and live-served disabled stubs skip without fetch while flags are false.

## Strict scope

Stage 8Y may:

- Document the future controlled frontend activation plan.
- Document the rollback plan.
- Verify current frontend/backend safety state.
- Verify Stage 8X evidence exists and passed.
- Verify local and live-served frontend disabled boundaries are still safe.

Stage 8Y must not:

- Set `ROUTER_SHADOW_READ_ENABLED = true`.
- Set `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = true`.
- Set `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
- Restart `edge-queue-controller`.
- Restart frontend/static services.
- Send browser-originated router POST traffic.
- Wire `app.js` to `sendRouterDryRunShadowRead`.
- Change `/tick`.
- Change queue behavior.
- Change power automation.

## Required state after Stage 8Y

After Stage 8Y:

- Stage 8X evidence final_result remains pass.
- `frontend/wrapper-ui/router_shadow_read_stub.js` contains `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` contains no `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` is not wired to `sendRouterDryRunShadowRead`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Local disabled helper returns `router_shadow_read_disabled`.
- Local disabled helper does not call fetch while flags are false.
- Live-served disabled helper returns `router_shadow_read_disabled`.
- Live-served disabled helper does not call fetch while flags are false.
- POST /api/router/dry-run remains HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` remains absent from the live controller environment.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 8Z activation proposal

Stage 8Z may perform a controlled full-stack shadow-read activation only if explicitly chosen.

A future Stage 8Z activation must:

1. Confirm repo is clean and pushed through Stage 8Y.
2. Confirm queue is clean.
3. Confirm timers are correct.
4. Confirm port 7076 is closed.
5. Confirm `app.js` is still not wired before activation.
6. Enable backend dry-run using a temporary systemd drop-in.
7. Restart `edge-queue-controller`.
8. Confirm POST `/api/router/dry-run` returns HTTP 200.
9. Enable frontend shadow-read only for a narrow test surface.
10. Perform exactly one controlled shadow-read request.
11. Confirm the response is non-dispatching.
12. Confirm queue remains clean.
13. Roll back frontend flags.
14. Remove backend dry-run drop-in.
15. Restart `edge-queue-controller`.
16. Confirm POST `/api/router/dry-run` returns HTTP 404 again.
17. Confirm frontend flags are false again.
18. Commit evidence only if all checks pass.

## Future Stage 8Z no-go triggers

A future Stage 8Z must stop and roll back if:

- Real dispatch occurs.
- Queue changes unexpectedly.
- Browser sends more than the approved controlled request.
- Any frontend flag defaults to enabled after rollback.
- Backend dry-run remains enabled after rollback.
- POST `/api/router/dry-run` remains enabled after rollback.
- Timers change unexpectedly.
- Port 7076 becomes active.
- `/tick` behavior changes.
## Exact smoke markers

- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js is not wired to sendRouterDryRunShadowRead.

