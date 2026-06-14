# Phase 13E Static Study Answer-Evaluation Contract Regression Smoke

Phase 13E adds a static and dynamic regression smoke for the Phase 13D disabled study answer-evaluation foundation.

## Purpose

Phase 13D established the correct grading direction:

- Keep deterministic matching small.
- Handle exact normalized matches locally.
- Handle number-word normalization locally.
- Mark non-exact answers as requiring a future small Study Judge model.
- Do not hardcode lots of semantic phrase rules.

Phase 13E protects that contract before any Study preview endpoint or model judge execution is added.

## Protected behavior

The Phase 13D helper must remain:

- Disabled.
- Pure.
- Not exposed as a FastAPI route.
- Not called by live Study routes.
- Not connected to Companion routes.
- Not allowed to call a model.
- Not allowed to enqueue jobs.
- Not allowed to write to the database.
- Not allowed to change card state.
- Not allowed to call Ollama.
- Not allowed to call /api/generate.
- Not allowed to call /api/chat.

## Regression examples

The smoke protects these behaviors:

- Expected 5 and user five should be correct by number-word normalization.
- Expected 5 and user the answer is five should be correct by number-word normalization.
- Expected blue and user blue should be correct by normalized exact match.
- Expected The sky is blue because of the reflection of the water and user reflection of water causes the sky to be blue should require the future small Study Judge.
- Expected Pants and user Jeans should require the future small Study Judge.
- Expected Blue and user Red should require the future small Study Judge.
- Empty user answer should be handled deterministically without a model judge.

## Card-match versus truth-check

This phase protects card-match mode only.

It does not check whether the stored card answer is factually true.

A future truth-check phase can separately flag bad card content.

## Phase 13F compatibility note

Phase 13E originally protected the Phase 13D helper as uncalled.

After Phase 13F, the only allowed caller is the disabled admin Study-answer preview route:

- POST /admin/study-answer-preview
- function admin_study_answer_preview

No live Study, Companion, Calendar, Profile, worker, queue, or public route may call the helper directly.

## Future phases

Recommended next phases:

1. Phase 13F: disabled Study answer preview endpoint.
2. Phase 13G: guarded dry-run Study review integration.
3. Phase 13H: small Study Judge model call for non-exact answers.
4. Phase 13I: guarded live Study answer grading rollout.
