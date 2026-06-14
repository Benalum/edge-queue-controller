# Phase 12R-AJ Optional Authenticated Confirm Request Still Disabled Smoke

Phase 12R-AJ adds a reusable no-restart smoke proving that a future-style warmup request is still disabled.

## Purpose

Phase 12R-AI defined the future activation contract.

This phase verifies that even a request shaped like a future activation request does not execute anything today.

The future-style request is:

- model: qwen3:0.6b
- dry_run: false
- confirm: WARMUP_MODEL_NOW

## Expected behavior

Without a bearer token:

- POST /admin/model-warmup must be blocked before the warmup refusal.

With a valid local admin bearer token:

- POST /admin/model-warmup must return HTTP 403.
- The response must remain the disabled warmup refusal.
- The response may echo dry_run: false.
- The response must still say dry_run_only: true.
- The response must still say runtime_action_available: false.
- The future preview must still say would_call: none.
- The future preview must still say execute_now: false.

## Token safety

The smoke must not print bearer token values.

When EDGE_TEST_ADMIN_BEARER_TOKEN is unset, the authenticated check is skipped.

## Safety

This phase must not:

- Restart any service.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.
- Warm any model.
- Unload any model.
- Print bearer token values.
