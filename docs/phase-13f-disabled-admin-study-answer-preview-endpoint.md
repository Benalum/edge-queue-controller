# Phase 13F Disabled Admin Study-Answer Preview Endpoint

Phase 13F adds a disabled admin preview endpoint for the Phase 13D Study answer-evaluation helper.

## Purpose

The Study system needs a safe way to preview answer evaluation over HTTP before connecting the evaluator to live Study review routes.

This phase adds:

- POST /admin/study-answer-preview
- admin_study_answer_preview

The endpoint is admin-gated and non-executing.

## Behavior

The endpoint returns:

- normalized deterministic answer-evaluation metadata
- whether the answer can be handled deterministically
- whether a future small Study Judge model is needed
- the future model judge prompt contract
- safety flags

## Current grading behavior

This endpoint does not call a model.

It uses Phase 13D behavior:

- exact normalized matches can be marked correct
- number-word matches can be marked correct
- empty user answers can be handled deterministically
- non-exact answers are marked as requiring a future small Study Judge

Examples requiring the future small Study Judge:

- sky explanation paraphrases
- Pants versus Jeans
- Blue versus Red until the model judge phase exists

## Safety

This phase does not restart the controller.

The new endpoint will not be live until the controller is reloaded in a later guarded phase.

This phase must not:

- Wire the endpoint to live Study review.
- Restart the controller.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Call any model.
- Enqueue any job.
- Write to the database.
- Change card state.
- Enable warmup execution.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.

## Relationship to Phase 13E

Phase 13E originally protected the Phase 13D helper as uncalled.

Phase 13F updates that contract so the only allowed helper caller is:

- admin_study_answer_preview

No live user-facing route may call the helper yet.

## Future phases

Recommended next phases:

1. Phase 13G: guarded live disabled route verification after controller restart.
2. Phase 13H: small Study Judge model call design.
3. Phase 13I: disabled small Study Judge execution skeleton.
4. Phase 13J: guarded dry-run Study review integration.
