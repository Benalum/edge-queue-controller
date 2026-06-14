# Phase 12R-I Read-Only Model Warmup Planner

Phase 12R-I adds a read-only model warmup planner to `model_memory_status`.

## Goal

The platform now has read-only visibility into:

- installed models
- loaded models
- controller memory
- CT101 memory
- eviction planning

Phase 12R-I uses that evidence to calculate which lane models would be eligible for future warmup, without loading anything.

## Status fields

The CT101 worker status should expose:

- `model_memory_status.warmup_plan`
- `model_memory_status.warmup_plan.mode`
- `model_memory_status.warmup_plan.action_enabled`
- `model_memory_status.warmup_plan.default_target_models`
- `model_memory_status.warmup_plan.candidates`
- `model_memory_status.warmup_plan.blocked`
- `model_memory_status.warmup_candidates`

## Current expected target models

The initial read-only target models are the current tiny/small lane models:

- `qwen3:0.6b`
- `qwen3:1.7b`
- `llama3.2:3b`

## Expected current result

Because those models are installed and Ollama `/api/ps` currently reports no loaded models, the expected planner result is:

- `warmup_plan.mode = read_only`
- `warmup_plan.action_enabled = false`
- `warmup_plan.reason = installed_not_loaded_models_available`
- `warmup_plan.candidates` includes the installed target models
- `warmup_candidates` mirrors the read-only candidates

## Safety

Phase 12R-I is read-only.

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

1. guarded manual warmup dry-run
2. manual warmup command with explicit confirmation
3. `ensure_model_ready(model)`
4. persistent lane activation

Phase 12R-I only plans and reports. It performs no warmup.
