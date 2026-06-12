# Stage 7I Local Authenticated Runner No-Create Guard

Stage 7I proves the future authenticated shadow comparison runner has not been created yet.

This stage does not create the runner.

This stage does not change runtime behavior.

This stage does not run authenticated comparisons.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7H defined the future runner plan.

Stage 7I creates a guard that keeps the future runner plan documentation-only until we intentionally create the runner in a later stage.

## Future runner path

The planned future runner path is:

- `ops/compare/run-authenticated-shadow-comparison.py`

That file must not exist during Stage 7I.

## Allowed references

References to the future runner path and `EDGE_AUTH_SHADOW_COMPARE` environment variables are allowed only in:

- Stage 7H docs/generated plan
- Stage 7H markdown doc
- Stage 7H smoke
- Stage 7I docs/generated guard
- Stage 7I markdown doc
- Stage 7I smoke

## Blocked runtime locations

Future runner references must not appear in:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

## Stage boundary

Stage 7I is a no-create guard.

Stage 7I does not expose a new HTTP endpoint.

Stage 7I does not modify runtime handlers.

Stage 7I does not modify frontend behavior.

Stage 7I does not enable router dispatch.

Stage 7I does not enable router model calls.

Stage 7I does not use cookies, bearer tokens, passwords, or secrets.
