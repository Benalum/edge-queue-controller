# Stage 8G Router Decision Contract Consumer Readiness

Stage 8G proves that downstream code can safely consume the nested router `decision_contract` object.

## Purpose

Stage 8F added `decision_contract` to enabled router dry-run responses.

Stage 8G verifies that a future frontend or wrapper consumer can read only the safe contract fields without depending on legacy router internals.

## Safety

Stage 8G does not:

- enable the live router endpoint
- restart the live controller
- dispatch Study commands
- call models
- change frontend behavior
- change Study behavior
- change Companion behavior

The live router endpoint remains disabled.

## Consumer Fields

A downstream consumer should read only:

- `decision_contract.selected_path`
- `decision_contract.intent_key`
- `decision_contract.legacy_intent_name`
- `decision_contract.confidence`
- `decision_contract.needs_confirmation`
- `decision_contract.dispatch_performed`
- `decision_contract.allowed_to_dispatch`
- `decision_contract.eligible_for_dispatch`
- `decision_contract.model_call_required`
- `decision_contract.dispatch_plan.would_dispatch`

## Safety Rules

A consumer must treat the decision as shadow-only unless all dispatch gates are explicitly safe.

Current expected safe state:

- `dispatch_performed = false`
- `allowed_to_dispatch = false`
- `dispatch_plan.would_dispatch = false`

## Expected Consumer Cases

The smoke verifies:

- `next` from Study → `study_command`
- `skip` from Study → `study_command`
- `show answer` from Study → `study_command`
- `how are you` from Companion → `companion_chat`
- blocked Admin input → `unsupported`

## Generated Fixture

The smoke writes a generated fixture file:

- `docs/generated/stage-8g-router-decision-contract-consumer-fixtures.json`

This file records safe consumer-facing examples only.

## Decision

Stage 8G proves consumer-readiness for the nested decision contract.

Stage 8H can inspect the frontend Study and Companion input surfaces and plan where a shadow read could happen without changing behavior.
