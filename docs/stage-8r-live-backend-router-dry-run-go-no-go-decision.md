# Stage 8R Live Backend Router Dry-Run Go/No-Go Decision

Stage 8R records the go/no-go decision after the temporary-controller router dry-run validation in Stage 8Q.

This is a docs/generated-report/smoke-only stage.

## Current Decision

**No-go for live backend router dry-run enablement right now.**

The temporary controller proved the router dry-run contract works safely when explicitly enabled on a separate port, but the live controller should remain disabled until a separate manual activation stage.

## Why No-Go

The system is safe and functional in the current state:

- live router endpoint is disabled
- browser frontend contains no `/api/router/dry-run`
- frontend feature flag remains off by default
- Study behavior is unchanged
- Companion behavior is unchanged
- dispatch remains disabled
- model calls remain disabled
- queue is clean
- platform is online

## What Stage 8Q Proved

Stage 8Q proved a temporary controller can return safe router dry-run `decision_contract` records for:

- Study next
- Study skip
- Study show answer
- Companion chat
- Admin blocked/unsupported

Every temporary response kept:

- `dry_run = true`
- `dispatch_performed = false`
- `model_call_required = false`
- `allowed_to_dispatch = false`
- `eligible_for_dispatch = false`

## Required Boundary Before Any Future Live Enablement

Before enabling live backend dry-run:

- create a systemd override plan
- create a rollback command
- confirm frontend still has no router endpoint call
- confirm router responses are consumed as `decision_contract` only
- confirm dispatch remains impossible
- confirm model calls remain impossible
- confirm platform/queue/timers are clean before and after

## Stage 8R Safety

Stage 8R does not:

- edit runtime controller source
- edit frontend runtime source
- restart the live controller
- restart the wrapper UI
- enable `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED`
- add `/api/router/dry-run` to frontend code
- dispatch Study commands
- call models

## Recommended Next Stage

Stage 8S may prepare a live backend dry-run activation and rollback plan, but should still avoid enabling it unless the operator explicitly chooses to proceed.
