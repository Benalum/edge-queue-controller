# Stage 9T Persistent Rollout Activation Control-Plane Plan

Generated: 2026-06-12

## Stage purpose

Stage 9T prepares the persistent rollout activation control-plane plan only.

Stage 9T does not modify frontend/wrapper-ui/app.js.
Stage 9T does not enable browser router traffic.
Stage 9T does not enable backend router dry-run.
Stage 9T does not restart live services.
Stage 9T does not send frontend router POST traffic.

## Current proven state

Stage 9R added a disabled persistent operator-gated rollout boundary.

Stage 9S proved the pushed/live-served disabled persistent rollout boundary skips without fetch or stub calls.

## Control-plane requirements

A future persistent rollout activation control plane must:

- Keep persistent rollout disabled by default.
- Keep browser router traffic disabled by default.
- Keep backend router dry-run disabled by default.
- Keep the operator gate false by default.
- Store persistent rollout state outside frontend static code.
- Require authenticated admin/operator authority before any activation state change.
- Expose only read-only safe activation status to the browser.
- Start with manual-diagnostic as the only allowlisted surface.
- Preserve dry_run = true.
- Preserve dispatch_requested = false.
- Preserve dispatch_performed = false.
- Refuse activation when app.js directly contains /api/router/dry-run.
- Refuse activation when router shadow-read flags are true by default.
- Refuse activation when persistent rollout is true by default.
- Refuse activation when the operator gate is true by default.
- Record activation and rollback evidence.
- Include exact one-request controlled activation smoke before widening.
- Include rollback to the current default-disabled state.
- Confirm POST /api/router/dry-run returns HTTP 404 after rollback.
- Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent after rollback.
- Confirm queue remains clean.
- Confirm modern timers remain active.
- Confirm legacy scheduler remains inactive/disabled.
- Confirm port 7076 remains closed.

## Recommended future implementation shape

A future implementation stage should add a disabled controller-side activation state boundary.

Recommended shape:

1. Add a read-only status endpoint for persistent rollout state.
2. Add an admin/operator-only state mutation path later, not in the first implementation.
3. Store the state in a safe server-side file or database row.
4. Default all state values to false.
5. Return safe browser-readable status only.
6. Keep app.js free of /api/router/dry-run.
7. Keep router_shadow_read_stub.js as the only frontend file containing /api/router/dry-run.
8. Require a later explicit activation stage before any live browser request is sent.

## Required current live state

After Stage 9T:

- Stage 9R evidence final_result remains pass.
- Stage 9S evidence final_result remains pass.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadPersistentRollout.
- frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- frontend/wrapper-ui/app.js contains PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false.
- frontend/wrapper-ui/app.js contains persistent_operator_gated_rollout_disabled.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- Live-served app.js contains EdgeRouterShadowReadPersistentRollout.
- Live-served app.js contains PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false.
- Live-served app.js contains persistent_operator_gated_rollout_disabled.
- Live-served app.js contains no /api/router/dry-run.
- Live-served router shadow-read stub remains disabled.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 9U proposal

Stage 9U should add the disabled controller-side persistent rollout status boundary.

Stage 9U should not enable browser router traffic automatically.
Stage 9U should not enable backend router dry-run automatically.
Stage 9U should not add an activation mutation endpoint yet.
Stage 9U should expose read-only disabled status only.
