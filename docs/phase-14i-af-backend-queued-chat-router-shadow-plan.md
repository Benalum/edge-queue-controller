# Phase 14I-AF - Backend Queued-chat Router Shadow Plan

Status: disabled-by-default plan recorded, not implemented

## Purpose

Phase 14I-AF defines the safest backend-only shadow plan for Study UI companion queued-chat router decisions.

This phase does not change runtime behavior.

This phase does not enable router model selection.

This phase does not remove the frontend fixed `requested_model`.

## Starting Checkpoint

- HEAD: df2ca48
- Tag: controller-phase-14i-ae-router-dry-run-preview-surface-inspection-2026-06-15

## Confirmed Current Behavior

Study UI companion queued-chat currently sends:

    body: { message: prompt, requested_model: "gemma4:e4b" }

The backend `/api/chat/queued` route accepts and passes through `requested_model`.

The queued-chat route does not currently perform dynamic model routing.

## Safe Existing Helper

Use this pure deterministic helper for future shadow routing:

    _stage5p13a_disabled_intent_router_foundation(message, profile)

Reasons:

- performs no network calls
- does not call a model
- does not enqueue jobs
- does not change runtime behavior
- returns deterministic routing metadata
- already powers the disabled admin intent-router preview surface

## Proposed Environment Flag

Add a future backend flag:

    EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED=0

Default:

    disabled

When disabled:

- no queued-chat router shadow decision is computed
- current live behavior remains unchanged
- `requested_model` continues to pass through as today

When enabled in a later implementation phase:

- `/api/chat/queued` computes a shadow router decision
- shadow decision is not used for live model choice
- live `requested_model` behavior remains unchanged
- shadow fields are recorded internally only
- no model call is made for the router decision

## Proposed Insertion Point

Future insertion point in `/api/chat/queued`:

1. after `guard_payload` is created and sanitized
2. after forbidden client user fields are rejected
3. before `_s5f19_create_real_user_queued_chat_job(...)`
4. before queued job creation writes to `app_jobs`

Reason:

- the message and mode are available
- identity checks are already underway
- shadow result can be included in safe metadata later
- live routing remains unchanged

## Proposed Shadow Input

Use:

- `message`: `guard_payload.get("message")`
- `mode`: `guard_payload.get("mode")`
- `profile`: minimal safe profile hints only, if already available

Do not include:

- auth headers
- session tokens
- cookies
- full hidden prompt/context dumps
- infrastructure secrets
- worker secrets

## Proposed Safe Shadow Output Fields

Safe internal fields:

- `primary_intent`
- `confidence`
- `recommended_model_tier`
- `deterministic_actions`
- `escalation_reasons`
- `safety.no_model_invocation`
- `safety.no_queue_write`
- `safety.no_tool_call`

Do not expose full shadow output to the browser by default.

## Live Model Selection Rule

Router shadow result must not control live model choice yet.

Live model choice remains:

- use existing `requested_model` pass-through behavior
- preserve `gemma4:e4b` behavior from current frontend
- do not override with router tier yet

## Why Shadow First

Shadow first lets us answer:

- whether simple greetings classify correctly
- whether Study review commands classify correctly
- whether companion messages classify correctly
- whether confidence is reliable enough
- whether recommended tiers are reasonable
- whether logging is safe
- whether latency improves only after a later live-selection phase

## Future Implementation Order

1. Add backend env helper for `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`.
2. Add pure shadow helper wrapper for queued-chat.
3. Add static smoke proving default disabled behavior is unchanged.
4. Add static smoke proving enabled shadow computes safe metadata without model calls.
5. Add docs for shadow evidence.
6. Only later add frontend omission flag.
7. Only later add backend router model selection flag.

## Safety Boundaries

Do not enable live router model selection in this phase.

Do not remove frontend `requested_model` in this phase.

Do not gate backend direct `/jobs` in this phase.

Do not remove legacy fallback in this phase.

Do not expose full router internals to the browser.

Do not call live model endpoints in smoke tests.

Do not use admin preview HTTP routes internally.

Do not depend on `/api/router/dry-run` internally.

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

Phase 14I-AG should implement only the disabled-by-default backend env helper and pure queued-chat shadow helper wrapper.

That implementation must preserve default behavior and must not change live model selection.
