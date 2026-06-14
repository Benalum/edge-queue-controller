# Phase 12R-X Inspect-Only Warmup Execution Boundary Design

Phase 12R-X records the inspected execution boundaries before any future model warmup execution path is added.

## Current state

The admin model warmup endpoint exists:

- `POST /admin/model-warmup`

It is admin-auth bounded and disabled.

The route currently:

- Requires `_admin_support_require_admin(request)`.
- Parses `model` and `dry_run`.
- Builds `_stage5p12m_disabled_admin_model_warmup_response(...)`.
- Raises `HTTPException(status_code=403, detail=response)`.

It must not call Ollama, warm models, unload models, start workers, or enable router rollout.

## Existing Ollama execution path

The existing direct Ollama execution path is separate:

- `POST /tick/ollama-direct`

That path is gated by:

- `EDGE_DIRECT_OLLAMA_FORWARD=1`
- `confirm=DIRECT_OLLAMA_FORWARD`

Phase 12R-X does not change or reuse that path.

## Existing model memory reads

The model memory helper is read-only and may inspect:

- `/api/version`
- `/api/tags`
- `/api/ps`

These are status reads only.

## Future warmup execution boundary

A future warmup execution phase must be separate and guarded. It must re-check immediately before execution:

- Admin auth.
- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1`.
- Model is installed.
- Model is not already loaded.
- CT101 memory is available.
- Projected loaded plus warming memory remains under the 80% budget.
- Model is allowed by lane policy.
- No active warming conflict exists.
- Explicit admin action request is present.
- Runtime action path is available.

## Future action shape

A future action may use a safe warmup call such as:

- Ollama endpoint: `/api/generate`
- Method: `POST`
- Prompt policy: empty or safe warmup prompt only
- Stream: false
- Keep alive: configured future value

This phase does not implement that call.

## Safety

This phase must not:

- Modify `edge_controller.py`.
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
