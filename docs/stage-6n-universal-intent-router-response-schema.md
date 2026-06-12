# Stage 6N Universal Intent Router Response Schema

Stage 6N adds a schema-style smoke test for Universal Intent Router dry-run responses.

This stage does not change runtime behavior.

The endpoint remains disabled by default.

## Purpose

The dry-run router response now contains several safety and observability fields.

Stage 6N locks the required response shape so future changes cannot accidentally remove:

- `source_surface_policy`
- `decision_trace`
- `intent.confidence_band`
- `confirmation_policy`
- `model_routing.model_call_required`
- `safety.allowed_to_dispatch`

## Required safety values

Every validated response must prove:

- `ok=true`
- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`
- `eligible_for_dispatch=false`

## Required trace behavior

Every validated response must include:

- `decision_trace[0].step=normalize_input`
- `decision_trace[-1].step=rule_result`

## Stage boundary

Stage 6N only adds schema documentation and smoke coverage.

Stage 6N does not wire the router into any page.

Stage 6N does not enable dispatch.

Stage 6N does not enable model calls.
