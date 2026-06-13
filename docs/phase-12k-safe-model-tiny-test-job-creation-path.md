# Phase 12K Safe Model-Tiny Test Job Creation Path

Phase 12K inspected the safest way to create one controlled `model-tiny` test job for the future one-lane activation test.

## Result

The `app_jobs` table supports a direct controlled test job with these important fields:

- `id`
- `user_id`
- `job_type`
- `status`
- `requested_model`
- `assigned_worker_id`
- `payload_json`
- `result_json`
- `error_text`
- `created_at`
- `updated_at`
- `started_at`
- `finished_at`

The safest controlled test job should use:

- `job_type`: `ollama_chat`
- `status`: `queued`
- `requested_model`: `qwen3:0.6b`
- `payload_json.requested_model`: `qwen3:0.6b`
- `payload_json.model_tier`: `tiny`
- `payload_json.model_lane`: `model-tiny`
- `payload_json.queue_lane`: `model-tiny`
- `payload_json.routing_contract_version`: `stage_5p11r_v1`
- `payload_json.synthetic`: true
- `payload_json.mode`: `companion`
- `payload_json.prompt`: short controlled test prompt
- `payload_json.messages`: one user message matching the prompt

## Existing proof

A historical completed job already exists with the desired tiny-lane shape:

- `requested_model`: `qwen3:0.6b`
- `model_tier`: `tiny`
- `model_lane`: `model-tiny`
- `queue_lane`: `model-tiny`

## Current safety state

Inspection confirmed:

- Primary worker is active and unfiltered.
- Tiny lane service is inactive.
- Small lane service is inactive.
- No active queued/running `ollama_chat` jobs existed during inspection.
- Router rollout remains parked.

## Important activation rule

Do not create the controlled `model-tiny` job while the primary unfiltered worker is active.

The controlled activation phase should:

1. Confirm no active queued/running jobs.
2. Stop the primary worker.
3. Start only the tiny lane worker.
4. Verify tiny worker registration.
5. Insert one controlled `model-tiny` job.
6. Wait for completion.
7. Stop tiny lane worker.
8. Restart primary worker.
9. Verify queue empty and primary restored.

## Safety state

This phase is inspection/documentation only.

No worker was stopped.
No lane worker was started.
No test job was inserted.
No queue-lane runtime behavior was changed.
