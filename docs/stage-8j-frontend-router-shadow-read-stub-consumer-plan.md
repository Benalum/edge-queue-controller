# Stage 8J Frontend Router Shadow-Read Stub Consumer Plan

Stage 8J proves the disabled frontend router shadow-read stub can consume Stage 8G decision contract fixtures.

This stage does not wire the stub into the live frontend.

## Purpose

Stage 8I added:

- `frontend/wrapper-ui/router_shadow_read_stub.js`

Stage 8J verifies that the stub can safely consume decision contract examples generated in Stage 8G and uses the Stage 8H frontend audit report to document the first safe future wiring plan.

## Safety

Stage 8J does not:

- modify `frontend/wrapper-ui/app.js`
- modify `frontend/wrapper-ui/index.html`
- load the stub in the browser
- enable the live router endpoint
- restart the live controller
- dispatch Study commands
- call models
- change Study behavior
- change Companion behavior

The stub remains disabled by default.

## Fixture Inputs

Stage 8J uses:

- `docs/generated/stage-8g-router-decision-contract-consumer-fixtures.json`
- `docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json`

## Required Stub Behavior

The stub must:

- build router payloads with `dry_run = true`
- build router payloads with `allow_dispatch = false`
- build router payloads with `allow_model_call = false`
- extract only safe `decision_contract` consumer fields
- reject unsafe dispatch states
- skip without calling the API while disabled

## First Safe Wiring Plan

The first future wiring should be:

1. Keep `ROUTER_SHADOW_READ_ENABLED = false`.
2. Load or import the helper only after a separate wiring stage.
3. Add shadow-read calls near existing Study command calls.
4. Do not block existing Study behavior.
5. Do not dispatch based on router output.
6. Do not show router output in UI yet.
7. Log or compare only safe consumer fields.

## Decision

Stage 8J proves the stub is ready for a later disabled wiring stage.

Stage 8K may add the stub script tag or import only if it remains disabled and behavior-preserving.
