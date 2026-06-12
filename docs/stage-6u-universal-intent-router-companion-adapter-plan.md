# Stage 6U Universal Intent Router Companion Adapter Plan

Stage 6U defines the future Companion adapter boundary for the Universal Intent Router.

This stage is docs-only.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, power automation, systemd, gateway, backend, or frontend behavior.

## Goal

Prepare a safe path for Companion input to eventually pass through the Universal Intent Router without breaking existing Companion or queued chat behavior.

## Current Companion router candidates

The current Companion/chat routes treated as router candidates are:

- `/api/companion/chat`
- `/api/chat/queued`

These routes should not be replaced directly.

A future adapter should observe intent and policy first, then only later route when proven safe.

## Initial Companion intent scope

The initial Companion adapter may support:

- `companion.chat`
- `unknown.general_chat`

## Adapter boundary

The Companion adapter must:

- accept user-facing Companion or Chat input only
- use `source=companion` or `source=chat`
- use `surface=companion_chat` or equivalent user-facing chat surface
- use `active_page=companion` or `active_page=chat`
- preserve existing Companion handler behavior
- preserve existing queued chat behavior
- call the router in dry-run mode first
- avoid dispatch until a later explicit dispatch stage
- avoid model tier escalation without an explicit model policy

## Required safety fields

Before any future Companion adapter routing, the router result must include:

- `dry_run=true` during dry-run stages
- `dispatch_performed=false` during dry-run stages
- `allowed_to_dispatch=false` during dry-run stages
- `source_surface_policy.allowed=true`
- `intent.confidence_band`
- `confirmation_policy`
- `decision_trace`
- `model_routing.tier`
- `model_routing.model_call_required`

## Never route through Companion adapter

The Companion adapter must reject or ignore:

- admin input
- auth input
- power input
- internal input
- system input
- worker input
- queue-control input
- billing input
- password/security input
- calendar write input without explicit future confirmation policy
- profile mutation input without explicit future confirmation policy

## Future migration sequence

1. Keep existing Companion and queued chat handlers unchanged.
2. Add a Companion shadow adapter helper in a future stage.
3. Run the router in dry-run mode beside existing Companion behavior.
4. Compare router intent and model tier against current behavior.
5. Add smoke tests proving no user-visible behavior changed.
6. Only later allow safe adapter routing behind an explicit flag.

## Stage boundary

Stage 6U only creates a plan and smoke coverage.

Stage 6U does not wire the router into Companion.

Stage 6U does not modify Companion routes.

Stage 6U does not enable dispatch.

Stage 6U does not enable model calls.
