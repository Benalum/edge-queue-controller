# Stage 9U Disabled Controller-Side Persistent Rollout Status Boundary

Generated: 2026-06-12

## Stage purpose

Stage 9U adds a disabled controller-side persistent rollout status boundary.

Stage 9U does not modify frontend/wrapper-ui/app.js.
Stage 9U does not enable browser router traffic.
Stage 9U does not enable backend router dry-run.
Stage 9U does not restart live services.
Stage 9U does not send frontend router POST traffic.
Stage 9U does not add any mutation endpoint.

## Implementation boundary

Stage 9U adds a read-only source route in `edge_controller.py`:

- GET /api/router/persistent-rollout/status

The source route returns:

- enabled = false
- status = disabled
- reason = persistent_operator_gated_rollout_disabled
- allowed_surfaces = ["manual-diagnostic"]
- dry_run = true
- dispatch_requested = false
- dispatch_performed = false
- mutation_supported = false
- activation_supported = false

## Required current source state

After Stage 9U:

- edge_controller.py contains PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = False.
- edge_controller.py contains PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH.
- edge_controller.py contains /api/router/persistent-rollout/status.
- edge_controller.py contains build_persistent_operator_gated_rollout_status.
- edge_controller.py contains mutation_supported = False.
- edge_controller.py contains activation_supported = False.
- edge_controller.py still contains /api/router/dry-run.
- frontend/wrapper-ui/app.js contains EdgeRouterShadowReadPersistentRollout.
- frontend/wrapper-ui/app.js contains PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false.
- frontend/wrapper-ui/app.js contains persistent_operator_gated_rollout_disabled.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Live-service note

Stage 9U intentionally does not restart edge-queue-controller.

The new controller-side status route is source-controlled in this stage. A later explicit live verification stage may restart the controller and verify the read-only disabled status endpoint live.

## Next recommended stage

Stage 9V should perform controlled live verification of the disabled controller-side persistent rollout status endpoint.

Stage 9V may restart edge-queue-controller only for live verification.
Stage 9V should not enable browser router traffic automatically.
Stage 9V should not enable backend router dry-run automatically.
Stage 9V should not add any mutation endpoint.
