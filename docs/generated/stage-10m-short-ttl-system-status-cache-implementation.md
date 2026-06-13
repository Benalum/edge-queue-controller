# Stage 10M Short TTL System Status Cache Implementation

Generated: 2026-06-12

## Stage purpose

Stage 10M implements a very short in-process TTL cache around /system/status.

Stage 10M modifies edge_controller.py.
Stage 10M does not modify frontend/wrapper-ui/app.js.
Stage 10M does not modify frontend/wrapper-ui/index.html.
Stage 10M does not add a mutation endpoint.
Stage 10M does not enable browser router traffic.
Stage 10M does not enable backend router dry-run.
Stage 10M does not send frontend router POST traffic.
Stage 10M preserves logged-in/logged-out route boundaries.
Stage 10M performs a controlled edge-queue-controller restart to load the backend implementation.

## Implementation

Stage 10M wraps the existing /system/status handler with a read-only cache.

The original handler is renamed to _system_status_uncached().

The public /system/status route calls _system_status_cached_payload().

The cache:

- uses a default TTL of 2 seconds,
- can be tuned with EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS,
- clamps TTL between 0 and 10 seconds,
- stores only the composed read-only /system/status payload,
- does not cache mutating operations,
- does not change route names,
- does not change auth behavior,
- does not change queue semantics,
- does not change power automation execution behavior.

## Why this is safe

Stage 10L confirmed the slow work is inside read-only status helper composition.

The /system/status route is a read-only status route.

A 2-second cache window reduces repeated browser/status polling pressure while keeping the status fresh enough for the current UI.

## Rollback

Rollback:

1. Restore edge_controller.py from the previous commit.
2. Restart edge-queue-controller.
3. Rerun the Stage 10M smoke or the latest stability smoke.

Example rollback:

git checkout HEAD~1 -- edge_controller.py
sudo systemctl restart edge-queue-controller
bash ops/smoke/check-stage-10m-short-ttl-system-status-cache-implementation.sh

## Required current live state

After Stage 10M:

- Stage 10L evidence final_result remains pass.
- Stage 10J evidence final_result remains pass.
- edge_controller.py compiles.
- /system/status route exists.
- _system_status_uncached exists.
- _system_status_cached_payload exists.
- EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS support exists.
- GET /health returns HTTP 200 after restart.
- GET /api/system/status returns HTTP 200.
- repeated /api/system/status samples show improved average latency.
- GET /api/router/persistent-rollout/status returns HTTP 200.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- frontend/wrapper-ui/index.html still contains the Stage 10H deferred loader marker.
- frontend/wrapper-ui/index.html still has no plain queued_chat_status.js script tag.
- router_shadow_read_stub.js contains /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- edge_controller.py has no persistent rollout mutation route.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.
