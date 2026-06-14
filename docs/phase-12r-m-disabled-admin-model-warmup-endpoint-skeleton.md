# Phase 12R-M Disabled Admin Model Warmup Endpoint Skeleton

Phase 12R-M adds the admin API shape for a future model warmup action, but keeps it disabled.

## Safety

This phase must not:

- Call Ollama.
- Warm any model.
- Unload any model.
- Start persistent lane workers.
- Enable router rollout.
- Mark persistent lane cutover ready.
- Change CT101 worker runtime.

## Added API shape

The FastAPI route exists:

- `POST /admin/model-warmup`

The route always refuses with HTTP 403.

The refusal detail includes:

- `source: phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton`
- `mode: disabled_endpoint_skeleton`
- `endpoint: /admin/model-warmup`
- `method: POST`
- `dry_run_only: true`
- `runtime_action_available: false`
- `admin_endpoint_available: true`
- `would_call: none`
- `required_env: EDGE_MODEL_WARMUP_ACTION_ENABLED=1`
- `reason: warmup_action_disabled`

## Status exposure

`model_memory_status.admin_model_warmup_endpoint` exposes the same disabled skeleton shape for read-only inspection.

## Follow-up

A later phase may add guarded execution, but only after explicit enablement and separate safety smokes.
