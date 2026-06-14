# Phase 13G Guarded Live Disabled Study-Answer Preview Verification

Phase 13G performs a guarded live verification of the disabled admin Study-answer preview route added in Phase 13F.

## Purpose

Phase 13F added the route in code:

- POST /admin/study-answer-preview

Phase 13G restarts only the edge controller so the route exists in the running process, then verifies the live route remains protected and non-executing.

## What this phase verifies

The smoke verifies:

- edge_controller.py compiles.
- Phase 13F static/dynamic smoke still passes.
- Warmup execution remains disabled before restart.
- Only edge-queue-controller is restarted.
- Health returns after restart.
- Unauthenticated POST /admin/study-answer-preview returns 401.
- Optional authenticated admin preview can be tested with EDGE_ADMIN_BEARER_TOKEN.
- Warmup execution remains disabled after restart.

## Optional authenticated admin test

If EDGE_ADMIN_BEARER_TOKEN is set locally, the smoke will use it without printing the token.

It will verify that the live admin route returns disabled answer-evaluation metadata:

- exact/number answer example does not need model judge
- semantic example still requires future small Study Judge
- no model call is made
- no job is enqueued
- no database write occurs
- no card state change occurs

If EDGE_ADMIN_BEARER_TOKEN is not set, the authenticated admin preview is skipped.

Do not paste bearer tokens into ChatGPT.

## Safety

This phase may restart only:

- edge-queue-controller

This phase must not:

- Restart CT101.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Wire the endpoint to live Study review.
- Call any model.
- Enqueue any job.
- Write to the database.
- Change card state.
- Enable warmup execution.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.
- Print bearer tokens.

## Future phases

Recommended next phases:

1. Phase 13H: small Study Judge model call design.
2. Phase 13I: disabled small Study Judge execution skeleton.
3. Phase 13J: guarded dry-run Study review integration.
4. Phase 13K: guarded live Study answer grading rollout.
