# Phase 12R-AH Disabled Warmup Control Plane Readiness Rollup

Phase 12R-AH adds a reusable no-restart rollup smoke for the disabled model warmup control plane.

## Purpose

This phase proves the disabled warmup control plane is stable after:

- Admin auth boundary.
- Disabled admin warmup endpoint.
- Disabled future warmup execution skeleton.
- Read-only future preview in the admin refusal.
- Guarded live restart verification.
- Optional authenticated preview smoke.

## Expected live behavior

Unauthenticated `POST /admin/model-warmup` must be blocked before the warmup refusal.

Authenticated checks are handled by the optional Phase 12R-AG smoke when a local token is supplied, but this rollup must pass safely without any token.

The live read-only status must still expose:

- `model_memory_status.admin_model_warmup_endpoint`
- `model_memory_status.disabled_future_warmup_execution_skeletons`

All execution markers must remain disabled:

- `runtime_action_available: false`
- `would_call: none`
- `future_ollama_request.execute_now: false`

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
