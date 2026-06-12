# Stage 7C Authenticated Shadow Comparison Artifact Schema

Stage 7C defines the artifact schema for future authenticated shadow comparison results.

This stage does not change runtime behavior.

This stage does not run authenticated comparisons.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stages 7A and 7B defined the authenticated comparison plans for Study and Companion.

Stage 7C defines the JSON artifact shape that future comparison stages will use to record results consistently.

## Supported domains

The schema supports:

- `study`
- `companion`

## Required artifact sections

Every future authenticated shadow comparison result should include:

- schema metadata
- domain
- comparison mode
- test identity summary
- current route observation
- shadow router observation
- safety observation
- comparison result
- notes

## Secret handling

Artifacts must never store:

- real user passwords
- session cookies
- bearer tokens
- Cloudflare tokens
- Tailscale keys
- infrastructure secrets
- personal raw chat content that is not needed for the comparison

A future test runner may use an authenticated session, but the artifact may only record a safe label such as `normal_test_user`.

## Required safety values

Future artifacts must prove:

- `router_endpoint_disabled_by_default=true`
- `router_disabled_http_code=404`
- `secrets_stored=false`
- `dispatch_enabled=false`
- `model_calls_enabled=false`
- `runtime_wiring_changed=false`

## Shadow observation requirements

Future shadow observations must record:

- helper name
- intent
- confidence band
- existing route
- rule id
- source/surface policy result
- model call requirement
- dispatch permission
- dispatch result
- behavior changed flag

For safe shadow comparison, these must remain false:

- `model_call_required`
- `allowed_to_dispatch`
- `dispatch_performed`
- `behavior_changed`

## Stage boundary

Stage 7C is schema and documentation only.

Stage 7C does not create authenticated automation.

Stage 7C does not create a runtime registry.

Stage 7C does not expose any new HTTP endpoint.

Stage 7C does not enable dispatch.

Stage 7C does not enable model calls.
