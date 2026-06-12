# Stage 6K Universal Intent Router Decision Trace

Stage 6K adds a `decision_trace` field to Universal Intent Router dry-run responses.

This stage preserves router safety.

The endpoint remains disabled by default.

## Purpose

The dry-run router should explain why it classified an input a certain way.

The trace helps debug:

- normalized input text
- source and surface context
- active page context
- study context detection
- companion context detection
- matched deterministic rule
- target intent
- target handler
- target route
- selected model tier
- dispatch block reason

## Safety

The trace is observational only.

The router still never dispatches.

The router still never calls a model.

The router still never mutates state.

The router still returns:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`

## Stage boundary

Stage 6K only adds response observability.

Stage 6K does not wire the router into any page.

Stage 6K does not enable dispatch.

Stage 6K does not enable model calls.
