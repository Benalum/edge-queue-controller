# Stage 8F Router Response Nested Decision Contract

Stage 8F exposes the Stage 8D decision-maker adapter inside the existing router dry-run response under a nested key:

- `decision_contract`

## Purpose

Stage 8D added a source-only adapter helper:

- `_stage8d_router_decision_contract(router_result)`

Stage 8E proved that helper against real HTTP router output from a temporary enabled controller process.

Stage 8F wires the adapter into the existing router response so future enabled dry-run responses can include both:

- the legacy router response fields
- the new Stage 8B decision-maker contract shape

## Safety

Stage 8F does not:

- enable the live router endpoint
- restart the live controller
- dispatch Study commands
- call any model
- change frontend behavior
- change Study behavior
- change Companion behavior

The live router endpoint remains disabled unless explicitly enabled by environment flag.

## Response Shape

The existing router response remains compatible.

A new nested object is added:

- `decision_contract`

The nested `decision_contract` includes:

- `selected_path`
- `legacy_intent_name`
- `intent_key`
- `needs_confirmation`
- `candidate_routes`
- `dispatch_plan`
- `dispatch_performed`
- `allowed_to_dispatch`
- `eligible_for_dispatch`
- `model_call_required`

## Expected Temporary Enabled Results

When tested through a temporary enabled controller process:

- `next` from Study maps to `decision_contract.selected_path = study_command`
- `skip` from Study maps to `decision_contract.selected_path = study_command`
- `show answer` from Study maps to `decision_contract.selected_path = study_command`
- `how are you` from Companion maps to `decision_contract.selected_path = companion_chat`
- blocked Admin input maps to `decision_contract.selected_path = unsupported`

All cases must keep:

- `decision_contract.dispatch_performed = false`
- `decision_contract.allowed_to_dispatch = false`
- `decision_contract.dispatch_plan.would_dispatch = false`

## Decision

Stage 8F exposes the nested decision contract inside the disabled dry-run router response.

Stage 8G can add a no-live-restart temporary HTTP smoke for downstream consumers or begin planning frontend shadow-read behavior.

Production dispatch is still not enabled.
