# Stage 8C Router Response Schema Comparison Audit

Stage 8C compares the current Universal Intent Router dry-run response shape against the Stage 8B decision-maker contract.

This was a no-change audit.

## Safety State

Before and during the audit:

- platform stayed online
- queue stayed clean: queued 0, running 0, failed 0
- CT101 Laptop Queue Worker stayed online
- router live dry-run endpoint stayed disabled
- `/api/router/dry-run` returned 404
- `/system/router/dry-run` returned 404
- `/router/dry-run` returned 404 / not found
- router/controller compile passed
- legacy scheduler timer stayed disabled/inactive
- modern power/remediation timers stayed active
- no fresh controller errors were found

## Current Router Endpoint

The current live router dry-run endpoint is still guarded by:

- `_stage6f_router_enabled()`

Routes:

- `POST /api/router/dry-run`
- `POST /system/router/dry-run`

When disabled, it raises:

- HTTP 404
- `Universal Intent Router dry-run endpoint is disabled.`

## Current Router Response Capabilities

The existing router code already includes many safe dry-run fields:

- `ok`
- `dry_run`
- `dispatch_performed`
- `model_call_required`
- `intent_key`
- `confidence`
- `reason`
- `surface`
- `context_domain`
- `language_code`
- `decision_trace`
- `allowed_to_dispatch`
- `eligible_for_dispatch`
- `sqlite_phrase_lookup`

The existing response also contains nested structures such as:

- `intent`
- `target`
- `model_routing`
- `safety`
- `confirmation_policy`
- `router_lookup`
- `source_surface_policy`

## Stage 8B Contract Gaps

The Stage 8B decision-maker contract expects these fields, but current code does not yet expose them directly:

- `selected_path`
- `legacy_intent_name`
- `needs_confirmation`
- `candidate_routes`
- `dispatch_plan`

## Existing Compatibility Fields

The current code still uses legacy intent names such as:

- `study.next`
- `study.skip`
- `study.hint`
- `study.answer`
- `companion.chat`
- `unknown.general_chat`
- `unknown.unsupported`

The newer canonical SQLite-backed intent keys exist separately, for example:

- `study.card.next`
- `study.card.skip`
- `study.card.answer`

## Router Database State

Router foundation tables exist:

- `intent_definitions`
- `intent_routes`
- `global_phrase_bank`
- `user_phrase_bank`
- `router_logs`
- `router_resolution_steps`

Observed counts:

- `intent_definitions`: 14
- `intent_routes`: 14
- `global_phrase_bank`: 34
- `user_phrase_bank`: 0
- `router_logs`: 0
- `router_resolution_steps`: 0

The router DB includes intent definitions for:

- Study session actions
- Study card actions
- Companion chat
- Chat message
- Calendar event/reminder draft actions
- Unknown unsupported input

## Decision

Stage 8D should add a source-only normalization adapter/helper that maps the existing router result into the Stage 8B decision-maker contract shape.

Stage 8D should not:

- enable live router dispatch
- restart the live controller
- call models
- modify frontend behavior
- change production routing

Recommended Stage 8D target:

- add helper function that produces:
  - `selected_path`
  - `legacy_intent_name`
  - `needs_confirmation`
  - `candidate_routes`
  - `dispatch_plan`
- preserve all current dry-run safety fields
- keep `/api/router/dry-run` disabled live
