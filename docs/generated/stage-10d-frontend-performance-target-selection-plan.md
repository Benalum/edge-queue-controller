# Stage 10D Frontend Performance Target Selection Plan

Generated: 2026-06-12

## Stage purpose

Stage 10D selects the first frontend performance optimization target from the Stage 10C baseline.

Stage 10D is plan-only.
Stage 10D does not modify frontend/wrapper-ui/app.js.
Stage 10D does not modify edge_controller.py.
Stage 10D does not restart live services.
Stage 10D does not add a mutation endpoint.
Stage 10D does not enable browser router traffic.
Stage 10D does not enable backend router dry-run.
Stage 10D does not send frontend router POST traffic.

## Stage 10C baseline findings

Stage 10C recorded:

- app.js baseline size: 323331 bytes.
- router_shadow_read_stub.js baseline size: 6830 bytes.
- Required live frontend routes returned HTTP 200.
- /api/system/status was the slowest measured route at about 2.058351 seconds.
- /api/system/status is the slowest measured route.
- Router rollout remained parked.
- Queue remained clean.
- Timers remained correct.
- Port 7076 remained closed.

## Selected first optimization target

The first optimization target should be startup/status load pressure.

Why:

- app.js is large but currently still loads fast locally.
- /api/system/status is much slower than static assets.
- The frontend likely benefits first from reducing unnecessary startup status polling, duplicate status fetches, or eager status refreshes.
- This target is lower-risk than splitting app.js because it can be guarded with smoke tests around route boundaries and queue visibility.

## Stage 10E recommended implementation

Stage 10E should inspect frontend startup fetch behavior and add a guarded plan before modifying runtime behavior.

Stage 10E should:

- Locate all startup calls to /api/system/status.
- Locate all startup calls to queued_chat_status.js.
- Locate all startup calls to queued_chat_config.js.
- Identify duplicate or eager fetch paths.
- Identify status polling intervals.
- Identify which pages need immediate status and which can defer it.
- Propose a no-regression implementation for lazy/deferred status loading.
- Keep logged-in/logged-out route boundaries unchanged.
- Keep router rollout parked.

Stage 10E should not yet modify runtime behavior unless the inspection proves a narrow, safe change.

## Guardrails for future implementation

A future optimization must preserve:

- Full app pages only for logged-in users.
- Logged-out users see public/preview pages.
- Study, Companion, Profile, Admin, and System route boundaries.
- Queue visibility where it is required.
- Server/worker status visibility where it is required.
- Router rollout parked posture.
- Backend dry-run disabled.
- No direct /api/router/dry-run in app.js.
- Clean queue.
- Correct timers.
- Port 7076 closed.

## Required current live state

After Stage 10D:

- Stage 10C evidence final_result remains pass.
- Stage 10C evidence includes app_js_bytes = 323331.
- Stage 10C evidence includes required route HTTP 200 values.
- GET /api/router/persistent-rollout/status returns HTTP 200.
- POST /api/router/dry-run remains HTTP 404.
- EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent.
- frontend/wrapper-ui/app.js contains no /api/router/dry-run.
- ROUTER_SHADOW_READ_ENABLED = false.
- ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false.
- edge_controller.py has no persistent rollout mutation route.
- Queue remains clean.
- Modern timers remain active.
- Legacy scheduler timer remains inactive/disabled.
- Port 7076 remains closed.
