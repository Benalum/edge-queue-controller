# Phase 12R-P Guarded Controller Restart Live Disabled Admin Warmup Verification

Phase 12R-P performs a guarded controller-only restart so the running FastAPI service loads the committed Phase 12R-M disabled admin warmup endpoint.

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
- Live status exposes the disabled admin warmup endpoint snapshot if the route code is loaded.
- `POST /admin/model-warmup` refuses with HTTP 403.
- The refusal detail reports `would_call: none`.
- The refusal detail reports `runtime_action_available: false`.
- The refusal detail reports `reason: warmup_action_disabled`.

The POST is a refusal-contract check only. It must not perform warmup execution.
