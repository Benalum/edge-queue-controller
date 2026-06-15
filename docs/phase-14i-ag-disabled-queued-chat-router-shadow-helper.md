# Phase 14I-AG - Disabled Queued-chat Router Shadow Helper

Status: disabled-by-default helper implemented, not wired to live route

## Purpose

Phase 14I-AG adds the backend env helper and pure queued-chat router shadow helper wrapper planned in Phase 14I-AF.

This phase preserves live behavior.

This phase does not wire the helper into `/api/chat/queued`.

This phase does not change live model selection.

## Starting Checkpoint

- HEAD: 4b31616
- Tag: controller-phase-14i-af-backend-queued-chat-router-shadow-plan-2026-06-15

## Implemented Helpers

Added:

    _phase14iag_queued_chat_router_shadow_enabled()

This reads:

    EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED

Default:

    false

Added:

    _phase14iag_queued_chat_router_shadow_decision(guard_payload)

Default behavior:

- returns disabled metadata
- does not compute a router decision
- does not call a model
- does not enqueue jobs
- does not change live model selection
- does not expose browser-visible router internals

## Enabled Future Behavior

When explicitly enabled in a later phase, the helper can call:

    _stage5p13a_disabled_intent_router_foundation(message, profile)

The returned shadow shape is narrow and safe:

- `primary_intent`
- `confidence`
- `recommended_model_tier`
- `deterministic_actions`
- `escalation_reasons`
- safety markers for no model invocation, no queue write, and no tool call

## Live Behavior Boundary

The helper is not wired into `/api/chat/queued` in this phase.

The Study UI still sends:

    requested_model: "gemma4:e4b"

The backend queued-chat route still passes through `requested_model`.

Router shadow results do not control live model choice.

## Safety Notes

No jobs are created.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified.

No backend route gates are changed.

No global frontend fallback flag is changed.

No model calls are made by this implementation.

No raw queue summary or prompt/context dump is recorded.

## Next Safe Step

Phase 14I-AH should statically validate the disabled helper behavior and then plan the exact route insertion point for a later default-off shadow-read integration.
