# Stage 7W-3 Fix Legacy Tick Pause Parser Helper

Stage 7W-3 corrects the source-only Stage 7W-1 patch.

## Problem

Stage 7W-1 added a local `web_presence_start_pause_minutes` value for legacy:

- `POST /tick`

But it used:

- `_parse_int_env(...)`

The live controller showed that helper is not defined in this file:

- `NameError: name '_parse_int_env' is not defined`

## Fix

The legacy `/tick` route now parses `WEB_POWER_START_PAUSE_MINUTES` locally with plain `int(os.getenv(...))`, catches invalid values, and clamps the value between 1 and 120 minutes.

## Runtime safety

The legacy scheduler timer has been disabled/inactive until a controlled restart can load the fix.

No controller restart is performed in this source-only stage.

## Safety boundary

This stage does not enable router dispatch.

This stage does not enable model calls.

This stage does not re-enable the legacy scheduler timer.

This stage does not restart the controller.
