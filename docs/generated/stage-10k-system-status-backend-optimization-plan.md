# Stage 10K System Status Backend Optimization Plan

Generated: 2026-06-12

## Stage purpose

Stage 10K converts the Stage 10J /api/system/status latency evidence into a backend optimization plan.

Stage 10K is plan-only.
Stage 10K does not modify frontend/wrapper-ui/app.js.
Stage 10K does not modify frontend/wrapper-ui/index.html.
Stage 10K does not modify edge_controller.py.
Stage 10K does not restart live services.
Stage 10K does not add a mutation endpoint.
Stage 10K does not enable browser router traffic.
Stage 10K does not enable backend router dry-run.
Stage 10K does not send frontend router POST traffic.
Stage 10K does not change runtime status polling behavior.

## Stage 10J evidence summary

Stage 10J confirmed:

- /api/system/status returned HTTP 200.
- /api/system/status latency samples were consistently around 1.8 to 2.0 seconds.
- Mean /api/system/status latency was about 1.91 seconds.
- /health returned HTTP 200 much faster.
- /api/router/persistent-rollout/status returned HTTP 200 much faster.
- Queue remained clean.
- Timers remained correct.
- Router rollout remained parked.
- Backend router dry-run remained disabled.

## Primary optimization target

The primary optimization target is the backend work inside /system/status.

The likely expensive areas are:

- Proxmox CT/host state checks.
- Queue worker status checks.
- Power automation status checks.
- Combined normalized status construction.
- Any synchronous network/system calls inside system_status().
- Any repeated status calls that could be cached briefly.

## Recommended Stage 10L inspection

Stage 10L should inspect the /system/status handler source in detail.

Stage 10L should identify:

- every helper called by system_status(),
- whether each helper uses subprocess, SSH, curl, systemctl, network I/O, file I/O, or database I/O,
- whether each helper can be cached safely,
- which fields must be live every request,
- which fields can tolerate a short cache window,
- whether public status can remain fast and separate,
- whether admin/system detail can be split from lightweight status.

## Preferred Stage 10M implementation direction

If Stage 10L confirms a narrow safe path, Stage 10M should implement a short TTL cache around expensive /system/status sections.

Preferred implementation shape:

- Add a very small in-process cache for /system/status output.
- Use a short TTL, such as 2 to 5 seconds.
- Keep manual refresh behavior intact.
- Do not cache mutating operations.
- Do not change route names.
- Do not change auth behavior.
- Do not change logged-in/logged-out boundaries.
- Do not change queue semantics.
- Do not change power automation execution behavior.
- Include a bypass/force-refresh option only if already safe and read-only.
- Add evidence comparing before/after latency.
- Add rollback instructions.

## Do-not-do list

Stage 10L/10M must not:

- enable router dry-run,
- enable browser router traffic,
- add persistent rollout mutation routes,
- change public/private route boundaries,
- hide real queue failures,
- hide real worker failures for too long,
- change power automation execution behavior,
- restart services without an explicit controlled implementation stage.

## Transition closure position

The transition is functionally safe now.

Remaining work is closure/polish:

1. inspect and possibly reduce /api/system/status latency,
2. run a final operational baseline checkpoint,
3. tag the transition complete checkpoint.

Recommended path:

- Stage 10K: this plan.
- Stage 10L: source-level /system/status backend dependency inspection.
- Stage 10M: implement a short TTL cache only if Stage 10L proves it safe.
- Stage 10N: final transition-complete operational checkpoint.
