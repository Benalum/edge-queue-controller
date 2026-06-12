# Stage 6J Universal Intent Router Helper Module

Stage 6J extracts the deterministic Universal Intent Router dry-run helper logic into a small module.

This stage preserves behavior.

This stage keeps the dry-run endpoint disabled by default.

## New module

`edge_intent_router.py`

The module contains helper logic for:

- endpoint enabled flag check
- dry-run response construction
- deterministic Study command classification
- deterministic Companion/general chat classification
- basic language detection for supported aliases

## Safety

The helper module does not dispatch.

The helper module does not call models.

The helper module does not mutate application state.

The helper module returns contract-shaped dry-run observations only.

## Compatibility

`edge_controller.py` still exposes:

- `_stage6f_router_enabled`
- `_stage6f_router_response`
- `/api/router/dry-run`
- `/system/router/dry-run`

Existing Stage 6H and Stage 6I fixture smokes must continue to pass.

## Stage boundary

Stage 6J is a refactor only.

Stage 6J does not wire the router into Study, Companion, Chat, Calendar, Profile, Admin, queue, worker, or power automation.

Stage 6J does not enable dispatch.

Stage 6J does not enable model calls.
