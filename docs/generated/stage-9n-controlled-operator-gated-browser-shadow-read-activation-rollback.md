# Stage 9N Controlled Operator-Gated Browser Shadow-Read Activation and Rollback

Generated: 2026-06-12

## Stage purpose

Stage 9N performs one controlled operator-gated browser shadow-read activation and rollback.

Stage 9N temporarily enables backend router dry-run.
Stage 9N restarts edge-queue-controller for activation and rollback.
Stage 9N loads live-served router_shadow_read_stub.js.
Stage 9N loads the live-served Stage 9D browser-surface bridge block.
Stage 9N loads the live-served Stage 9K operator gate block.
Stage 9N enables browser shadow-read flags only inside a Node VM.
Stage 9N enables the operator gate only inside a Node VM.
Stage 9N calls requestBrowserSurfaceRouterShadowRead exactly once.
Stage 9N confirms exactly one request is sent.
Stage 9N confirms dry_run = true.
Stage 9N confirms dispatch_requested = false.
Stage 9N confirms dispatch_performed = false.
Stage 9N rolls backend dry-run back to disabled.

## Required pre-activation state

Before activation:

- Stage 9K evidence final_result remains pass.
- Stage 9L evidence final_result remains pass.
- Stage 9M report exists.
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
- POST /api/router/dry-run returns HTTP 404 before activation.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent before activation.
- Queue is clean before activation.

## Required activated state

During activation:

- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is present.
- POST /api/router/dry-run returns HTTP 200.
- Browser shadow-read flags are enabled only inside the Node VM.
- Operator gate is enabled only inside the Node VM.
- requestBrowserSurfaceRouterShadowRead is called exactly once.
- Exactly one frontend fetch is sent.
- The browser-surface request uses manual-diagnostic.
- The request is dry-run only.
- dispatch_requested = false.
- dispatch_performed = false.
- The backend response does not indicate dispatch.
- Queue remains clean during activation.

## Required rollback state

After rollback:

- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 is absent.
- POST /api/router/dry-run returns HTTP 404 after rollback.
- Browser shadow-read flags remain disabled in repo/static files.
- Operator gate remains disabled in repo/static files.
- frontend/wrapper-ui/app.js still contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js still contains ROUTER_SHADOW_READ_ENABLED = false.
- frontend/wrapper-ui/router_shadow_read_stub.js still contains ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- frontend/wrapper-ui/app.js still contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false.
- Queue remains clean after rollback.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.
