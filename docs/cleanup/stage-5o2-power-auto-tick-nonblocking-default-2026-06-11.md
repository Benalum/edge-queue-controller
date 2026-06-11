# Stage 5O-2 Power Auto Tick Non-Blocking Default — 2026-06-11

## Result

`/power/auto/tick` is now non-blocking by default.

## Reason

Stage 5O-1 proved that manually calling `/power/auto/tick` could timeout and then make `/health` timeout immediately afterward. That means the route could wedge the controller request path when Proxmox/SSH-backed planning was unreachable or slow.

## Change

The route now returns a safe quarantined response unless:

- `EDGE_POWER_AUTO_TICK_FULL=1`

This prevents accidental timer or browser-triggered calls from freezing the controller.

## Current timer state

The tick timers should remain stopped until the full power automation plan is split into safe background jobs or made fully timeout-bounded.

## Follow-up

Future work should move Proxmox inventory, host shutdown planning, worker stop planning, and wake/start planning out of the public controller request path.
