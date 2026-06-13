# Stage 8P Backend Live Router Dry-Run Flag Boundary Plan

Stage 8P records the backend/live feature-flag boundary plan for Universal Intent Router dry-run traffic.

This is a docs/generated-report/smoke-only stage.

## Purpose

Stage 8O added a frontend feature-flag boundary that remains off by default.

Stage 8P records the backend/live dry-run flag boundary and verifies the live system is still not accepting router dry-run traffic.

## Current Boundary

The live controller already has a dry-run enablement boundary:

- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED`

When the flag is not enabled:

- `/api/router/dry-run` returns 404 with a disabled detail
- `/system/router/dry-run` returns 404 with a disabled detail
- `/router/dry-run` returns 404 Not Found

## Current Decision

Do not enable live router dry-run traffic yet.

## Safety Requirements Before Any Future Enablement

Before any browser or live frontend code can call router dry-run:

- frontend feature flag must remain off until a separate go decision
- backend dry-run flag must remain off until a separate go decision
- dispatch must remain disabled
- model calls must remain disabled
- router response must be consumed as `decision_contract` only
- Study command behavior must remain unchanged
- Companion behavior must remain unchanged
- queue must remain clean
- platform must remain online

## Stage 8P Safety

Stage 8P does not:

- edit runtime controller source
- edit frontend runtime source
- restart the live controller
- restart the wrapper UI
- enable `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED`
- add `/api/router/dry-run` to frontend code
- dispatch Study commands
- call models

## Recommended Next Stage

Stage 8Q should be a controlled temporary-controller validation stage only.

Stage 8Q may start a temporary controller on a separate port with the router dry-run env enabled, validate the response contract, and then shut it down.

Stage 8Q should not enable the live controller or the browser frontend.
