# Phase 12R-V Optional Authenticated Admin Warmup Refusal Smoke

Phase 12R-V adds a reusable live smoke for authenticated admin access to the disabled model warmup endpoint.

## Auth path

`POST /admin/model-warmup` now uses:

- `_admin_support_require_admin(request)`

That guard resolves the user from a bearer token and requires admin status.

## Optional token

The smoke supports this optional environment variable:

- `EDGE_TEST_ADMIN_BEARER_TOKEN`

If the variable is not set, the smoke verifies only the unauthenticated auth-boundary behavior and reports the authenticated-admin check as skipped.

If the variable is set, the smoke verifies that an authenticated admin reaches the disabled warmup refusal contract.

## Safety

This phase must not:

- Restart any service.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Call Ollama directly.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm any model.
- Unload any model.
- Print bearer token values.

## Expected behavior

Without a token:

- `POST /admin/model-warmup` returns HTTP 401 or 403.
- The response must not expose warmup refusal internals.

With a valid admin token:

- `POST /admin/model-warmup` returns HTTP 403.
- The response detail is the disabled warmup refusal contract.
- `would_call` remains `none`.
- `runtime_action_available` remains `false`.
- `reason` remains `warmup_action_disabled`.
