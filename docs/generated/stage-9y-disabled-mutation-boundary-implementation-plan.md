# Stage 9Y Disabled Mutation-Boundary Implementation Plan

Generated: 2026-06-12

## Stage purpose

Stage 9Y prepares the disabled mutation-boundary implementation plan only.

Stage 9Y does not modify frontend/wrapper-ui/app.js.
Stage 9Y does not modify edge_controller.py.
Stage 9Y does not restart live services.
Stage 9Y does not add the mutation endpoint.
Stage 9Y does not enable browser router traffic.
Stage 9Y does not enable backend router dry-run.
Stage 9Y does not send frontend router POST traffic.

## Current proven state

Stage 9W proved the live persistent rollout status endpoint remained disabled, read-only, and stable.

Stage 9X documented the persistent activation mutation design requirements without implementation.

## Disabled mutation-boundary requirements

A future disabled mutation-boundary implementation must:

- Keep GET /api/router/persistent-rollout/status read-only.
- Add any future mutation route separately from the status endpoint.
- Keep the future mutation route disabled by default.
- Require authenticated admin/operator authority.
- Refuse anonymous requests.
- Refuse non-admin requests.
- Refuse malformed requests.
- Refuse activation unless dry_run = true.
- Refuse activation unless dispatch_requested = false.
- Refuse activation unless dispatch_performed = false.
- Refuse activation unless the surface is manual-diagnostic.
- Refuse activation when app.js directly contains /api/router/dry-run.
- Refuse activation when router shadow-read flags are true by default.
- Refuse activation when persistent rollout is true by default.
- Refuse activation when the operator gate is true by default.
- Refuse activation when backend dry-run is unavailable.
- Record every mutation attempt in generated evidence.
- Record every refusal reason in generated evidence.
- Record every activation decision in generated evidence.
- Record every rollback decision in generated evidence.
- Include one-request controlled activation smoke before widening.
- Include rollback to current default-disabled state in the same activation stage.
- Confirm POST /api/router/dry-run returns HTTP 404 after rollback.
- Confirm EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent after rollback.
- Confirm queue remains clean after rollback.
- Confirm modern timers remain active.
- Confirm legacy scheduler remains inactive/disabled.
- Confirm port 7076 remains closed.

## Proposed future mutation route shape

A later implementation stage may introduce a disabled route such as:

- POST /api/router/persistent-rollout/request

The route should remain disabled by default and return a safe refusal such as:

- ok = true
- accepted = false
- enabled = false
- status = disabled
- reason = persistent_rollout_mutation_disabled
- dry_run = true
- dispatch_requested = false
- dispatch_performed = false
- mutation_supported = false
- activation_supported = false

## Required current live state

After Stage 9Y:

- Stage 9W evidence final_result remains pass.
- Stage 9X report exists.
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
- edge_controller.py has no persistent rollout mutation route.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Future Stage 9Z proposal

Stage 9Z should checkpoint the end-of-Stage-9 router shadow-read rollout posture.

Stage 9Z should summarize Stage 9A through Stage 9Y.
Stage 9Z should not add a mutation endpoint.
Stage 9Z should not restart services.
Stage 9Z should not enable browser router traffic.
Stage 9Z should not enable backend router dry-run.
