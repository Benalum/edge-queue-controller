# Stage 6L Universal Intent Router Confidence and Confirmation Policy

Stage 6L adds confidence-band and confirmation-policy metadata to Universal Intent Router dry-run responses.

The endpoint remains disabled by default.

## Purpose

Before the router can ever dispatch, every decision needs clear confidence and confirmation metadata.

Stage 6L adds:

- `intent.confidence_band`
- `decision_trace[].confidence`
- `decision_trace[].confidence_band`
- `confirmation_policy`

## Confidence bands

- `high`: confidence greater than or equal to 0.90
- `medium`: confidence greater than or equal to 0.70
- `low`: confidence greater than 0
- `none`: confidence equal to 0

## Confirmation policy

The current dry-run router never dispatches, so confirmation is never actively required.

The policy still records whether an intent would require confirmation if dispatch were enabled later.

Examples that should require confirmation in future dispatch mode:

- calendar write requests
- profile preference updates
- admin actions

## Safety

The router still never dispatches.

The router still never calls a model.

The router still never mutates state.

The router still returns:

- `dry_run=true`
- `dispatch_performed=false`
- `model_call_required=false`
- `allowed_to_dispatch=false`
- `eligible_for_dispatch=false`

## Stage boundary

Stage 6L only adds response metadata.

Stage 6L does not wire the router into any page.

Stage 6L does not enable dispatch.

Stage 6L does not enable model calls.
