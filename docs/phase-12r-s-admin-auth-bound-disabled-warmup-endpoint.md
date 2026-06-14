# Phase 12R-S Admin-Auth Bound Disabled Warmup Endpoint

Phase 12R-S adds the existing admin support auth boundary to the disabled admin model warmup endpoint.

## Change

`POST /admin/model-warmup` now accepts `request: Request` and calls:

- `_admin_support_require_admin(request)`

The admin guard runs before the disabled warmup refusal is built.

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

## Expected behavior after a later guarded restart

- Unauthenticated/non-admin callers should fail at the admin boundary.
- Authenticated admins should still receive the disabled warmup refusal.
- Warmup execution remains unavailable.
- `would_call` remains `none`.
- `runtime_action_available` remains `false`.

## Deployment note

This phase is static only. A later phase must perform a guarded controller-only restart before live route behavior is expected to change.
