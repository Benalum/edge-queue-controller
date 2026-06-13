# Stage 9A Controlled Full-Stack Router Shadow-Read Activation and Rollback

Generated: 2026-06-12

## Stage purpose

Stage 9A performs the first controlled full-stack router shadow-read activation and rollback.

This stage intentionally enables backend dry-run temporarily, restarts the live controller, performs exactly one controlled shadow-read request using the live-served frontend stub inside a Node VM, and then rolls everything back.

## Strict scope

Stage 9A may:

- Create a temporary systemd drop-in for `edge-queue-controller`.
- Set `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` only during the controlled test window.
- Restart `edge-queue-controller` for activation.
- Fetch live-served frontend static JavaScript with GET only.
- Evaluate the live-served router shadow-read stub inside a Node VM.
- Temporarily set frontend shadow-read flags to true inside the Node VM only.
- Send exactly one controlled router shadow-read request.
- Verify the response is non-dispatching.
- Roll back backend dry-run by removing the temporary systemd drop-in.
- Restart `edge-queue-controller` for rollback.
- Commit evidence only after rollback succeeds.

Stage 9A must not:

- Persistently enable frontend flags in repo files.
- Persistently enable backend dry-run.
- Wire `app.js` to `sendRouterDryRunShadowRead`.
- Send more than one controlled shadow-read request.
- Change `/tick`.
- Change queue behavior.
- Change power automation.
- Leave POST `/api/router/dry-run` enabled after rollback.

## Required pre-activation state

Before activation:

- Stage 8Z preflight exists.
- `frontend/wrapper-ui/app.js` contains no `/api/router/dry-run`.
- `frontend/wrapper-ui/app.js` is not wired to `sendRouterDryRunShadowRead`.
- `frontend/wrapper-ui/router_shadow_read_stub.js` contains `/api/router/dry-run`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- POST `/api/router/dry-run` returns HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` is absent.
- Queue is clean.
- Modern timers are active.
- Legacy scheduler timer is inactive/disabled.
- Port 7076 is closed.

## Required activated state

During activation:

- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` is present.
- POST `/api/router/dry-run` returns HTTP 200.
- Exactly one controlled shadow-read request is sent from the live-served stub inside a Node VM.
- The request is dry-run only.
- The result is non-dispatching.
- Queue remains clean.

## Required rollback state

After rollback:

- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` is absent.
- POST `/api/router/dry-run` returns HTTP 404.
- Frontend repo flags remain false.
- Live-served frontend flags remain false.
- `app.js` remains unwired.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## No-go triggers

Stage 9A must fail and roll back if:

- More than one controlled shadow-read request is attempted.
- The response indicates dispatch occurred.
- Queue changes unexpectedly.
- Frontend repo flags become true.
- Backend dry-run remains enabled after rollback.
- POST `/api/router/dry-run` remains HTTP 200 after rollback.
- Timers change unexpectedly.
- Port 7076 becomes active.
## Exact smoke markers

- Set EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 only during the controlled test window.
- POST /api/router/dry-run returns HTTP 404.
- Leave POST /api/router/dry-run enabled after rollback.

