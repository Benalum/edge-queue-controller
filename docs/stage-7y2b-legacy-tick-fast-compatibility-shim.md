# Stage 7Y-2B Legacy Tick Fast Compatibility Shim

Stage 7Y-2B retires the legacy `/tick` executor path into a fast compatibility shim.

## Problem

After the controlled restart, the old crash was fixed, but a one-shot POST to `/tick` still timed out after 30 seconds.

The controller stayed healthy and no traceback was observed, but `/tick` remained unsafe for a repeating scheduler timer because it could enter old long-running worker readiness or forwarding paths.

## Current safe automation

The modern timer endpoints are the active automation paths:

- `/workers/remediation/tick`
- `/power/auto/tick`
- `/power/idle/tick`

These endpoints responded quickly during inspection.

## Fix

`/tick` now returns a fast compatibility response by default.

It reports that legacy `/tick` is retired as a scheduler executor and points to the modern timer endpoints.

## Safety boundary

This stage is source-only.

This stage does not restart the controller.

This stage does not re-enable the legacy scheduler timer.

This stage does not call `/tick` against the live old process.

This stage keeps router dispatch disabled.
