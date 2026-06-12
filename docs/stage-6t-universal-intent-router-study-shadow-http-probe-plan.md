# Stage 6T Universal Intent Router Study Shadow HTTP Probe Plan

Stage 6T defines the future authenticated HTTP comparison plan for Study router integration.

This stage does not change runtime behavior.

## Purpose

Stage 6S captured the current Study route baseline before router wiring.

The unauthenticated Study route baseline is:

- `/api/study/intent/parse` returns `401`
- `/api/study/session/command` returns `401`

That is expected because Study routes remain protected by existing authentication behavior.

Stage 6T defines how a future stage should compare authenticated Study behavior against the Study shadow adapter without enabling dispatch.

## Future authenticated comparison flow

A later stage should:

1. Authenticate as a normal app user.
2. Submit an existing Study command to the current Study route.
3. Submit an equivalent payload to the Study shadow adapter helper.
4. Compare current Study behavior against shadow router output.
5. Record intent, confidence, route, rule id, and safety flags.
6. Prove user-visible Study behavior is unchanged.
7. Keep router dispatch disabled.

## Comparison fields

The future comparison should record:

- input text
- current Study route HTTP status
- current Study route response class
- shadow intent
- shadow confidence band
- shadow existing route
- shadow rule id
- source/surface policy result
- model call requirement
- dispatch permission
- dispatch result

## Safety boundary

Stage 6T must not:

- wire the router into Study
- bypass auth
- enable dispatch
- enable model calls
- mutate Study state through the router
- alter frontend Study behavior

## Required current state

The router dry-run endpoint must remain disabled by default.

The Study shadow adapter must remain isolated from runtime wiring.

The existing Study routes must remain auth-protected.
