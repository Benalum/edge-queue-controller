# Phase 14I-AJ - Router Shadow Contract Validation and Evidence Plan

Date: 2026-06-15

## Goal

Record and validate the post-Phase 14I-AI queued-chat router shadow contract.

Phase 14I-AI wired `_phase14iag_queued_chat_router_shadow_decision(guard_payload)` into `/api/chat/queued` behind the existing default-off backend flag:

`EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`

Phase 14I-AJ does not add runtime behavior. It documents the contract and records the safe plan for later shadow evidence collection.

## Current Contract

The queued-chat shadow hook must remain:

- default-off
- backend-only
- shadow-only
- non-authoritative
- non-persistent
- not browser-exposed

The hook may inspect `guard_payload` only through the helper.

The hook must not:

- mutate `guard_payload`
- change `requested_model`
- choose the live model
- enqueue additional jobs
- call live model endpoints
- persist shadow output
- expose router internals to browser responses
- weaken authentication
- mutate CT101
- enable router rollout
- enable persistent lane workers
- enable warmup execution

## Required Route Contract

Inside `/api/chat/queued`:

- the shadow helper call exists exactly once
- the helper return value is intentionally discarded
- the call runs after queued-chat auth resolution
- the call runs before real-user queued job creation
- `payload=guard_payload` remains unchanged
- synthetic queued-chat requested model fallback remains unchanged
- browser response shape remains unchanged

## Evidence Collection Plan

A later gated phase may add safe shadow evidence collection.

That later phase must define:

- the exact evidence fields
- privacy redaction rules
- retention rules
- where evidence is stored
- whether evidence is sampled or full
- how to prevent raw prompt/context dumps
- how to prove no secrets, cookies, auth headers, or raw queue summaries are persisted
- how to disable evidence collection by default
- how to smoke-test without live model calls

Allowed future evidence fields should be narrow and non-sensitive, such as:

- shadow enabled/disabled boolean
- deterministic preview route name
- confidence bucket, not raw internals
- fallback reason code
- live model unchanged boolean
- safety booleans confirming no model call and no enqueue

Blocked evidence fields:

- raw prompt
- raw message
- raw context
- raw queue summary
- cookies
- bearer tokens
- auth headers
- secrets
- full router internals
- full user profile
- full job payload
- model output

## Phase 14I-AJ Scope

This phase adds only:

- this documentation
- a static/read-only smoke test validating the contract

This phase does not patch runtime code.

## Validation

Required validation:

- Python compile passes.
- Phase 14I-AI smoke still passes.
- Phase 14I-AJ smoke passes.
- The queued-chat route keeps the shadow hook contract.
- The helper remains default-off.
- No browser exposure markers are present in the queued-chat route.
- No persistence/evidence implementation is added.
- No live model endpoints are called by smoke tests.
