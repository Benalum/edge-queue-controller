# Stage 6AG Universal Intent Router DB-Backed Fixtures

Stage 6AG records DB-backed dry-run router fixture outputs.

This stage does not change runtime behavior.

This stage does not restart the controller.

This stage does not enable the router endpoint by default.

This stage does not dispatch.

This stage does not call models.

## Why this stage exists

Stage 6AF added SQLite phrase lookup observability to the disabled dry-run router helper.

Stage 6AG locks representative DB-backed lookup outputs into generated fixtures so future router changes cannot accidentally remove or break the DB lookup metadata.

## Fixture coverage

The fixture set covers:

- English Study next command
- English Study skip command
- English Study show answer command
- Spanish Study next command
- blocked Admin source

## Required safety values

Every fixture must prove:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`
- `eligible_for_dispatch=false`

## Required DB lookup values

Study fixtures must include:

- `router_lookup.stage=6AF`
- `router_lookup.sqlite_phrase_lookup.matched=true`
- a DB-backed canonical intent key such as `study.card.next`

Blocked admin fixtures must include:

- `router_lookup.sqlite_phrase_lookup.matched=false`
- `router_lookup.sqlite_phrase_lookup.error_code=source_surface_policy_blocked`

## Stage boundary

Stage 6AG only adds documentation, generated fixtures, and smoke coverage.

It does not wire router output into Study.

It does not wire router output into Companion.

It does not wire router output into Chat.

It does not wire router output into Calendar.

It does not make the endpoint public or enabled.
