# Phase 11K Deterministic Answer Normalizer

Phase 11K improves Companion Study answer checking without using a model.

## Goal

Make simple natural-language number answers match numeric expected answers.

Example:

- Question: `2 + 3`
- Expected answer: `5`
- User answer: `five`
- Desired verdict: `correct`

## Implementation

Runtime file changed:

- `frontend/wrapper-ui/app.js`

The existing Study answer path remains in place:

- `stage5p11jCompareAnswer(userAnswer, correctAnswer)`
- `stage5p11jRouteCompanionStudyAnswer(message)`

Phase 11K adds deterministic number-word parsing before numeric comparison.

Supported examples include:

- `five` = `5`
- `twenty one` = `21`
- `twenty-one` = `21`
- `negative five` = `-5`
- `minus five` = `-5`
- `five point five` = `5.5`

## Non-goals

This phase does not add model fallback.

The router rollout remains parked:

- no backend dry-run env
- no frontend router POST traffic
- no persistent rollout mutation routes
- no rollout mutation routes

## Next phase

A later phase can add a tiny model fallback only for deterministic `uncertain` cases.
