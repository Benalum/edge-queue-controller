# Stage 6G Universal Intent Router Local Enabled Smoke

Stage 6G proves the disabled Stage 6F dry-run router endpoint works when deliberately enabled for a local smoke test.

## Purpose

Stage 6F added the endpoint but left it disabled by default.

Stage 6G verifies:

1. The endpoint is disabled by default.
2. A local-only smoke can enable it temporarily.
3. The endpoint returns a contract-shaped dry-run response over HTTP.
4. The endpoint never dispatches.
5. The endpoint never calls a model.
6. The endpoint is disabled again after the smoke.

## Safety

The smoke uses a temporary systemd manager environment variable:

`EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`

The smoke restarts the controller to load the temporary flag.

The smoke then unsets the flag and restarts the controller again.

The final expected state is disabled:

- `/api/router/dry-run` returns HTTP 404
- `dispatch_performed` is never true
- `model_call_required` is never true
- `allowed_to_dispatch` is never true

## Stage boundary

Stage 6G does not wire the router into Study, Companion, Chat, Calendar, Profile, Admin, queue, worker, or power automation.

Stage 6G does not add model calls.

Stage 6G does not enable dispatch.

Stage 6G is only a local proof that the disabled dry-run endpoint behaves safely when intentionally enabled.
