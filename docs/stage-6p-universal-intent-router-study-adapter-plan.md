# Stage 6P Universal Intent Router Study Adapter Plan

Stage 6P defines the future Study adapter boundary for the Universal Intent Router.

This stage is docs-only.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, power automation, systemd, gateway, or frontend behavior.

## Goal

Prepare a safe path for Study input to eventually pass through the Universal Intent Router without breaking existing Study behavior.

## Current Study router candidates

The current Study routes classified as router candidates are:

- `/api/study/intent/parse`
- `/api/study/session/command`

These routes should not be replaced directly.

A future adapter should sit in front of them, observe intent, and only later dispatch when proven safe.

## Initial Study intent scope

The initial Study adapter may support:

- `study.next`
- `study.skip`
- `study.hint`
- `study.answer`

## Adapter boundary

The Study adapter must:

- accept user-facing Study input only
- use `source=study`
- use `surface=study_session`
- use `active_page=study`
- call the router in dry-run mode first
- preserve existing Study handler behavior
- avoid model calls for short command aliases
- avoid dispatch until a later explicit dispatch stage

## Required safety fields

Before any future Study dispatch, the router result must include:

- `dry_run=true` during dry-run stages
- `dispatch_performed=false` during dry-run stages
- `model_call_required=false` for deterministic aliases
- `allowed_to_dispatch=false` during dry-run stages
- `source_surface_policy.allowed=true`
- `intent.confidence_band`
- `confirmation_policy`
- `decision_trace`

## Never route through Study adapter

The Study adapter must reject or ignore:

- admin input
- auth input
- power input
- internal input
- system input
- worker input
- queue input
- billing input
- password/security input
- calendar write input
- profile mutation input
- delete actions without explicit confirmation

## Future migration sequence

1. Keep existing Study handlers unchanged.
2. Add a Study adapter wrapper in a future stage.
3. Run the router in dry-run mode beside existing Study command handling.
4. Compare router intent with current Study behavior.
5. Add smoke tests proving no user-visible behavior changed.
6. Only later allow dispatch for safe high-confidence Study commands.

## Stage boundary

Stage 6P only creates a plan and smoke coverage.

Stage 6P does not wire the router into Study.

Stage 6P does not enable dispatch.

Stage 6P does not call a model.
