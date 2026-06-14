# Phase 13J Disabled Study Answer Judge Queue Contract

Phase 13J adds a disabled backend contract for the future study_answer_judge queue job.

## Goal

The Study Companion needs a durable queued job for flexible answer grading, but this phase does not enable queue writes, worker dispatch, model calls, or card state changes.

## Added helper

- _stage5p13j_disabled_study_answer_judge_queue_contract

The helper is source-only, disabled, and unwired.

## Future job contract

- job_type: study_answer_judge
- model_tier: tier_2_study_light
- priority: interactive_study_answer_judge
- timeout_seconds: 20
- durable_queue_required: true

## Required payload when enabled

- card_id
- session_id
- user_id
- expected_answer
- user_answer

Optional payload fields include question, profile_context, and prior_deterministic_evaluation.

## Result contract

The worker result must include verdict, relationship, confidence, and reason.

Allowed verdicts are correct, partially_correct, incorrect, and unsure.

Allowed relationships are same_meaning, narrower, broader, related, unrelated, contradiction, and unclear.

## Backend authority

The worker may recommend a grade, but the backend must accept or reject it. Workers are not allowed to mutate card state.

## Current scheduler boundary

The current worker capability router has explicit handling for ollama_chat, companion_chat, tts, stt, comfy_image, and comfy_video.

Unknown job types currently map to required_capability equals job_type. Therefore study_answer_judge must remain disabled until a worker capability mapping is added intentionally.

## Activation gates

- requires_worker_capability_update
- requires_queue_enqueue_endpoint
- requires_worker_result_schema_validation
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
