# Stage 6Q Universal Intent Router Study Shadow Adapter

Stage 6Q adds a dry-run-only Study shadow adapter helper.

This stage does not wire the router into Study.

This stage does not change runtime Study behavior.

## Purpose

Stage 6P defined the future Study adapter plan.

Stage 6Q adds a helper that can translate Study-shaped payloads into Universal Intent Router dry-run input without dispatching.

The helper is useful for future comparison tests because it accepts Study-like fields such as:

- `command`
- `action`
- `text`
- `answer`
- `message`
- `input.text`

## Safety

The Study shadow adapter:

- is not wired into any route
- does not dispatch
- does not call a model
- does not mutate Study state
- returns `behavior_changed=false`
- returns `dispatch_performed=false`
- returns `allowed_to_dispatch=false`

## Expected output

The helper returns:

- original payload key summary
- normalized router input
- router dry-run result
- shadow summary
- safety flags

## Stage boundary

Stage 6Q only adds a helper, fixtures, documentation, and smoke coverage.

Stage 6Q does not modify Study handlers.

Stage 6Q does not modify frontend wiring.

Stage 6Q does not enable dispatch.

Stage 6Q does not enable model calls.
