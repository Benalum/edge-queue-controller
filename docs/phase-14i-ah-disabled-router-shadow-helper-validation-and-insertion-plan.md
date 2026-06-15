# Phase 14I-AH - Disabled Router Shadow Helper Validation and Insertion Plan

Status: validation and insertion plan recorded, not wired

## Purpose

Phase 14I-AH validates the disabled queued-chat router shadow helper from Phase 14I-AG and records the exact future insertion plan for `/api/chat/queued`.

This phase does not change runtime behavior.

This phase does not wire the helper into `/api/chat/queued`.

This phase does not change live model selection.

## Starting Checkpoint

- HEAD: 2d79fba
- Tag: controller-phase-14i-ag-disabled-queued-chat-router-shadow-helper-2026-06-15

## Confirmed Helper State

Phase 14I-AG added:

    _phase14iag_queued_chat_router_shadow_enabled()

and:

    _phase14iag_queued_chat_router_shadow_decision(guard_payload)

The helper is disabled by default through:

    EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED

Default:

    false

## Confirmed Route State

The helper is not currently wired into:

    POST /api/chat/queued

The queued-chat route still passes through:

    requested_model=guard_payload.get("requested_model") or guard_payload.get("model")

The Study UI still sends:

    requested_model: "gemma4:e4b"

Decision:

- live behavior remains unchanged
- router shadow helper exists but is not active in queued-chat
- model choice remains fixed/pass-through

## Proposed Future Insertion Point

Future wiring should be inserted in `/api/chat/queued` after:

    _s5f17_reject_client_provided_user_id(guard_payload)

and before:

    _s5f19_create_real_user_queued_chat_job(...)

Reason:

- `guard_payload` exists
- forbidden client-provided identity fields have already been rejected
- the request message is available
- the queued job has not yet been created
- the shadow result can be computed without altering live behavior

## Proposed Future Local Variable

Use a local variable such as:

    router_shadow = _phase14iag_queued_chat_router_shadow_decision(guard_payload)

Only when the default-off flag is enabled in a later phase.

Do not use this variable to select the live model yet.

Do not expose the full variable to the browser.

## Proposed Future Persistence Boundary

Do not write router shadow metadata into persistent job storage until a separate phase proves the field shape is safe.

Preferred sequence:

1. compute local shadow result with default-off flag
2. validate default disabled route behavior is unchanged
3. validate enabled shadow path statically
4. later decide whether safe metadata belongs in `payload_json`
5. later decide whether any safe metadata can be exposed to admin-only diagnostics

## Safety Boundaries

Do not enable router shadow by default.

Do not use router shadow to select the live model.

Do not remove frontend `requested_model`.

Do not gate backend direct `/jobs`.

Do not remove legacy fallback.

Do not call model endpoints in smoke tests.

Do not expose full prompt, hidden prompt/context, auth/session data, or infrastructure details.

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

Phase 14I-AI should wire the helper into `/api/chat/queued` behind the existing default-off backend flag.

The next implementation must prove:

- default disabled behavior remains unchanged
- live model selection remains unchanged
- no model calls are made by the shadow helper
- no browser exposure is added
- no persistent writes are added beyond existing queued job creation
