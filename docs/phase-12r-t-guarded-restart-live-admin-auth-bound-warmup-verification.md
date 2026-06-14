# Phase 12R-T Guarded Restart Live Admin-Auth Bound Warmup Verification

Phase 12R-T performs a guarded controller-only restart so the running FastAPI service loads the Phase 12R-S admin-auth boundary for `POST /admin/model-warmup`.

## Safety

This phase must not:

- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Call Ollama directly.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm any model.
- Unload any model.

## Allowed runtime action

This phase may restart only:

- `edge-queue-controller`

## Verification

After restart, the stage script checks:

- `/health` returns HTTP 200.
- `/system/status` returns HTTP 200.
- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1` is not set.
- Unauthenticated `POST /admin/model-warmup` is blocked before the warmup refusal contract.
- The unauthenticated response does not expose `phase_12r_m_disabled_admin_model_warmup_endpoint_skeleton`.
- The unauthenticated response does not expose `would_call: none`.
- The unauthenticated response does not expose `warmup_action_disabled`.

Authenticated admin behavior will be verified in a later phase using a real admin session path.
