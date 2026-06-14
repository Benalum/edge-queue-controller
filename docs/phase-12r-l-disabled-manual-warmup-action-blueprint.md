# Phase 12R-L Disabled Manual Warmup Action Blueprint

Phase 12R-L adds a disabled manual warmup action blueprint to `model_memory_status`.

## Goal

Before any actual model warmup action exists, the platform should expose the future action contract while keeping execution impossible.

The blueprint answers:

- Is a manual warmup action enabled?
- Which environment variable would be required later?
- Is an admin endpoint available?
- Which future Ollama endpoint would be used?
- Which preflight checks are required?
- Which models currently pass the dry-run checks?

## Status fields

The CT101 worker status should expose:

- `model_memory_status.manual_warmup_action`
- `model_memory_status.manual_warmup_action.mode`
- `model_memory_status.manual_warmup_action.enabled`
- `model_memory_status.manual_warmup_action.runtime_action_available`
- `model_memory_status.manual_warmup_action.action_enabled_env`
- `model_memory_status.manual_warmup_action.admin_endpoint_available`
- `model_memory_status.manual_warmup_action.would_call`
- `model_memory_status.manual_warmup_action.future_command_plan`
- `model_memory_status.manual_warmup_action.preflight_required`
- `model_memory_status.manual_warmup_action.eligible_models`
- `model_memory_status.manual_warmup_action.blocked_models`

## Required future gate

A future warmup action must require:

- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1`
- admin-only action route
- explicit model target
- successful manual warmup dry-run
- model installed
- model not currently loaded
- CT101 memory visible
- projected loaded + warming model estimates under 80% CT101 RAM
- no active/warming model conflict
- no unexpected router rollout

## Safety

Phase 12R-L is disabled by design.

It must not:

- warm models
- unload models
- call Ollama generate/chat endpoints
- call Ollama unload or stop commands
- run prompts
- expose an execution endpoint
- start persistent lane workers
- change CT101 env files
- change Docker containers
- enable router rollout
- mark persistent cutover ready

## Expected current result

The current expected result is:

- `manual_warmup_action.mode = disabled_action_blueprint`
- `manual_warmup_action.enabled = false`
- `manual_warmup_action.runtime_action_available = false`
- `manual_warmup_action.admin_endpoint_available = false`
- `manual_warmup_action.would_call = none`
- `manual_warmup_action.action_enabled_env = EDGE_MODEL_WARMUP_ACTION_ENABLED`
- eligible models include the dry-run-passing lane models

## Future phases

Later phases can add:

1. admin-only warmup endpoint while still default-disabled
2. explicit manual warmup action
3. model reservation tracking
4. `ensure_model_ready(model)`
5. persistent lane activation

Phase 12R-L only exposes the disabled action blueprint. It performs no warmup.
