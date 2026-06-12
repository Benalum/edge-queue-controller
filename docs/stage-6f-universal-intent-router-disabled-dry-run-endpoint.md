# Stage 6F Universal Intent Router Disabled Dry-Run Endpoint

Stage 6F adds the first Universal Intent Router runtime skeleton.

The endpoint is disabled by default.

This stage does not change Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, or power automation behavior.

## Routes

- `/api/router/dry-run`
- `/system/router/dry-run`

## Feature flag

The endpoint only responds when:

`EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`

## Safety

The endpoint never dispatches.

The endpoint never calls a model.

The endpoint never mutates app state.

The endpoint always returns:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`

## Stage boundary

Stage 6F does not wire the router into any existing page.

Stage 6F does not replace existing handlers.

Stage 6F does not enable dispatch.
