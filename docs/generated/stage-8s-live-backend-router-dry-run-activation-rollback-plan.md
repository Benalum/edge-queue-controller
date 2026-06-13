# Stage 8S Live Backend Router Dry-Run Activation and Rollback Plan

Generated: 2026-06-12

## Stage result

Stage 8S is a planning and safety verification stage only.

No live backend router dry-run was enabled.
No live controller restart was performed.
No browser or frontend router traffic was added.
No frontend router endpoint string was added.
No live dispatch path was changed.

## Current safety baseline to preserve

The platform must remain in this state after Stage 8S:

- Live controller router dry-run remains disabled.
- POST /api/router/dry-run returns HTTP 404 on the live controller while dry-run is disabled.
- GET /api/router/dry-run may return HTTP 405 because the route is POST-only.
- Browser/frontend code still has no /api/router/dry-run endpoint string.
- Frontend router shadow-read remains disabled:
  - ROUTER_SHADOW_READ_ENABLED = false
  - ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false
- /tick remains the fast compatibility shim.
- Platform health remains online.
- Queue remains clean: queued 0, running 0, failed 0.
- Modern timers remain active:
  - edge-queue-power-auto-tick.timer
  - edge-queue-remediation-tick.timer
- Legacy scheduler timer remains disabled/inactive:
  - edge-queue-scheduler-tick.timer

## Exact backend dry-run flag identified from previous stages

The backend dry-run endpoint activation flag is:

- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1

This flag must not be enabled during Stage 8S.

## Future activation plan, not part of Stage 8S

A later activation stage may perform a short controlled live backend-only dry-run test.

The activation stage must:

1. Confirm the repo is clean and already contains the Stage 8S commit/tag.
2. Confirm queue state is clean before activation.
3. Confirm browser/frontend traffic is still disabled.
4. Confirm no frontend code contains /api/router/dry-run.
5. Confirm the frontend shadow-read constants still default to false.
6. Create a temporary systemd drop-in for edge-queue-controller that sets:
   - EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1
7. Reload systemd.
8. Restart only the live controller service during the controlled activation stage.
9. Verify /health is still HTTP 200.
10. Verify POST /api/router/dry-run is reachable only as a non-dispatching backend dry-run endpoint.
11. Run only direct backend curl tests.
12. Keep browser/router traffic disabled.
13. Capture logs and generated evidence.
14. Make a go/no-go decision before any frontend or browser integration.

## Future activation guardrails

The activation stage must not:

- Enable real router dispatch.
- Add router traffic to browser/frontend code.
- Enable frontend router shadow-read.
- Change /tick behavior.
- Change power timers.
- Change queue execution behavior.
- Leave a temporary controller running on port 7076.
- Leave dry-run enabled after a failed test.

## Rollback plan for a future activation stage

Rollback must be immediate if any safety check fails.

Rollback steps for a future activation stage:

1. Remove the temporary dry-run systemd drop-in, or unset:
   - EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED
2. Run systemctl daemon-reload.
3. Restart edge-queue-controller.
4. Verify /health returns HTTP 200.
5. Verify POST /api/router/dry-run returns HTTP 404 again.
6. Verify browser/frontend still has no /api/router/dry-run string.
7. Verify frontend shadow-read constants remain false.
8. Verify queue is clean.
9. Verify modern timers are active and the legacy scheduler timer is inactive/disabled.
10. Record rollback evidence before any new attempt.

## No-go triggers

A future activation stage must stop and roll back if any of these happen:

- /api/router/dry-run dispatches real work.
- Any browser/frontend router request appears.
- Queue state changes unexpectedly.
- /tick behavior changes.
- The live controller health check fails.
- Modern timers stop unexpectedly.
- The legacy scheduler timer becomes active.
- Any router flag remains enabled after cleanup.
- Any endpoint remains exposed after rollback.

## Stage 8S acceptance criteria

Stage 8S passes only if:

- This report exists.
- The smoke script exists and is executable.
- Live health is HTTP 200.
- POST /api/router/dry-run remains HTTP 404 while disabled.
- GET /api/router/dry-run is confirmed as either HTTP 404 or HTTP 405.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is not present in the live controller environment.
- Frontend/browser code has no /api/router/dry-run string.
- Frontend router shadow-read constants remain false.
- Queue state is confirmed clean.
- Modern timers are active.
- Legacy scheduler timer is inactive/disabled.
- No service restart is performed by this stage.
