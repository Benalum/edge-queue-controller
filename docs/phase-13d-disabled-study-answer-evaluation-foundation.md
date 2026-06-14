# Phase 13D Disabled Study Answer-Evaluation Foundation

Phase 13D adds a pure disabled study answer-evaluation foundation.

## Design decision

Do not hardcode lots of similar phrases.

The deterministic layer should stay small and safe:

- exact normalized matches
- number-word normalization
- answer-prefix cleanup
- empty answer handling

Any non-exact answer should be marked as requiring a future small Study Judge model.

## Why

Hardcoding semantic meaning does not scale.

Examples that should go to the Study Judge model:

- Expected: The sky is blue because of the reflection of the water
- User: reflection of water causes the sky to be blue

The wording is different, but the meaning may match the stored card answer.

Another example:

- Expected: Pants
- User: Jeans

Jeans may be correct, partially correct, or incorrect depending on the question.

The model judge should use the question, expected answer, and user answer together.

## Card-match versus truth-check

This helper is card-match only.

It asks:

- Does the user answer match the stored card answer?

It does not ask:

- Is the stored card answer factually true?

A future truth-check phase can separately flag bad card content.

## Future model judge output

The future small Study Judge should return:

- verdict: correct, partially_correct, incorrect, or unsure
- relationship: same_meaning, narrower, broader, related, unrelated, contradiction, or unclear
- confidence: 0.0 to 1.0
- reason: brief explanation

## Safety

This phase must not:

- Wire the helper to live Study routes.
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

## Phase 13F compatibility note

Phase 13D originally protected the helper as uncalled.

After Phase 13F, the only allowed caller is the disabled admin Study-answer preview route:

- POST /admin/study-answer-preview
- function admin_study_answer_preview

No live Study, Companion, Calendar, Profile, worker, queue, or public route may call the helper directly.

## Future phases

Recommended next phases:

1. Phase 13E: static answer-evaluation contract regression smoke.
2. Phase 13F: disabled Study answer preview endpoint.
3. Phase 13G: guarded dry-run Study review integration.
4. Phase 13H: small Study Judge model call for non-exact answers.
