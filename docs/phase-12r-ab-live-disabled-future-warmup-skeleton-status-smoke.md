# Phase 12R-AB Live Disabled Future Warmup Skeleton Status Smoke

Phase 12R-AB adds a reusable no-restart live smoke for the disabled future warmup skeleton status loaded by Phase 12R-AA.

## Purpose

After Phase 12R-Z attached the skeletons to read-only status and Phase 12R-AA restarted the controller, this smoke verifies the live runtime continues to expose:

- `model_memory_status.disabled_future_warmup_execution_skeletons`

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
- Phase 12R-Z static smoke passes.
- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1` is not set.
- `/health` returns HTTP 200.
- `/system/status` returns HTTP 200.
- Live status exposes disabled skeletons for:
  - `qwen3:0.6b`
  - `qwen3:1.7b`
  - `llama3.2:3b`
- Each skeleton remains non-executable.
- Unauthenticated `POST /admin/model-warmup` remains auth/admin blocked.
