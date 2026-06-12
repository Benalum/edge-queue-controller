# Stage 8D Router Decision Contract Adapter Helper

Stage 8D adds a source-only helper that maps the current Universal Intent Router dry-run result into the Stage 8B decision-maker contract shape.

## Purpose

Stage 8C found that the current router response is safe, but missing direct Stage 8B contract fields:

- `selected_path`
- `legacy_intent_name`
- `needs_confirmation`
- `candidate_routes`
- `dispatch_plan`

Stage 8D adds an adapter helper to produce those fields without changing live behavior.

## Safety

Stage 8D does not:

- enable the live router endpoint
- restart the live controller
- dispatch any command
- call any model
- change frontend behavior
- change Study command behavior
- change Companion behavior

The live endpoints stay disabled:

- `POST /api/router/dry-run`
- `POST /system/router/dry-run`

## Added Helper

Stage 8D adds:

- `_stage8d_selected_path_from_intent(...)`
- `_stage8d_router_decision_contract(router_result)`

The helper accepts the existing router result and returns a contract-shaped decision object.

## Contract Fields Produced

The adapter returns:

- `ok`
- `dry_run`
- `dispatch_performed`
- `model_call_required`
- `selected_path`
- `intent_key`
- `legacy_intent_name`
- `confidence`
- `needs_confirmation`
- `reason`
- `surface`
- `context_domain`
- `language_code`
- `decision_trace`
- `candidate_routes`
- `dispatch_plan`
- `allowed_to_dispatch`
- `eligible_for_dispatch`

## selected_path Mapping

The adapter maps current router fields to Stage 8B paths:

- Study intents → `study_command`
- Companion chat intents → `companion_chat`
- Chat/general intents → `general_chat`
- Calendar intents → `calendar_command`
- Blocked/unsupported inputs → `unsupported`

## Decision

Stage 8D only adds the adapter helper.

Stage 8E should add a source-only or temporary-process smoke that proves:

- `next` maps to `study_command`
- `skip` maps to `study_command`
- `show answer` maps to `study_command`
- companion conversation maps to `companion_chat`
- unsupported/admin blocked input maps safely to `unsupported`
- live router endpoint remains disabled
