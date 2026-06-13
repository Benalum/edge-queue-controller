# Stage 10H Deferred Queued-Status Script Loader Implementation

Generated: 2026-06-12

## Stage purpose

Stage 10H implements a narrow deferred loader for queued_chat_status.js.

Stage 10H modifies frontend/wrapper-ui/index.html.
Stage 10H does not modify frontend/wrapper-ui/app.js.
Stage 10H does not modify queued_chat_config.js.
Stage 10H does not modify queued_chat_status.js.
Stage 10H does not modify edge_controller.py.
Stage 10H does not restart live services.
Stage 10H does not add a mutation endpoint.
Stage 10H does not enable browser router traffic.
Stage 10H does not enable backend router dry-run.
Stage 10H does not send frontend router POST traffic.
Stage 10H preserves logged-in/logged-out route boundaries.

## Implementation

Stage 10H keeps queued_chat_config.js as a normal script before the queued status helper.

Stage 10H replaces the direct queued_chat_status.js script tag with a tiny deferred loader.

The deferred loader:

- waits until window load when possible,
- falls back safely if the document is already loaded,
- injects queued_chat_status.js once,
- marks the script with data-stage10h-deferred-queued-status,
- avoids duplicate injection,
- keeps the same /queued_chat_status.js path,
- avoids changing queue helper source code.

## Why this is safe

Stage 10G proved queued_chat_status.js has:

- no fetch calls,
- no setInterval calls,
- no setTimeout calls,
- no DOMContentLoaded hooks,
- no window load hooks,
- no document references.

Because queued_chat_status.js only defines helper functions on the global object, deferred loading is a low-risk first startup-load reduction.

## Required current live state

After Stage 10H:

- Stage 10G evidence final_result remains pass.
- Stage 10F report exists.
- frontend/wrapper-ui/index.html references queued_chat_config.js before the deferred queued status loader.
- frontend/wrapper-ui/index.html no longer directly loads queued_chat_status.js with a plain script tag.
- frontend/wrapper-ui/index.html contains data-stage10h-deferred-queued-status.
- queued_chat_config.js remains unchanged.
- queued_chat_status.js remains unchanged.
- app.js remains unchanged by Stage 10H.
- edge_controller.py remains unchanged by Stage 10H.
- GET /api/router/persistent-rollout/status returns HTTP 200.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- edge_controller.py has no persistent rollout mutation route.
- Live frontend routes still return HTTP 200.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.

## Rollback

Rollback is simple:

- restore the original direct script tag for /queued_chat_status.js,
- remove the Stage 10H deferred loader block,
- rerun the Stage 10H smoke.
