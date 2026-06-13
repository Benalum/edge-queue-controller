# Stage 9X Persistent Activation Mutation Design Plan

Generated: 2026-06-12

## Stage purpose

Stage 9X prepares the persistent activation mutation design plan only.

Stage 9X does not modify frontend/wrapper-ui/app.js.
Stage 9X does not modify edge_controller.py.
Stage 9X does not restart live services.
Stage 9X does not add a mutation endpoint.
Stage 9X does not enable browser router traffic.
Stage 9X does not enable backend router dry-run.
Stage 9X does not send frontend router POST traffic.

## Current proven state

Stage 9V proved the disabled controller-side persistent rollout status endpoint live after restart.

Stage 9W proved the live disabled persistent rollout status endpoint remained stable after push without restart.

## Mutation design requirements

A future persistent activation mutation implementation must:

- Remain disabled by default.
- Require authenticated admin/operator authority.
- Refuse anonymous or non-admin mutation attempts.
- Require explicit operator approval before implementation.
- Keep GET /api/router/persistent-rollout/status read-only and safe.
- Add any mutation endpoint separately from the status endpoint.
- Start with manual-diagnostic as the only allowlisted surface.
- Preserve dry_run = true.
- Preserve dispatch_requested = false.
- Preserve dispatch_performed = false.
- Never store /api/router/dry-run directly in frontend/wrapper-ui/app.js.
- Keep router_shadow_read_stub.js as the only frontend file containing /api/router/dry-run.
- Refuse activation when app.js directly contains /api/router/dry-run.
- Refuse activation when router shadow-read flags are true by default.
- Refuse activation when persistent rollout is true by default.
- Refuse activation when the operator gate is true by default.
- Refuse activation when backend dry-run is unavailable.
- Record every mutation attempt in generated evidence.
- Record every activation and rollback decision in generated evidence.
- Include exact one-request controlled activation smoke before widening.
- Include rollback to the current default-disabled state.
- Confirm POST /api/router/dry-run returns HTTP 404 after rollback.
- Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent after rollback.
- Confirm queue remains clean.
- Confirm modern timers remain active.
- Confirm legacy scheduler remains inactive/disabled.
- Confirm port 7076 remains closed.

## Recommended future shape

A future implementation stage should add a disabled mutation boundary only after another explicit approval checkpoint.

Recommended shape:

1. Keep GET /api/router/persistent-rollout/status read-only.
2. Add a separate admin/operator-only mutation route later.
3. Gate mutation behind authenticated admin/operator checks.
4. Store mutation state server-side, not in frontend static code.
5. Keep default state disabled.
6. Return safe browser-readable status only.
7. Require a later explicit live activation stage before any browser shadow-read request is sent.
8. Require a rollback smoke in the same activation stage.

## Required current live state

After Stage 9X:

- Stage 9V evidence final_result remains pass.
- Stage 9W evidence final_result remains pass.
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
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadPersistentRollout.
- frontend/wrapper-ui/app.js contains PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 9Y proposal

Stage 9Y should prepare the disabled mutation-boundary implementation plan.

Stage 9Y should not add the mutation endpoint yet.
Stage 9Y should not enable browser router traffic.
Stage 9Y should not enable backend router dry-run.
Stage 9Y should define exact authorization checks, request schema, rollback evidence, and refusal behavior.
