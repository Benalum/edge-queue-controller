# Phase 12R-AI Inspect-Only Warmup Execution Activation Contract

Phase 12R-AI defines the future activation contract for model warmup execution without adding execution code.

## Purpose

The disabled warmup control plane is now stable through Phase 12R-AH.

Before any real model warmup can be added, the activation contract must be explicit, testable, and hard to trigger accidentally.

## Current state

The current system remains disabled:

- POST /admin/model-warmup is admin-auth bounded.
- The endpoint returns HTTP 403.
- The disabled refusal includes a non-executable future preview.
- The future preview says would_call: none.
- The future preview says future_ollama_request.execute_now: false.
- Warmup execution env remains disabled.
- No /api/generate runtime call exists for warmup execution.

## Future activation gates

A future execution phase must not run unless all of these are true:

1. Admin authentication passes.
2. EDGE_MODEL_WARMUP_ACTION_ENABLED=1.
3. A request-level confirmation equals WARMUP_MODEL_NOW.
4. The requested model is allowlisted.
5. The read-only dry-run planner passes.
6. The memory-budget planner passes.
7. The worker/lane state is safe.
8. The route remains separate from router rollout.
9. The route remains separate from persistent lane workers.
10. The route records the action result clearly.

## Future request contract

Future execution, if ever enabled, should require a request body equivalent to:

{
  "model": "qwen3:0.6b",
  "dry_run": false,
  "confirm": "WARMUP_MODEL_NOW"
}

Without that exact confirmation, the endpoint should remain a dry-run or disabled refusal.

## Future execution contract

The only future Ollama warmup call under consideration is:

- Endpoint: /api/generate
- Method: POST
- stream: false
- Prompt: empty or safe warmup-only prompt
- keep_alive: configured future value

No /api/chat warmup path is approved by this phase.

## Safety

This phase must not:

- Patch runtime execution code.
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
