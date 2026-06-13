# Stage 9P Narrow Persistent Operator-Gated Shadow-Read Rollout Decision Checkpoint

Generated: 2026-06-12

## Stage purpose

Stage 9P records the decision checkpoint for a future narrow persistent operator-gated browser shadow-read rollout.

Stage 9P does not modify frontend/wrapper-ui/app.js.
Stage 9P does not enable browser router traffic.
Stage 9P does not enable backend router dry-run.
Stage 9P does not restart live services.
Stage 9P does not send frontend router POST traffic.

## Current proven state

Stage 9N proved one controlled operator-gated browser shadow-read request can safely pass through the live-served browser bridge and backend dry-run.

Stage 9O proved the Stage 9N rollback stayed stable after push.

## Decision

The system is ready to plan a narrow persistent operator-gated rollout, but it should not be enabled automatically.

Recommended decision:

- Keep default browser router traffic disabled.
- Keep backend router dry-run disabled by default.
- Keep the operator gate false by default.
- Require explicit operator approval before any persistent rollout.
- Start with one narrow surface only.
- Keep dry_run = true.
- Keep dispatch_requested = false.
- Keep dispatch_performed = false.
- Add a persistent operator/admin switch only after a rollback plan exists.
- Continue using one-request activation smokes before any wider rollout.

## Required current live state

After Stage 9P:

- Stage 9N evidence final_result remains pass.
- Stage 9O evidence final_result remains pass.
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

## Future Stage 9Q proposal

Stage 9Q should prepare a persistent operator-gated rollout implementation plan only.

Stage 9Q should not enable browser router traffic automatically.
Stage 9Q should not enable backend router dry-run automatically.
Stage 9Q should define the persistent operator/admin switch.
Stage 9Q should define rollback to the current default-disabled state.
Stage 9Q should require explicit approval before any implementation or activation.
