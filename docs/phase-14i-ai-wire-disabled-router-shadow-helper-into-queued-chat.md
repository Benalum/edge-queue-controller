# Phase 14I-AI - Wire Disabled Router Shadow Helper Into Queued Chat

Date: 2026-06-15

## Goal

Wire `_phase14iag_queued_chat_router_shadow_decision(guard_payload)` into `/api/chat/queued` behind the existing default-off backend flag:

`EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`

## Scope

This phase connects the disabled-by-default router shadow helper to the queued-chat route as a shadow-only hook.

The hook runs after queued-chat auth resolution and before real-user queued job creation.

The returned shadow decision is intentionally discarded.

## Preserved Behavior

Phase 14I-AI must preserve all current live behavior:

- Default behavior remains unchanged.
- Live model selection remains unchanged.
- `requested_model` pass-through remains unchanged.
- Study UI still sends fixed `requested_model: "gemma4:e4b"`.
- Backend direct `/jobs` remains enabled.
- Legacy Study UI fallback is not removed.
- Router model selection is not enabled.
- No shadow output is returned to the browser.
- No shadow output is persisted.
- No model calls are made by smoke tests.

## Safety Boundaries

This phase does not:

- call live model endpoints
- mutate CT101
- archive, delete, or mutate job 23
- expose secrets, cookies, auth headers, raw prompt/context dumps, or raw queue summaries
- gate backend direct `/jobs`
- remove Study UI `requested_model`
- remove legacy fallback
- enable router model selection
- enable persistent lane workers
- enable warmup execution

## Implementation Notes

The helper remains controlled by `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`.

When the flag is unset or false, the helper returns a disabled shadow metadata shape and does not compute a router decision.

When the flag is explicitly enabled later, the helper uses the deterministic disabled router foundation preview and still does not control live model choice.

Phase 14I-AI only wires the hook.

A later gated phase may add safe shadow evidence collection.

## Validation

Validation is static/read-only except for repository file edits in this phase.

Required checks:

- Python compile passes.
- Phase 14I-AI smoke passes.
- The hook exists inside `/api/chat/queued`.
- The hook runs after auth resolution and before real-user job creation.
- The hook return value is discarded.
- `payload=guard_payload` remains unchanged.
- Synthetic requested model behavior remains unchanged.
- No browser response key exposes router shadow output.
- Smoke test does not call live model endpoints.

## Prior Smoke Compatibility Note

Phase 14I-AG and Phase 14I-AH originally asserted that the helper was not wired into `/api/chat/queued`.

After Phase 14I-AI, that historical assertion is intentionally obsolete. Their smoke tests are updated to remain forward-compatible: they now accept either the original pre-AI unwired state or the post-AI shadow-only wiring state, while still verifying that live model selection, browser exposure, payload pass-through, and persistence behavior remain protected.
