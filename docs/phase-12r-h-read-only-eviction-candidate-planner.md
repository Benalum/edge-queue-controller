# Phase 12R-H Read-Only Eviction Candidate Planner

Phase 12R-H adds a read-only eviction candidate planner to `model_memory_status`.

## Goal

The platform now has read-only visibility into:

- installed models
- loaded models
- controller memory
- CT101 memory
- active models
- warming models

Phase 12R-H uses that evidence to calculate what would be eligible for future eviction, without unloading anything.

## Status fields

The CT101 worker status should expose:

- `model_memory_status.eviction_plan`
- `model_memory_status.eviction_plan.mode`
- `model_memory_status.eviction_plan.action_enabled`
- `model_memory_status.eviction_plan.reason`
- `model_memory_status.eviction_plan.candidates`
- `model_memory_status.eviction_plan.blocked`
- `model_memory_status.safe_eviction_candidates`

## Current expected result

Because Ollama `/api/ps` currently reports no loaded models, the expected result is:

- `loaded_models = []`
- `safe_eviction_candidates = []`
- `eviction_plan.mode = read_only`
- `eviction_plan.action_enabled = false`
- `eviction_plan.reason = no_loaded_models`

## Safety

Phase 12R-H is read-only.

It must not:

- warm models
- unload models
- call Ollama generate/chat endpoints
- call Ollama unload or stop commands
- run prompts
- start persistent lane workers
- change CT101 env files
- change Docker containers
- enable router rollout
- mark persistent cutover ready

## Future phases

Later phases can use this planner to support:

1. manual guarded model warm checks
2. manual guarded model unload checks
3. model reservation tracking
4. `ensure_model_ready(model)`
5. persistent lane activation

Phase 12R-H only plans and reports. It performs no eviction.
