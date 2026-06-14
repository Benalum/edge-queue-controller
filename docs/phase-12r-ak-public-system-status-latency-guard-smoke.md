# Phase 12R-AK Public System Status Latency Guard Smoke

Phase 12R-AK adds a reusable no-restart latency guard for the public /system/status endpoint.

## Purpose

Phase 12R-AJ fixed a live status-shape problem by adding a top-level model_memory_status snapshot to /system/status.

The first repair used the full read-only model-memory scan and made /system/status too slow when pveso or CT101 was degraded.

The final Phase 12R-AJ repair replaced that with a lightweight public-safe disabled snapshot.

This phase locks in that behavior.

## Expected behavior

/system/status must:

- Return HTTP 200.
- Expose top-level model_memory_status.
- Use source phase_12r_aj_public_system_status_model_memory_snapshot.
- Say network_calls: false.
- Say runtime_action_available: false.
- Say would_call: none.
- Include admin_model_warmup_endpoint.
- Include disabled_future_warmup_execution_skeletons.
- Stay responsive enough for existing smoke chains.

## Static requirements

_system_status_uncached must attach:

- _stage5p12aj_public_model_memory_status_snapshot

_system_status_uncached must not call:

- _stage5p12r_model_memory_status_read_only

The lightweight helper must not perform network or process execution.

## Safety

This phase must not:

- Restart the controller.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Print bearer token values.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.
- Warm any model.
- Unload any model.
