# Stage 7Y-3 Power Automation Online With Retired Legacy Tick

Stage 7Y-3 updates System status semantics for Power Automation.

## Problem

Power Automation showed `degraded` because `edge-queue-scheduler-tick.timer` was disabled.

That was correct while `/tick` was still unsafe.

After Stage 7Y-2B and Stage 7Y-2C, `/tick` is now retired into a fast compatibility shim. The legacy scheduler timer should remain disabled.

## Fix

Power Automation should show `online` when:

- `edge-queue-power-auto-tick.timer` is active.
- `edge-queue-remediation-tick.timer` is active.
- `edge-queue-scheduler-tick.timer` is disabled/inactive.
- `EDGE_LEGACY_TICK_COMPAT_SHIM` is true, meaning legacy `/tick` is retired.

## Safety boundary

This stage is source-only.

This stage does not restart the controller.

This stage does not re-enable the legacy scheduler timer.

This stage does not change the modern timer endpoints.

This stage keeps router dispatch disabled.
