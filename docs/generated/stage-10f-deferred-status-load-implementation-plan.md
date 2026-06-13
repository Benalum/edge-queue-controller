# Stage 10F Deferred Status-Load Implementation Plan

Generated: 2026-06-12

## Stage purpose

Stage 10F converts the Stage 10E startup fetch inspection into a narrow deferred status-load implementation plan.

Stage 10F is plan-only.
Stage 10F does not modify frontend/wrapper-ui/app.js.
Stage 10F does not modify frontend/wrapper-ui/index.html.
Stage 10F does not modify edge_controller.py.
Stage 10F does not restart live services.
Stage 10F does not add a mutation endpoint.
Stage 10F does not enable browser router traffic.
Stage 10F does not enable backend router dry-run.
Stage 10F does not send frontend router POST traffic.
Stage 10F does not change runtime status polling behavior.

## Stage 10E findings

Stage 10E found:

- app.js has 26 fetch-call lines.
- app.js has 7 setInterval lines.
- app.js has 33 setTimeout lines.
- index.html directly loads queued_chat_config.js.
- index.html directly loads queued_chat_status.js.
- app.js does not directly contain /api/system/status.
- app.js does not directly contain queued_chat_status.js.
- app.js does not directly contain queued_chat_config.js.
- router_shadow_read_stub.js has no fetch calls.
- Router rollout remains parked.

## Selected implementation direction

The safest first runtime optimization should be deferred non-critical status loading.

The recommended implementation should:

- Keep required app shell scripts loading normally.
- Keep app.js loading normally for now.
- Avoid route-boundary changes.
- Avoid auth/session behavior changes.
- Avoid Study/Companion/Profile/Admin behavior changes.
- Avoid router rollout behavior changes.
- Avoid changing backend controller behavior.
- Defer non-critical status refresh work until after the initial page render.
- Avoid eager repeated status refreshes on pages that do not need them immediately.
- Preserve manual refresh behavior.
- Preserve visible status on System/Admin surfaces.
- Preserve queue visibility on Companion/Chat surfaces.
- Add smoke coverage before and after implementation.

## Candidate Stage 10G implementation

Stage 10G should be a narrow implementation stage only if the inspection confirms the exact safe hook.

Preferred Stage 10G shape:

1. Add a small frontend helper for deferred status refresh scheduling.
2. Use a short post-render delay for non-critical system status refresh.
3. Keep immediate status fetch only where the current page requires it.
4. Do not remove existing status functions.
5. Do not change logged-in/logged-out route boundaries.
6. Do not change router shadow-read flags.
7. Do not change backend dry-run state.
8. Add evidence proving:
   - live routes still return HTTP 200,
   - app.js still contains no /api/router/dry-run,
   - backend dry-run remains HTTP 404,
   - queue remains clean,
   - timers remain correct,
   - port 7076 remains closed.

## Do-not-do list

Stage 10G must not:

- Split app.js yet.
- Remove queued_chat_status.js yet.
- Remove queued_chat_config.js yet.
- Change auth routing.
- Change public/private page boundaries.
- Change backend controller routes.
- Enable router dry-run.
- Enable browser router traffic.
- Add persistent rollout mutation routes.

## Required current live state

After Stage 10F:

- Stage 10E evidence final_result remains pass.
- Stage 10D report exists.
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
