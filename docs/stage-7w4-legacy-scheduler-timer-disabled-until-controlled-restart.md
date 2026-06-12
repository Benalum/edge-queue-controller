# Stage 7W-4 Legacy Scheduler Timer Disabled Until Controlled Restart

Stage 7W-4 records the live safety state after fixing the legacy `/tick` source bug.

## Current state

The legacy scheduler timer is intentionally disabled and inactive:

- `edge-queue-scheduler-tick.timer`

This timer calls:

- `POST /tick`

## Why it is disabled

The source fix for `/tick` has been committed, but the live controller process has not been restarted yet.

Restarting the controller can interrupt the browser session, so the restart is deferred until a controlled maintenance point.

Until that restart happens, the running controller process may still have the old `/tick` code loaded.

Keeping the timer disabled prevents the old running process from receiving automatic `/tick` calls.

## Safe timers still active

The modern safe timers remain active:

- `edge-queue-power-auto-tick.timer`
- `edge-queue-remediation-tick.timer`

## Restore plan later

At a controlled restart window:

1. Restart `edge-queue-controller`.
2. Verify `/health` returns HTTP 200.
3. Manually run or test `POST /tick`.
4. Re-enable `edge-queue-scheduler-tick.timer`.
5. Watch one timer cycle and confirm no 500 errors.

## Safety boundary

This stage does not restart the controller.

This stage does not call `/tick`.

This stage does not re-enable the legacy scheduler timer.

This stage does not change router dispatch behavior.
