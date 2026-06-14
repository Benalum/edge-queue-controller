# Phase 13K Disabled Study Answer Reasoning Escalation Contract

Phase 13K adds a disabled backend contract for the future Study answer reasoning escalation path.

## Goal

When the small Study Judge is unsure, low confidence, unclear, or invalid, the backend may later escalate the answer comparison to a deeper reasoning judge.

This phase does not enable queue writes, worker dispatch, model calls, database writes, or card state changes.

## Added helper

- _stage5p13k_disabled_study_answer_reasoning_escalation_contract

The helper is source-only, disabled, and unwired.

## Future escalation job contract

- job_type: study_answer_reasoning_escalation
- model_tier: tier_4_deep_reasoning
- priority: interactive_study_escalation
- timeout_seconds: 45
- durable_queue_required: true

## Escalation triggers

- small_judge_verdict_is_unsure
- small_judge_confidence_below_0_70
- small_judge_relationship_is_unclear
- small_judge_output_invalid
- user_requests_explanation_after_unclear_grade

## Required payload when enabled

- question
- expected_answer
- user_answer
- small_judge_result

Optional payload fields include card_id, session_id, user_id, profile_context, and prior_deterministic_evaluation.

## Result contract

The reasoning result must include final_verdict, relationship, confidence, reason, and student_feedback.

Allowed final verdicts are correct, partially_correct, incorrect, and unsure.

Allowed relationships are same_meaning, narrower, broader, related, unrelated, contradiction, and unclear.

## Backend authority

The reasoning judge may recommend a grade and feedback, but the backend must accept or reject it. Workers are not allowed to mutate card state.

The escalation contract prefers unsure over an overconfident grade.

## Current scheduler boundary

The current worker capability router treats unknown job types as required_capability equals job_type.

Therefore study_answer_reasoning_escalation must remain disabled until a worker capability mapping is added intentionally.

## Activation gates

- requires_small_judge_result_validation
- requires_worker_capability_update
- requires_queue_enqueue_endpoint
- requires_reasoning_result_schema_validation
- requires_backend_acceptance_policy
- requires_card_state_write_guard
- requires_live_smoke_before_enable

## Disabled safety contract

- no model call
- no queue write
- no worker dispatch
- no database write
- no card state change
- no tool call
- no Ollama direct call
- no live Study route integration
- no Companion live flow integration
