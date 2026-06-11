# Stage 5N-4 Post-Recovery User-Facing Smoke — 2026-06-11

## Result

The post-recovery user-facing smoke passed.

## Checkpoint

Commit before this smoke:

- `ce29e0e`
- `controller-stage-5n3-bounded-tick-services-power-auto-quarantine-2026-06-11`

## What passed

Local wrapper routes returned HTTP 200 quickly:

- `/`
- `/companion`
- `/study`
- `/calendar`
- `/profile`
- `/admin`
- `/api/system/public-status`

Public routes returned HTTP 200 quickly:

- `/`
- `/companion`
- `/study`
- `/calendar`
- `/profile`
- `/api/system/public-status`

Controller health returned HTTP 200.

Wrapper public status returned HTTP 200.

No recent controller or wrapper errors appeared during the smoke window.

## Expected unauthenticated result

`/api/auth/me` returned HTTP 401 with `Missing bearer token`.

That is expected for an unauthenticated curl request.

## Timer state

All tick timers remained stopped:

- `edge-queue-power-auto-tick.timer`
- `edge-queue-power-idle-tick.timer`
- `edge-queue-remediation-tick.timer`
- `edge-queue-scheduler-tick.timer`

## Important safety note

Do not restart the tick timers yet.

`edge-queue-power-auto-tick.service` is quarantined as a `/usr/bin/true` no-op until `/power/auto/tick` is made non-blocking or moved out of the controller request path.
