# Stage 9K Disabled Operator-Gated Browser Shadow-Read Activation Boundary

Generated: 2026-06-12

## Stage purpose

Stage 9K adds a disabled operator-gated browser shadow-read activation boundary.

Stage 9K keeps the operator gate false by default.
Stage 9K does not enable browser router traffic.
Stage 9K does not enable backend router dry-run.
Stage 9K does not restart live services.
Stage 9K does not send frontend router POST traffic during smoke.
Stage 9K does not put /api/router/dry-run directly in frontend/wrapper-ui/app.js.

## Implementation boundary

Stage 9K adds `window.EdgeRouterShadowReadOperatorGate` in `frontend/wrapper-ui/app.js`.

The operator gate:

- Defines OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- Wraps requestBrowserSurfaceRouterShadowRead.
- Returns operator_browser_shadow_read_activation_disabled while the operator gate is false.
- Preserves dry_run = true.
- Preserves dispatch_requested = false.
- Preserves dispatch_performed = false.
- Does not call fetch while disabled.
- Does not call sendRouterDryRunShadowRead while disabled.
- Keeps router_shadow_read_stub.js as the only file containing /api/router/dry-run.

## Required current live state

After Stage 9K:

- Stage 9G evidence final_result remains pass.
- Stage 9H evidence final_result remains pass.
- Stage 9J report exists.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate.
- frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- frontend/wrapper-ui/app.js contains requestBrowserSurfaceRouterShadowRead.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- Disabled operator gate returns operator_browser_shadow_read_activation_disabled.
- Disabled operator gate does not call fetch.
- Disabled operator gate does not call sendRouterDryRunShadowRead.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Next recommended stage

Stage 9L should verify the live-served disabled operator gate after deployment.

Stage 9L should not enable browser router traffic automatically.
Stage 9L should not enable backend router dry-run automatically.
