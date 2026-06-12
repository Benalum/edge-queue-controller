# Stage 7J Local Authenticated Runner Offline Implementation

Stage 7J creates the local authenticated shadow comparison runner as a manual ops tool.

This stage does not change runtime behavior.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7H planned the future runner.

Stage 7I proved the runner did not exist yet.

Stage 7J creates the runner file, but keeps it manual, offline by default, and not runtime-wired.

## Runner path

The runner lives at:

- `ops/compare/run-authenticated-shadow-comparison.py`

## Default behavior

By default, the runner performs offline shadow comparison artifact generation only.

Default behavior does not:

- authenticate
- call existing HTTP routes
- call the router endpoint
- dispatch router actions
- call models
- mutate Study state
- mutate Companion or Chat state

## Authenticated execution

Authenticated HTTP execution requires an explicit flag.

Existing route calls may change state, so authenticated execution also requires explicit confirmation.

The runner may read one of these runtime-only environment values:

- `EDGE_AUTH_SHADOW_COMPARE_COOKIE`
- `EDGE_AUTH_SHADOW_COMPARE_BEARER`

The runner must never print or store those values.

## Artifact behavior

The runner writes sanitized artifacts only.

Artifacts must not include:

- auth cookies
- bearer tokens
- passwords
- secrets
- raw authenticated route responses
- raw personal response bodies

Artifacts are validated with:

- `ops/validate/validate-authenticated-shadow-comparison-artifact.py`

## Stage boundary

Stage 7J creates an ops tool only.

Stage 7J does not expose a new HTTP endpoint.

Stage 7J does not modify runtime handlers.

Stage 7J does not modify frontend behavior.

Stage 7J does not enable router dispatch.

Stage 7J does not enable router model calls.
