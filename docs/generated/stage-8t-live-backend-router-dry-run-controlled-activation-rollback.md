# Stage 8T Live Backend Router Dry-Run Controlled Activation and Rollback

Generated: 2026-06-12

## Stage purpose

Stage 8T performs a controlled live backend-only router dry-run activation, validates the endpoint directly with curl, and immediately rolls the system back to the disabled state.

This stage intentionally allows a live `edge-queue-controller` restart because backend dry-run activation is controlled through a systemd environment flag.

## Strict scope

Stage 8T may:

- Create a temporary systemd drop-in for `edge-queue-controller`.
- Set `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` only during the controlled test window.
- Restart `edge-queue-controller` for activation.
- POST directly to `http://127.0.0.1:7070/api/router/dry-run`.
- Remove the temporary systemd drop-in.
- Restart `edge-queue-controller` again for rollback.
- Write local evidence.

Stage 8T must not:

- Add `/api/router/dry-run` to frontend/browser code.
- Enable frontend router shadow-read.
- Enable real router dispatch.
- Change `/tick`.
- Change power automation.
- Change queue execution.
- Leave dry-run enabled after the smoke.
- Leave a temporary controller on port 7076.

## Required baseline before activation

Before activation:

- Repo must be on top of Stage 8S.
- Browser/frontend code must contain no `/api/router/dry-run`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Live health must be HTTP 200.
- POST `/api/router/dry-run` must be HTTP 404 while disabled.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` must not be in the live controller environment.
- Queue must be clean.
- Modern timers must be active.
- Legacy scheduler timer must be inactive/disabled.

## Activation validation

During activation:

- Temporary drop-in sets `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
- Live controller is restarted.
- Live health must return HTTP 200.
- Live environment must show `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
- POST `/api/router/dry-run` must return HTTP 200.
- Queue must remain clean after the dry-run call.
- No browser/frontend router endpoint is added.

## Rollback validation

After rollback:

- Temporary drop-in is removed.
- Live controller is restarted.
- Live health must return HTTP 200.
- Live environment must no longer show `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
- POST `/api/router/dry-run` must return HTTP 404 again.
- Queue must remain clean.
- Timers must remain in their expected states.
- Browser/frontend code must still contain no `/api/router/dry-run`.

## Stage 8T acceptance criteria

Stage 8T passes only if:

- The controlled activation succeeds.
- The direct backend dry-run call succeeds.
- No queue work is dispatched.
- Rollback succeeds.
- The disabled endpoint state is restored.
- The live router dry-run flag is absent after rollback.
- The generated evidence file is written.
