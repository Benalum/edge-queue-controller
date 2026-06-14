# Phase 12R-J Read-Only Warmup Memory Budget Planner

Phase 12R-J adds a read-only memory budget planner to `model_memory_status`.

## Goal

Before any real model warmup action exists, the platform should know whether warming a candidate model would keep the CT101 model memory plan inside a safe RAM budget.

The initial rule is:

- loaded model estimates + warming model estimates must stay below 80% of CT101 RAM

This protects the server from trying to keep too many models warm at once.

## Status fields

The CT101 worker status should expose:

- `model_memory_status.warmup_memory_budget`
- `model_memory_status.warmup_memory_budget.mode`
- `model_memory_status.warmup_memory_budget.action_enabled`
- `model_memory_status.warmup_memory_budget.budget_percent`
- `model_memory_status.warmup_memory_budget.ct101_mem_total_mb`
- `model_memory_status.warmup_memory_budget.budget_mb`
- `model_memory_status.warmup_memory_budget.loaded_plus_warming_estimated_mb`
- `model_memory_status.warmup_memory_budget.candidates`
- `model_memory_status.warmup_memory_budget.blocked`

## Initial budget rule

The default max budget is 80% of CT101 RAM.

For a CT101 memory total of roughly 31,943 MB, the budget is roughly 25,554 MB.

Current expected state:

- loaded models: none
- warming models: none
- target warmup candidates:
  - `qwen3:0.6b`
  - `qwen3:1.7b`
  - `llama3.2:3b`

Since no models are loaded right now, all three current target candidates should be within the initial 80% planning budget.

## Safety

Phase 12R-J is read-only.

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

Later phases can use this budget planner to support:

1. guarded manual warmup dry-run
2. guarded manual warmup action
3. automatic `ensure_model_ready(model)`
4. memory-aware model eviction
5. persistent lane activation

Phase 12R-J only plans and reports. It performs no warmup.
