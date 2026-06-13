# Stage 8V Frontend Router Shadow-Read Activation Plan

Generated: 2026-06-12

## Stage purpose

Stage 8V prepares the frontend/browser router shadow-read activation plan only.

Stage 8V does not enable browser router traffic.

This stage records the next safe activation boundary after Stage 8T proved backend dry-run activation/rollback and Stage 8U recorded the no-browser-traffic checkpoint.

## Strict scope

Stage 8V may:

- Document the future browser/frontend shadow-read activation plan.
- Document frontend safety gates.
- Document rollback steps.
- Verify current live/backend/frontend safety state.
- Verify Stage 8T and Stage 8U evidence exists.

Stage 8V must not:

- Add `/api/router/dry-run` to frontend code.
- Enable `ROUTER_SHADOW_READ_ENABLED`.
- Enable `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT`.
- Enable backend router dry-run.
- Restart live services.
- Change `/tick`.
- Change queue behavior.
- Change power automation.
- Send browser-originated router requests.

## Current checkpoint decision

Decision: do not enable browser/frontend router traffic in Stage 8V.

Reason:

- Backend dry-run was proven live and rollback-safe in Stage 8T.
- No-browser-traffic safety was preserved in Stage 8U.
- Frontend/browser shadow-read introduces a new traffic source and needs its own staged activation.
- The frontend must stay off until the exact request surface, sampling policy, evidence format, and rollback procedure are locked.

## Required state after Stage 8V

After Stage 8V:

- POST /api/router/dry-run remains HTTP 404.
- Live backend dry-run remains disabled.
- POST `/api/router/dry-run` remains HTTP 404.
- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1` remains absent from the live controller environment.
- `frontend/wrapper-ui/app.js` contains no `/api/router/dry-run`.
- `frontend/wrapper-ui/router_shadow_read_stub.js` contains no `/api/router/dry-run`.
- `ROUTER_SHADOW_READ_ENABLED = false`.
- `ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false`.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 8W proposal

Stage 8W should implement a frontend shadow-read activation boundary without enabling it.

Stage 8W may add a frontend function that knows how to call `/api/router/dry-run`, but only if all of these remain true:

- The function is behind `ROUTER_SHADOW_READ_ENABLED = false`.
- The feature flag default remains false.
- No user action can call it while disabled.
- The smoke proves the browser path is unreachable while disabled.
- Live backend dry-run remains disabled unless a separate controlled backend activation is explicitly performed.
- No service restart occurs unless explicitly required by the stage.

## Future browser activation proposal

A later browser activation stage must be explicit and controlled.

Before any browser request is allowed:

1. Backend dry-run must be enabled in a temporary rollback-safe window.
2. Frontend shadow-read must be enabled only for a narrow test surface.
3. The request must be non-dispatching.
4. The response must be logged as evidence.
5. Queue must remain clean.
6. Rollback must disable both backend dry-run and frontend shadow-read.
7. POST `/api/router/dry-run` must return HTTP 404 after rollback.

## No-go triggers for future browser activation

Stop and roll back if any of these occur:

- Real dispatch occurs.
- Queue count changes unexpectedly.
- Browser sends router requests outside the approved test surface.
- Frontend flag defaults to enabled.
- `/tick` behavior changes.
- Backend dry-run remains enabled after rollback.
- Timers change state unexpectedly.
- Port 7076 becomes active.
