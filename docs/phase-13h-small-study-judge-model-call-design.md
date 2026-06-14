# Phase 13H Small Study Judge Model-Call Design

Phase 13H defines the design contract for a future small Study Judge model call.

This phase is design-only.

It does not add model execution, queue submission, worker changes, Study integration, or live grading behavior.

## Why this exists

Phase 13D intentionally stopped hardcoding semantic grading rules.

The system should handle simple deterministic matches locally, then send non-exact answers to a small Study Judge model.

Examples that should go to the small Study Judge:

- Expected: The sky is blue because of the reflection of the water
- User: reflection of water causes the sky to be blue

- Expected: Pants
- User: Jeans

- Expected: Blue
- User: Red

The Study Judge decides whether the user's answer matches the stored card answer for the current question.

## Scope

The Study Judge is for card-match grading.

It should answer:

- Does the user answer mean the same thing as the expected stored answer?
- Is the user answer narrower than the expected answer?
- Is the user answer broader than the expected answer?
- Is the user answer related but incomplete?
- Is the user answer incorrect?
- Is the answer too ambiguous and should be marked unsure?

It should not answer:

- Should the stored card be rewritten?
- Should the database be updated?
- Should the card state change?
- Should a Study review be marked correct live?
- Is the stored card globally factually true?

A separate future truth-check phase can handle bad card content.

## Future model tier

Recommended model tier:

- tier_2_study_light

Candidate local models:

- qwen3:1.7b
- gemma3:4b
- llama3.2:3b

The router should prefer a fast small model first. Larger models should only be used later if confidence is low or the answer requires deeper reasoning.

## Future input schema

The future Study Judge model call should receive:

- question
- expected_answer
- user_answer
- preferred_language
- study_language
- grading_mode
- allowed_verdicts
- allowed_relationships

The grading_mode should be:

- card_match_not_truth_check

## Future output schema

The future Study Judge must return strict JSON:

- verdict: correct, partially_correct, incorrect, or unsure
- relationship: same_meaning, narrower, broader, related, unrelated, contradiction, or unclear
- confidence: number from 0.0 to 1.0
- reason: brief explanation
- model_tier: tier_2_study_light
- model_used: model identifier
- execution_mode: disabled_preview, dry_run, or live_after_guarded_rollout

## Guardrails

The Study Judge prompt must say:

- Grade against the stored card answer first.
- Do not require exact wording.
- Accept paraphrases with the same meaning.
- Treat narrower or broader answers according to the question.
- Return unsure when uncertain.
- Do not rewrite or mutate the stored card.
- Do not claim a database write happened.
- Do not claim a card state change happened.
- Return strict JSON only.

## Execution lifecycle

Recommended staged rollout:

1. Disabled design contract only.
2. Disabled execution skeleton that still does not call a model.
3. Admin-only dry-run preview that can call a small model.
4. Study dry-run integration that does not mark cards.
5. Guarded live grading rollout for exact + model-judge approved answers.
6. Human review fallback for unsure cases.

## Safety

This phase must not:

- Change edge_controller.py.
- Restart the controller.
- Restart CT101.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Wire model judging to live Study review.
- Call any model.
- Enqueue any job.
- Write to the database.
- Change card state.
- Enable warmup execution.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.
- Print bearer tokens.

## Current live route state

The live disabled preview route remains:

- POST /admin/study-answer-preview

It is admin-gated. Unauthenticated requests must return 401.

The route should continue to return disabled metadata only.
