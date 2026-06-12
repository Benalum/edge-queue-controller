# Stage 7D Authenticated Test Identity and Secret-Handling Guardrail

Stage 7D defines how future authenticated shadow comparison tests may handle authentication safely.

This stage does not change runtime behavior.

This stage does not run authenticated comparisons.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stages 7A and 7B defined authenticated shadow comparison plans.

Stage 7C defined the result artifact schema.

Stage 7D defines the secret-handling rules required before any future authenticated comparison is attempted.

## Allowed authentication handling

Future tests may use authentication only in ephemeral local ways.

Allowed:

- a manually authenticated local browser session
- a runtime-only shell environment value read by a local test runner
- a safe test identity label such as `normal_test_user`

Not allowed:

- committing cookies
- committing tokens
- committing passwords
- committing SSH keys
- committing infrastructure secrets
- committing raw personal response bodies
- committing raw personal chat, calendar, or profile data

## Artifact recording policy

Future artifacts may record:

- test user label
- route name
- HTTP status code
- response class summary
- state-change summary
- shadow intent
- shadow confidence band
- shadow rule id
- safety booleans

Future artifacts must not record:

- authentication values
- raw secrets
- raw cookies
- raw tokens
- raw passwords
- raw personal content
- raw authenticated response bodies by default

## Required artifact safety values

Future artifacts must keep these values false:

- `test_identity.real_user_secret_stored`
- `current_route_observation.raw_response_stored`
- `safety_observation.secrets_stored`
- `safety_observation.dispatch_enabled`
- `safety_observation.model_calls_enabled`
- `safety_observation.runtime_wiring_changed`

## Future test runner behavior

A future test runner must:

- fail closed if authentication is missing
- fail closed if a secret-like value would be written to an artifact
- summarize route responses instead of storing raw bodies
- never print authentication values
- never write authentication values to generated docs
- never enable router dispatch
- never enable router model calls

## Stage boundary

Stage 7D is guardrail documentation and smoke coverage only.

Stage 7D does not create authenticated automation.

Stage 7D does not create a runtime registry.

Stage 7D does not expose any new HTTP endpoint.

Stage 7D does not enable dispatch.

Stage 7D does not enable model calls.
