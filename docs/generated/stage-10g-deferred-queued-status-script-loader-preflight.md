# Stage 10G Deferred Queued-Status Script Loader Preflight

Generated: 2026-06-12

## Stage purpose

Stage 10G performs a deferred queued-status script loader implementation preflight.

Stage 10G is inspection/preflight only.
Stage 10G does not modify frontend/wrapper-ui/app.js.
Stage 10G does not modify frontend/wrapper-ui/index.html.
Stage 10G does not modify queued_chat_config.js.
Stage 10G does not modify queued_chat_status.js.
Stage 10G does not modify edge_controller.py.
Stage 10G does not restart live services.
Stage 10G does not add a mutation endpoint.
Stage 10G does not enable browser router traffic.
Stage 10G does not enable backend router dry-run.
Stage 10G does not send frontend router POST traffic.
Stage 10G does not change runtime status polling behavior.

## Why this preflight exists

Stage 10E showed index.html directly loads queued_chat_config.js and queued_chat_status.js.

Stage 10F selected deferred non-critical status loading as the preferred optimization direction.

Before changing runtime behavior, Stage 10G inspects queued_chat_status.js and queued_chat_config.js directly so the implementation can preserve script order, global variables, queue visibility, and route boundaries.

## Preflight questions

Stage 10G answers:

- Does queued_chat_status.js perform immediate fetches?
- Does queued_chat_status.js register load or DOMContentLoaded handlers?
- Does queued_chat_status.js use setInterval or setTimeout?
- Does queued_chat_status.js depend on queued_chat_config.js globals?
- Does queued_chat_config.js define required globals before queued_chat_status.js runs?
- Can queued_chat_status.js be safely loaded after app.js?
- Can queued_chat_status.js be deferred without breaking public/private route boundaries?

## Candidate Stage 10H implementation

If Stage 10G confirms it is safe, Stage 10H may implement a tiny deferred script loader for queued_chat_status.js.

Preferred implementation shape:

1. Keep queued_chat_config.js loading before queued_chat_status.js.
2. Replace direct queued_chat_status.js load with a tiny deferred loader.
3. Run the loader after initial page render or window load.
4. Preserve queue status on Chat/Companion surfaces.
5. Preserve System/Admin status behavior.
6. Preserve logged-in/logged-out route boundaries.
7. Preserve router parked posture.
8. Keep app.js free of /api/router/dry-run.
9. Keep backend dry-run disabled.
10. Add rollback instructions in the same stage.

## Required current live state

After Stage 10G:

- Stage 10F report exists.
- Stage 10E evidence final_result remains pass.
- queued_chat_config.js exists.
- queued_chat_status.js exists.
- index.html directly references queued_chat_config.js.
- index.html directly references queued_chat_status.js.
- GET /api/router/persistent-rollout/status returns HTTP 200.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- edge_controller.py has no persistent rollout mutation route.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.
