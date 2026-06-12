# Stage 7H Authenticated Shadow Comparison Runner Plan

Stage 7H defines the future local-only authenticated comparison runner contract.

This stage does not create the runner.

This stage does not change runtime behavior.

This stage does not run authenticated comparisons.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7C created the artifact schema.

Stage 7D created the secret-handling guardrail.

Stage 7E created the offline artifact validator.

Stage 7F proved the validator is not runtime-wired.

Stage 7G created safe dry-run example artifacts.

Stage 7H defines how a future runner may perform real authenticated comparisons without storing secrets.

## Future runner path

A future stage may create:

- `ops/compare/run-authenticated-shadow-comparison.py`

Stage 7H does not create that file.

## Future environment variables

Required non-secret values:

- `EDGE_AUTH_SHADOW_COMPARE_BASE_URL`
- `EDGE_AUTH_SHADOW_COMPARE_DOMAIN`

One authentication value is required at runtime:

- `EDGE_AUTH_SHADOW_COMPARE_COOKIE`
- `EDGE_AUTH_SHADOW_COMPARE_BEARER`

Optional non-secret values:

- `EDGE_AUTH_SHADOW_COMPARE_OUTPUT`
- `EDGE_AUTH_SHADOW_COMPARE_LABEL`

## Secret handling

The future runner must never:

- print cookie values
- print bearer tokens
- write cookie values to disk
- write bearer tokens to disk
- store auth values in artifacts
- commit auth values
- store raw authenticated route responses by default

## Fail-closed behavior

The future runner must fail closed if:

- base URL is missing
- domain is missing
- domain is unsupported
- no authentication value is provided
- a generated artifact contains a secret-like value
- the artifact fails the Stage 7E validator
- shadow output indicates dispatch or model calls were enabled

## Sanitized artifact output

The future runner may write only sanitized artifacts that match the Stage 7C schema.

Artifacts must keep these values false:

- `test_identity.real_user_secret_stored`
- `current_route_observation.raw_response_stored`
- `safety_observation.secrets_stored`
- `safety_observation.dispatch_enabled`
- `safety_observation.model_calls_enabled`
- `safety_observation.runtime_wiring_changed`

## Stage boundary

Stage 7H is planning and guardrail coverage only.

Stage 7H does not create authenticated automation.

Stage 7H does not expose a new HTTP endpoint.

Stage 7H does not modify runtime handlers.

Stage 7H does not modify frontend behavior.

Stage 7H does not enable router dispatch.

Stage 7H does not enable router model calls.
