# Stage 5O-3 Safe Tick Timers Restored — 2026-06-11

## Result

Safe tick timers were restored after `/power/auto/tick` was made non-blocking by default.

## Enabled

- `edge-queue-scheduler-tick.timer`
- `edge-queue-remediation-tick.timer`

## Kept stopped intentionally

- `edge-queue-power-idle-tick.timer`
- `edge-queue-power-auto-tick.timer`

## Reason

`edge-queue-power-idle-tick.timer` still touches Proxmox inventory and idle stop/shutdown logic, so it should stay stopped until the Proxmox/SSH planning path is split out of the controller request path or made fully safe.

`edge-queue-power-auto-tick.timer` is currently quarantined as a no-op service and is not needed yet.

## Safety checkpoint

`/power/auto/tick` returns a quarantined non-blocking response unless `EDGE_POWER_AUTO_TICK_FULL=1`.

Do not enable `EDGE_POWER_AUTO_TICK_FULL=1` until the full power automation planner is redesigned.
