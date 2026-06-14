# Phase 12R-K Guarded Manual Warmup Dry-Run

Phase 12R-K adds read-only manual warmup dry-run reports to `model_memory_status`.

## Goal

Before allowing any manual model warmup action, the platform should be able to answer:

- Is the model installed?
- Is the model already loaded?
- Is CT101 memory visible?
- Is the model allowed by the current lane policy?
- Would the projected loaded + warming memory stay inside the 80% CT101 RAM budget?
- Would eviction be required?
- Would any command be called?

Phase 12R-K answers those questions without warming anything.

## Status fields

The CT101 worker status should expose:

- `model_memory_status.manual_warmup_dry_runs`
- `model_memory_status.manual_warmup_dry_runs["qwen3:0.6b"]`
- `model_memory_status.manual_warmup_dry_runs["qwen3:1.7b"]`
- `model_memory_status.manual_warmup_dry_runs["llama3.2:3b"]`

Each report includes:

- `mode`
- `model`
- `action_enabled`
- `dry_run_passed`
- `installed`
- `currently_loaded`
- `ct101_memory_available`
- `budget_percent`
- `within_budget`
- `eviction_required`
- `allowed_by_lane_policy`
- `would_call`
- `reason`
- `blockers`

## Expected current result

Since the three target models are installed, not currently loaded, and within the 80% memory budget, the dry-run reports should show:

- `mode = read_only`
- `action_enabled = false`
- `dry_run_passed = true`
- `installed = true`
- `currently_loaded = false`
- `ct101_memory_available = true`
- `budget_percent = 80`
- `within_budget = true`
- `eviction_required = false`
- `allowed_by_lane_policy = true`
- `would_call = none`

## Safety

Phase 12R-K is read-only.

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

Later phases can use this dry-run report to support:

1. explicit manual warmup action
2. `ensure_model_ready(model)`
3. model reservation tracking
4. persistent lane activation

Phase 12R-K only reports. It performs no warmup.
