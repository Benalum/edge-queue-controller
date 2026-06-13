# Stage 8Z Full-Stack Shadow-Read Activation Preflight Go/No-Go Checkpoint

Generated: 2026-06-12

## Stage purpose

Stage 8Z records the final preflight checkpoint before any full-stack frontend shadow-read activation.

Stage 8Z does not enable browser router traffic.
Stage 8Z does not enable backend router dry-run.
Stage 8Z does not restart live services.
Stage 8Z does not send router POST traffic from the browser.

## Current proven state

- Stage 8T proved backend dry-run activation and rollback.
- Stage 8W added the disabled frontend call boundary.
- Stage 8X proved the live-served disabled frontend boundary skips without fetch.
- Stage 8Y documented the controlled activation and rollback plan.

## Preflight decision

Decision: no-go for automatic activation in Stage 8Z.

Reason:

The next activation is the first full-stack path that would temporarily combine:

- backend dry-run enabled,
- frontend shadow-read enabled,
- a controlled frontend-originated request,
- and rollback of both frontend and backend flags.

That step should be performed only as a separate explicitly controlled activation stage.

## Required state after Stage 8Z

After Stage 8Z:

- Stage 8X evidence final_result remains pass.
- Stage 8Y activation/rollback plan exists.
- `frontend/wrapper-ui/router_shadow_read_stub.js` contains `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` contains no `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` is not wired to `sendRouterDryRunShadowRead`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Local disabled helper returns `router_shadow_read_disabled`.
- Local disabled helper does not call fetch while flags are false.
- Live-served disabled helper remains available.
- Live-served app.js remains unwired.
- POST /api/router/dry-run remains HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` remains absent from the live controller environment.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Next activation stage requirements

The next stage after this checkpoint may be named:

`Stage 9A Controlled Full-Stack Router Shadow-Read Activation and Rollback`

That stage may enable traffic only inside a controlled rollback window.

It must:

1. Confirm Stage 8Z is committed, tagged, and pushed.
2. Confirm repo is clean.
3. Confirm queue is clean before activation.
4. Confirm backend dry-run is disabled before activation.
5. Confirm frontend flags are false before activation.
6. Enable backend dry-run with a temporary systemd drop-in.
7. Restart `edge-queue-controller`.
8. Confirm POST `/api/router/dry-run` returns HTTP 200.
9. Temporarily enable frontend shadow-read for one narrow test path only.
10. Trigger exactly one controlled shadow-read.
11. Confirm no dispatch occurred.
12. Confirm queue remains clean.
13. Disable frontend shadow-read again.
14. Remove backend dry-run drop-in.
15. Restart `edge-queue-controller`.
16. Confirm POST `/api/router/dry-run` returns HTTP 404.
17. Confirm frontend flags are false again.
18. Confirm queue/timers/port safety.
19. Commit evidence only if all checks pass.

## No-go triggers for the activation stage

The activation stage must roll back immediately if:

- Real dispatch occurs.
- Queue changes unexpectedly.
- More than one frontend request is sent.
- Backend dry-run remains enabled after rollback.
- Frontend flags remain enabled after rollback.
- POST `/api/router/dry-run` remains HTTP 200 after rollback.
- `/tick` behavior changes.
- Timers change unexpectedly.
- Port 7076 becomes active.
## Exact smoke markers

- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js is not wired to sendRouterDryRunShadowRead.

