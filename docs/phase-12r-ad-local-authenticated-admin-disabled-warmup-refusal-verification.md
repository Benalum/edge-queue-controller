# Phase 12R-AD Local Authenticated Admin Disabled Warmup Refusal Verification

Phase 12R-AD verifies the valid authenticated admin path for the disabled model warmup endpoint.

## Purpose

Previous phases verified that unauthenticated requests are blocked before warmup refusal. This phase verifies that a valid admin bearer token reaches the disabled warmup refusal contract.

## Local-only token handling

The stage script prompts for the admin bearer token locally using a silent prompt.

The token must not be:

- Printed.
- Written to a file.
- Committed.
- Passed to curl on the command line.
- Shared with ChatGPT.

The token is used only inside a local Python process to make the authenticated request.

## Expected authenticated behavior

`POST /admin/model-warmup` with a valid admin bearer token must return HTTP 403 with:

- `source: phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton`
- `mode: disabled_endpoint_skeleton`
- `endpoint: /admin/model-warmup`
- `method: POST`
- `dry_run_only: true`
- `runtime_action_available: false`
- `admin_endpoint_available: true`
- `would_call: none`
- `reason: warmup_action_disabled`

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
