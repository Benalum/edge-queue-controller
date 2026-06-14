# Phase 12R-AO Disabled Warmup Control-Plane Final Rollup

Phase 12R-AO is the final no-restart rollup for the disabled model warmup control plane.

## Purpose

The 12R warmup-control chain now has:

- Read-only model memory status.
- Read-only warmup planning.
- Disabled manual warmup action blueprint.
- Disabled admin warmup endpoint.
- Admin auth boundary.
- Disabled future warmup execution preview.
- Lightweight public /system/status snapshot.
- Disabled activation guard report.
- Live authenticated admin refusal verification.

This phase provides one reusable final smoke to prove those guarantees still hold.

## Default behavior

This smoke does not restart the controller by default.

It verifies the no-restart safety surface and checks that the guarded live authenticated Phase 12R-AN smoke exists.

The Phase 12R-AN smoke may be run separately when an authenticated admin live restart verification is desired.

## Optional authenticated live check

Set RUN_PHASE12R_AN_LIVE=1 before running this smoke to invoke the Phase 12R-AN live authenticated smoke.

That optional mode may restart only edge-queue-controller and will require an admin bearer token through hidden local input or EDGE_TEST_ADMIN_BEARER_TOKEN.

## Safety

This phase must not, by default:

- Restart the controller.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Print bearer token values.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.
- Warm any model.
- Unload any model.
