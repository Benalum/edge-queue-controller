# Stage 7E Authenticated Shadow Comparison Artifact Validator

Stage 7E adds a non-runtime validator for future authenticated shadow comparison artifacts.

This stage does not change runtime behavior.

This stage does not run authenticated comparisons.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7C defined the artifact schema.

Stage 7D defined the secret-handling guardrail.

Stage 7E adds a validator that future stages can use before committing authenticated comparison artifacts.

## Validator location

The validator lives at:

- `ops/validate/validate-authenticated-shadow-comparison-artifact.py`

It is an offline validation utility only.

## Validator responsibilities

The validator checks that future artifacts:

- use schema version `stage-7c-v1`
- use artifact kind `authenticated_shadow_comparison_result`
- use a supported domain
- use an allowed route for that domain
- use the correct shadow helper for that domain
- use a safe expected intent for that domain
- keep dispatch disabled
- keep model calls disabled
- keep runtime wiring unchanged
- do not store real secrets
- do not store raw authenticated response bodies by default
- do not contain secret-like values

## Stage boundary

Stage 7E does not expose a new HTTP endpoint.

Stage 7E does not modify runtime handlers.

Stage 7E does not modify frontend behavior.

Stage 7E does not enable router dispatch.

Stage 7E does not enable router model calls.
