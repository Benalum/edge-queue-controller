# Stage 9Q Persistent Operator-Gated Rollout Implementation Plan

Generated: 2026-06-12

## Stage purpose

Stage 9Q prepares the persistent operator-gated browser shadow-read rollout implementation plan only.

Stage 9Q does not modify frontend/wrapper-ui/app.js.
Stage 9Q does not enable browser router traffic.
Stage 9Q does not enable backend router dry-run.
Stage 9Q does not restart live services.
Stage 9Q does not send frontend router POST traffic.

## Current proven state

Stage 9N proved one controlled operator-gated browser shadow-read request can safely pass through the live-served browser bridge and backend dry-run.

Stage 9O proved the Stage 9N rollback stayed stable after push.

Stage 9P recorded the narrow persistent rollout decision checkpoint and recommended keeping all defaults disabled.

## Persistent rollout implementation requirements

A future persistent operator-gated rollout implementation must:

- Keep browser router traffic disabled by default.
- Keep backend router dry-run disabled by default.
- Keep the operator gate false by default.
- Store persistent activation state outside frontend static code.
- Require authenticated admin/operator authority to change activation state.
- Scope activation to exactly one allowlisted surface first.
- Preserve dry_run = true.
- Preserve dispatch_requested = false.
- Preserve dispatch_performed = false.
- Refuse activation when app.js directly contains /api/router/dry-run.
- Refuse activation when router shadow-read flags are true by default.
- Refuse activation when the operator gate is true by default.
- Refuse activation when backend dry-run is unavailable.
- Record every activation and rollback decision in generated evidence.
- Include a one-request smoke before any persistent rollout is widened.
- Include rollback to the current default-disabled state.
- Confirm POST /api/router/dry-run returns HTTP 404 after rollback.
- Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent after rollback.
- Confirm queue remains clean.
- Confirm modern timers remain active.
- Confirm legacy scheduler remains inactive/disabled.
- Confirm port 7076 remains closed.

## Recommended implementation shape

A future implementation stage should add a disabled persistent operator gate boundary, but should not activate it.

Recommended shape:

1. Add a controller-side read-only activation status endpoint.
2. Add an admin/operator-only activation state file or database flag.
3. Keep the default state false.
4. Expose only safe status to the browser.
5. Keep the backend endpoint string in router_shadow_read_stub.js only.
6. Keep app.js free of /api/router/dry-run.
7. Keep frontend bridge disabled unless all gates are true.
8. Require a later explicit activation stage before any live browser request is sent.

## Required current live state

After Stage 9Q:

- Stage 9N evidence final_result remains pass.
- Stage 9O evidence final_result remains pass.
- Stage 9P report exists.
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

## Future Stage 9R proposal

Stage 9R should add the disabled persistent operator-gated rollout boundary.

Stage 9R should not enable browser router traffic automatically.
Stage 9R should not enable backend router dry-run automatically.
Stage 9R should keep all persistent activation state false by default.
Stage 9R should require a later explicit activation stage before any live browser shadow-read traffic runs.
