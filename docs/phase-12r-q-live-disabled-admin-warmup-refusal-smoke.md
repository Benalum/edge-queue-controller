# Phase 12R-Q Live Disabled Admin Warmup Refusal Smoke

Phase 12R-Q adds a reusable live smoke for the disabled admin model warmup endpoint.

## Purpose

After Phase 12R-P loaded the route into the running controller, this smoke verifies the disabled endpoint remains safe and refuses execution.

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

## Checks

The smoke verifies:

- `edge_controller.py` compiles.
- Phase 12R-N static endpoint contract still passes.
- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1` is not set.
- Local `/health` returns HTTP 200.
- Local `/system/status` returns HTTP 200.
- Live status exposes `model_memory_status.admin_model_warmup_endpoint`.
- `POST /admin/model-warmup` returns HTTP 403.
- The refusal detail reports `would_call: none`.
- The refusal detail reports `runtime_action_available: false`.
- The refusal detail reports `reason: warmup_action_disabled`.

The POST check is a refusal-contract check only.
