# Stage 10A Persistent Rollout Mutation Readiness Decision Checkpoint

Generated: 2026-06-12

## Stage purpose

Stage 10A starts Stage 10 with a persistent rollout mutation readiness decision checkpoint.

Stage 10A is plan-only.
Stage 10A does not modify frontend/wrapper-ui/app.js.
Stage 10A does not modify edge_controller.py.
Stage 10A does not restart live services.
Stage 10A does not add a mutation endpoint.
Stage 10A does not enable browser router traffic.
Stage 10A does not enable backend router dry-run.
Stage 10A does not send frontend router POST traffic.

## Stage 9 handoff

Stage 9Z closed Stage 9 with a safe default-disabled router shadow-read rollout posture.

The Stage 9 final posture is:

- Browser router traffic remains disabled by default.
- Backend router dry-run remains disabled by default.
- app.js contains no /api/router/dry-run.
- router_shadow_read_stub.js remains disabled by default.
- Operator gate remains false by default.
- Persistent rollout boundary remains false by default.
- Controller-side persistent rollout status endpoint is read-only.
- No persistent rollout mutation route exists.
- Status endpoint reports enabled = false.
- Status endpoint reports mutation_supported = false.
- Status endpoint reports activation_supported = false.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.

## Stage 10 decision

Stage 10 should not immediately implement mutation support.

The recommended decision is:

- Pause before adding a mutation endpoint.
- Keep the current read-only status endpoint.
- Keep all browser/router traffic disabled.
- Keep backend dry-run disabled.
- Add mutation support only after a dedicated authorization design and explicit approval checkpoint.
- Consider using the next work block for broader product/platform stability instead of continuing router rollout immediately.

## If mutation work continues later

A future mutation implementation must require:

- Authenticated admin/operator authority.
- Explicit operator approval before implementation.
- A separate mutation route from GET /api/router/persistent-rollout/status.
- Default disabled mutation behavior.
- Safe refusal for anonymous users.
- Safe refusal for non-admin users.
- Safe refusal for malformed requests.
- Safe refusal when surface is not manual-diagnostic.
- Safe refusal when dry_run is not true.
- Safe refusal when dispatch_requested is not false.
- Safe refusal when dispatch_performed is not false.
- Safe refusal when app.js directly contains /api/router/dry-run.
- Safe refusal when router shadow-read flags are true by default.
- Safe refusal when persistent rollout is true by default.
- Safe refusal when operator gate is true by default.
- Safe refusal when backend dry-run is unavailable.
- Generated evidence for every mutation attempt.
- Generated evidence for every refusal reason.
- Generated evidence for every activation and rollback decision.
- One-request controlled activation smoke before widening.
- Rollback in the same activation stage.
- POST /api/router/dry-run returns HTTP 404 after rollback.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent after rollback.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Required current live state

After Stage 10A:

- Stage 9Z evidence final_result remains pass.
- Stage 9Z report exists.
- GET /api/router/persistent-rollout/status returns HTTP 200.
- Status endpoint remains enabled = false.
- Status endpoint remains status = disabled.
- Status endpoint remains reason = persistent_operator_gated_rollout_disabled.
- Status endpoint remains dry_run = true.
- Status endpoint remains dispatch_requested = false.
- Status endpoint remains dispatch_performed = false.
- Status endpoint remains mutation_supported = false.
- Status endpoint remains activation_supported = false.
- POST mutation to /api/router/persistent-rollout/status remains unavailable.
- POST mutation to /api/router/persistent-rollout/request remains unavailable.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadPersistentRollout.
- frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- frontend/wrapper-ui/app.js contains PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- edge_controller.py has no persistent rollout mutation route.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 10B options

Option A: Stage 10B can be a plan-only authorization design for persistent rollout mutation.

Option B: Stage 10B can pause router rollout work and move to platform stability, product UX, or performance work.

Recommended default: choose Option B unless mutation support is urgently needed.
