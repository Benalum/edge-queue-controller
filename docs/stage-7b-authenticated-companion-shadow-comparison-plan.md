# Stage 7B Authenticated Companion Shadow Comparison Plan

Stage 7B continues the post-foundation router phase.

This stage does not change runtime behavior.

This stage does not wire the router into Companion or Chat.

## Purpose

Stage 7A defined the authenticated Study shadow comparison plan.

Stage 7B defines how a future authenticated test should compare existing Companion and queued Chat behavior against the Companion shadow adapter output before any production wiring happens.

## Foundation requirement

Stage 7B assumes:

- Stage 6Z is complete
- Stage 7A is complete
- router endpoint remains disabled by default
- router dispatch remains disabled
- router model calls remain disabled
- `_stage6v_companion_adapter_shadow` exists
- `_stage6v_companion_adapter_shadow` is not wired into runtime

## Companion and Chat routes under comparison

Future authenticated comparison should inspect:

- `/api/companion/chat`
- `/api/chat/queued`

These routes must remain owned by existing Companion and queued Chat behavior during Stage 7B.

## Future authenticated comparison flow

A future stage should:

1. Authenticate as a normal test user.
2. Send a safe Companion or queued Chat request to the existing route.
3. Send an equivalent payload to `_stage6v_companion_adapter_shadow`.
4. Capture the existing route response class.
5. Capture the shadow router intent.
6. Confirm router dispatch stayed disabled.
7. Confirm router model calls stayed disabled.
8. Confirm no user-visible Companion or Chat regression occurred.

## Safe comparison inputs

Future comparison may use:

- basic chat text
- planning help text
- study organization text
- general non-destructive conversation text

Future comparison must avoid:

- real secrets
- sensitive personal data
- Calendar writes
- Profile mutations
- admin actions
- power actions
- worker/queue control actions

## Do not do during Stage 7B

Stage 7B must not:

- bypass authentication
- store real user secrets
- wire the router into Companion
- wire the router into Chat
- modify Companion handlers
- modify queued Chat handlers
- modify frontend Companion behavior
- modify frontend Chat behavior
- enable router dispatch
- enable router model calls
- enqueue Chat jobs through the router
- write Calendar entries
- mutate Profile preferences

## Stage boundary

Stage 7B is planning and guardrail coverage only.

Stage 7B does not create authenticated automation.

Stage 7B does not create a runtime registry.

Stage 7B does not expose any new HTTP endpoint.

Stage 7B does not enable dispatch.

Stage 7B does not enable model calls.
