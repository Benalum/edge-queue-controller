# Phase 13I Disabled Study Judge Execution Contract Helper

Phase 13I adds a disabled backend contract helper for the future Study Judge execution path.

## Goal

The Study Companion needs a safe backend path for grading flexible answers.

The intended flow is:

1. Run deterministic checks first.
2. Use a small Study Judge only when deterministic checks are not enough.
3. Escalate to a deeper reasoning judge only when the small judge is unsure.
4. Use the Companion model for tutoring or explanations, not for final grading authority.
5. Keep the backend as the final authority for card state changes.

## Added helper

Function added:

- _stage5p13i_disabled_study_judge_execution_contract

The helper is source-only and disabled. It is not wired to live Study routes, Companion routes, queue dispatch, or model execution.

## Model tiers described

- tier_2_study_light for study_answer_judge
- tier_4_deep_reasoning for study_answer_reasoning_escalation
- tier_3_companion_medium for companion feedback and tutoring

## Future job types described

- study_answer_judge
- study_answer_reasoning_escalation
- companion_chat for explanations after the backend accepts a result

## Disabled safety contract

Phase 13I does not perform execution.

- no model call
- no queue write
- no database write
- no card state change
- no tool call
- no Ollama direct call
- no live Study route integration
- no Companion live flow integration

## Backend authority rule

The Study Judge and reasoning judge are recommendation providers only. The backend accepts or rejects their result and is the only component allowed to mutate card review state.

## Queue rule

When enabled in a future phase, Study Judge work must go through durable queue jobs. Direct browser-to-model and direct route-to-Ollama paths remain disallowed.
