# Phase 12R-F Read-Only Model Memory Status

Phase 12R-F adds read-only model memory status evidence to `/system/status`.

## Goal

Expose model memory visibility before implementing warmup, unload, eviction, or persistent lane activation.

The status evidence is attached to the CT101 laptop queue worker service as:

- `model_memory_status.source`
- `model_memory_status.mode`
- `model_memory_status.ollama_base_url`
- `model_memory_status.ollama_reachable`
- `model_memory_status.ollama_version`
- `model_memory_status.installed_models`
- `model_memory_status.loaded_models`
- `model_memory_status.memory`
- `model_memory_status.safe_eviction_candidates`
- `model_memory_status.active_models`
- `model_memory_status.warming_models`
- `model_memory_status.last_warmup_decision`
- `model_memory_status.last_eviction_decision`

## Safety

Phase 12R-F is read-only.

It must not:

- warm models
- unload models
- call Ollama generate/chat endpoints
- run prompts
- start persistent lane workers
- change CT101 env files
- change Docker containers
- enable router rollout
- mark persistent cutover ready

## Ollama path

Phase 12R-E discovered that CT101 reaches Ollama at:

- `http://100.88.245.33:11434`

Phase 12R-F uses that path as the default read-only Ollama status base URL unless overridden by environment.

## Expected current state

Current expected safe state:

- primary worker active
- tiny lane worker inactive
- small lane worker inactive
- persistent cutover blocked
- router rollout parked
- installed models visible
- loaded models may be empty

## Future phases

Later phases can use this evidence to add:

1. read-only eviction candidate planning
2. guarded manual warm/unload helpers
3. `ensure_model_ready(model)`
4. controlled lane activation

Phase 12R-F only adds read-only status evidence.
