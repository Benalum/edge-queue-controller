# Phase 12R-N Static Admin Warmup Endpoint Contract Smoke

Phase 12R-N adds a static contract smoke for the disabled admin model warmup endpoint created in Phase 12R-M.

## Purpose

The smoke verifies the endpoint shape without importing the app, restarting services, calling the live route, calling Ollama, or changing CT101.

## Contract checked

The smoke verifies:

- `POST /admin/model-warmup` exists.
- The route function is async.
- The route refuses with `HTTPException(status_code=403, detail=response)`.
- The route builds its response using `_stage5p12m_disabled_admin_model_warmup_response`.
- The read-only status exposes `model_memory_status.admin_model_warmup_endpoint`.
- The helper includes the disabled endpoint skeleton fields.
- No forbidden runtime strings are present in the route body.

## Safety

This phase must not:

- Import or execute `edge_controller.py`.
- Restart any service.
- Call Ollama.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm or unload models.
- Start persistent lane workers.
- Enable router rollout.
- Change CT101 worker runtime.
