# Stage 6V Universal Intent Router Companion Shadow Adapter

Stage 6V adds a dry-run-only Companion shadow adapter helper.

This stage does not wire the router into Companion.

This stage does not change runtime Companion or Chat behavior.

## Purpose

Stage 6U defined the future Companion adapter plan.

Stage 6V adds a helper that can translate Companion-shaped payloads into Universal Intent Router dry-run input without dispatching.

The helper accepts Companion-like fields such as:

- `text`
- `message`
- `prompt`
- `content`
- `input.text`

## Safety

The Companion shadow adapter:

- is not wired into any route
- does not dispatch
- does not call a model
- does not mutate Companion state
- does not mutate Calendar state
- does not mutate Profile state
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

Stage 6V only adds a helper, fixtures, documentation, and smoke coverage.

Stage 6V does not modify Companion handlers.

Stage 6V does not modify Chat handlers.

Stage 6V does not modify frontend wiring.

Stage 6V does not enable dispatch.

Stage 6V does not enable model calls.
