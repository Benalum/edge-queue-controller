# Phase 14I-AE - Router Dry-run and Preview Surface Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-AE records the read-only inspection of existing router dry-run and preview surfaces.

This phase identifies the safest existing helper for future Study UI companion queued-chat router shadow decisions.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 1d4b54a
- Tag: controller-phase-14i-ad-study-ui-queued-chat-router-integration-plan-2026-06-15

## Key Finding

The safest current reusable helper is:

    _stage5p13a_disabled_intent_router_foundation(message, profile)

This helper is preferred for future queued-chat shadow routing because it is pure and deterministic.

The helper documentation states that it:

- performs no network calls
- does not call a model
- does not enqueue jobs
- does not change runtime behavior
- returns deterministic routing metadata

## Useful Return Fields

The helper returns useful fields for future shadow decisions, including:

- `primary_intent`
- `confidence`
- `scores`
- `deterministic_actions`
- `normalized_features`
- `number_word_matches`
- `tokens_preview`
- `recommended_model_tier`
- `escalation_reasons`
- `allowed_future_intents`
- `safety`

Decision:

- future queued-chat shadow routing should reuse the pure helper directly
- future queued-chat shadow routing should not call HTTP router routes internally
- future queued-chat shadow routing should not call admin preview routes internally

## Router Dry-run Surface Finding

Existing dry-run routes:

- `POST /api/router/dry-run`
- `POST /system/router/dry-run`

The dry-run route function is:

    stage6f_universal_intent_router_dry_run(request)

Observed behavior:

- checks `_stage6f_router_enabled()`
- returns disabled 404 when router dry-run is not enabled
- parses JSON body
- returns `_stage6f_router_response(body)`

Decision:

- dry-run HTTP routes are useful for external validation
- queued-chat internal shadow routing should not depend on HTTP routes
- internal shadow routing should prefer direct pure helper reuse

## Admin Preview Surface Finding

Existing admin preview route:

- `POST /admin/intent-router-preview`

The admin preview function is:

    admin_intent_router_preview(request, payload)

Observed behavior:

- requires admin access
- calls `_stage5p13a_disabled_intent_router_foundation(message, profile)`
- returns `router_preview`
- declares no model invocation
- declares no queue write
- declares no tool call

Decision:

- admin preview proves the helper is already used safely for preview
- queued-chat should not depend on an admin-only route
- queued-chat shadow routing should reuse the pure helper directly

## Safety Analysis

Inspection found no obvious model-call, external HTTP, SQL mutation, or queue mutation markers in the inspected router blocks.

Inspected block categories:

- API router dry-run route
- system router dry-run route
- dry-run route function
- disabled intent-router foundation helper
- admin intent-router preview route
- admin intent-router preview function

Decision:

- helper is safe for a future shadow-read planning phase
- live model choice should remain unchanged until shadow results are documented
- no live router dispatch should be enabled yet

## Implementation Direction For A Later Phase

A future implementation phase should add backend-only queued-chat router shadow metadata.

Recommended approach:

1. Keep live queued-chat model behavior unchanged.
2. In `/api/chat/queued`, compute a router shadow decision using `_stage5p13a_disabled_intent_router_foundation`.
3. Do not use the shadow decision to select the live model yet.
4. Do not expose full router internals to the browser.
5. Record safe internal fields only.
6. Validate static behavior first.
7. Only later consider frontend omission of `requested_model`.
8. Only later consider backend model selection when `requested_model` is omitted.

## Safe Shadow Fields

Potentially safe fields to record internally:

- `primary_intent`
- `confidence`
- `recommended_model_tier`
- `deterministic_actions`
- `escalation_reasons`
- `safety.no_model_invocation`
- `safety.no_queue_write`
- `safety.no_tool_call`

Fields that should not be exposed casually:

- full prompt text
- full normalized prompt
- raw profile data
- hidden prompt/context
- auth/session data
- worker or infrastructure secrets

## Speed Concern Connection

The previous browser test was slow because the current Study UI companion queued-chat path still sends:

    requested_model: "gemma4:e4b"

The helper can eventually help classify simple prompts and recommend a smaller model tier.

However, this phase does not enable that behavior.

## Safety Notes

No code behavior changes are made in this phase.

No jobs are created.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified.

No backend route gates are changed.

No global frontend fallback flag is changed.

No model calls are made by this documentation phase.

No raw queue summary or prompt/context dump is recorded.

## Next Safe Step

Phase 14I-AF should create a disabled-by-default backend queued-chat router shadow plan.

That plan should specify:

- exact insertion point in `/api/chat/queued`
- exact helper call
- safe shadow metadata fields
- default-off environment flag
- no live model selection change
- no browser exposure unless explicitly gated later
