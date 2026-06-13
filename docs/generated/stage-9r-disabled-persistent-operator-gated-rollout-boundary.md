# Stage 9R Disabled Persistent Operator-Gated Rollout Boundary

Generated: 2026-06-12

## Stage purpose

Stage 9R adds a disabled persistent operator-gated browser shadow-read rollout boundary.

Stage 9R keeps persistent rollout disabled by default.
Stage 9R does not enable browser router traffic.
Stage 9R does not enable backend router dry-run.
Stage 9R does not restart live services.
Stage 9R does not send frontend router POST traffic during smoke.
Stage 9R does not put /api/router/dry-run directly in frontend/wrapper-ui/app.js.

## Implementation boundary

Stage 9R adds `window.EdgeRouterShadowReadPersistentRollout` in `frontend/wrapper-ui/app.js`.

The persistent rollout boundary:

- Defines PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false.
- Defines PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS = disabled.
- Defines PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON = persistent_operator_gated_rollout_disabled.
- Allows only manual-diagnostic as the first planned surface.
- Preserves dry_run = true.
- Preserves dispatch_requested = false.
- Preserves dispatch_performed = false.
- Does not call fetch while disabled.
- Does not call sendRouterDryRunShadowRead while disabled.
- Keeps router_shadow_read_stub.js as the only frontend file containing /api/router/dry-run.

## Required current live state

After Stage 9R:

- Stage 9N evidence final_result remains pass.
- Stage 9O evidence final_result remains pass.
- Stage 9Q report exists.
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
- Disabled persistent rollout boundary returns persistent_operator_gated_rollout_disabled.
- Disabled persistent rollout boundary does not call fetch.
- Disabled persistent rollout boundary does not call sendRouterDryRunShadowRead.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Next recommended stage

Stage 9S should verify the live-served disabled persistent rollout boundary after deployment.

Stage 9S should not enable browser router traffic automatically.
Stage 9S should not enable backend router dry-run automatically.
