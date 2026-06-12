# Stage 6O Universal Intent Router HTTP Enabled Schema Smoke

Stage 6O proves the Universal Intent Router dry-run endpoint returns the required schema over HTTP when temporarily enabled.

This stage does not change runtime behavior.

The endpoint remains disabled by default after the smoke.

## Purpose

Stage 6N validates the helper response shape directly.

Stage 6O validates the same schema through the real FastAPI endpoint.

## Smoke flow

The smoke test:

1. Proves `/api/router/dry-run` returns HTTP 404 while disabled.
2. Temporarily enables `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`.
3. Restarts the controller.
4. Calls `/api/router/dry-run` over HTTP.
5. Validates the response schema.
6. Validates a normal Study request.
7. Validates a blocked Admin request.
8. Unsets the temporary environment variable.
9. Restarts the controller.
10. Proves `/api/router/dry-run` returns HTTP 404 again.

## Safety

The router still never dispatches.

The router still never calls a model.

The router still never mutates state.

Every HTTP response must prove:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`
- `eligible_for_dispatch=false`

## Stage boundary

Stage 6O adds only documentation and smoke coverage.

Stage 6O does not wire the router into any page.

Stage 6O does not enable dispatch.

Stage 6O does not enable model calls.
