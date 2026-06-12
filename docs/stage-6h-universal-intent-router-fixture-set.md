# Stage 6H Universal Intent Router Fixture Set

Stage 6H adds a fixture-based smoke test for the Universal Intent Router dry-run helper.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, power automation, systemd, gateway, or frontend behavior.

## Purpose

Stage 6H creates repeatable test coverage for the deterministic dry-run classifier added in Stage 6F.

The fixture set covers:

- English study next command
- English study skip command
- English study hint command
- Spanish study next command
- Companion chat input
- Unknown general chat input
- Empty unsupported input

## Safety expectations

Every fixture must prove:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`

## Stage boundary

Stage 6H only adds fixtures, documentation, and smoke coverage.

It does not enable the router endpoint.

It does not dispatch.

It does not call a model.

It does not wire the router into any app page.
