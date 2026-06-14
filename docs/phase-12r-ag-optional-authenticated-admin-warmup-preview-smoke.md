# Phase 12R-AG Optional Authenticated Admin Warmup Preview Smoke

Phase 12R-AG adds a reusable no-restart live smoke for the authenticated admin disabled warmup refusal preview.

## Purpose

Phase 12R-AE added `future_warmup_execution_preview` to the disabled admin warmup refusal.

Phase 12R-AF restarted the controller and verified the live authenticated admin path manually.

This phase creates a reusable smoke that:

- Always verifies the unauthenticated path remains auth-blocked.
- Optionally verifies the authenticated admin preview path when `EDGE_TEST_ADMIN_BEARER_TOKEN` is set.
- Skips the authenticated portion safely when no token is set.

## Token safety

The smoke must not print bearer token values.

When `EDGE_TEST_ADMIN_BEARER_TOKEN` is unset, the authenticated check is skipped.

When `EDGE_TEST_ADMIN_BEARER_TOKEN` is set locally, the smoke verifies the live authenticated admin response includes a non-executable future preview.

## Safety

This phase must not:

- Restart any service.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Call Ollama directly.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm any model.
- Unload any model.
- Print bearer token values.
