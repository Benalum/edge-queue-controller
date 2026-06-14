# Phase 12R-AA Guarded Restart Live Disabled Future Warmup Skeleton Status

Phase 12R-AA performs a guarded controller-only restart so the running FastAPI service loads the Phase 12R-Z read-only status attachment.

## Allowed runtime action

This phase may restart only:

- `edge-queue-controller`

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

## Live verification

After restart, `/system/status` must expose:

- `model_memory_status.disabled_future_warmup_execution_skeletons`

For each expected model:

- `qwen3:0.6b`
- `qwen3:1.7b`
- `llama3.2:3b`

Each skeleton must remain disabled:

- `source: phase_12r_y_disabled_future_warmup_execution_skeleton`
- `mode: disabled_future_execution_skeleton`
- `runtime_action_available: false`
- `would_call: none`
- `future_ollama_request.execute_now: false`
- `reason: runtime_action_unavailable`

The `/api/generate` value is a documented future request shape only. It must not be called.
