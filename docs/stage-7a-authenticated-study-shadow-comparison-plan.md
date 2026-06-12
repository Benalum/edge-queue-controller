# Stage 7A Authenticated Study Shadow Comparison Plan

Stage 7A starts the post-foundation router phase.

This stage does not change runtime behavior.

This stage does not wire the router into Study.

## Purpose

Stage 6Z completed the Universal Intent Router foundation.

Stage 7A defines how a future authenticated test should compare existing Study route behavior against the Study shadow adapter output before any production wiring happens.

## Foundation requirement

Stage 7A assumes:

- Stage 6Z is complete
- router endpoint remains disabled by default
- router dispatch remains disabled
- router model calls remain disabled
- `_stage6q_study_adapter_shadow` exists
- `_stage6q_study_adapter_shadow` is not wired into runtime

## Study routes under comparison

Future authenticated comparison should inspect:

- `/api/study/intent/parse`
- `/api/study/session/command`

These routes must remain owned by existing Study behavior during Stage 7A.

## Future authenticated comparison flow

A future stage should:

1. Authenticate as a normal test user.
2. Send a safe Study request to the existing Study route.
3. Send an equivalent payload to `_stage6q_study_adapter_shadow`.
4. Capture the Study route response class.
5. Capture the shadow router intent.
6. Confirm router dispatch stayed disabled.
7. Confirm router model calls stayed disabled.
8. Confirm no user-visible Study regression occurred.

## Safe comparison inputs

Future comparison may use:

- `next`
- `skip`
- `show hint`
- simple answer text

Future comparison must avoid destructive or irreversible Study actions.

## Do not do during Stage 7A

Stage 7A must not:

- bypass authentication
- store real user secrets
- wire the router into Study
- modify Study handlers
- modify frontend Study behavior
- enable router dispatch
- enable router model calls
- mutate Study state through the router

## Stage boundary

Stage 7A is planning and guardrail coverage only.

Stage 7A does not create authenticated automation.

Stage 7A does not create a runtime registry.

Stage 7A does not expose any new HTTP endpoint.

Stage 7A does not enable dispatch.

Stage 7A does not enable model calls.
