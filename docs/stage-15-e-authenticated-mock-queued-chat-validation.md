# Stage 15-E — Authenticated Mock Queued Chat Validation

Date: 2026-06-19  
Base checkpoint: Stage 15-D / HEAD `9156666`  
Approval: `APPROVE_STAGE_15_E_AUTHENTICATED_MOCK_QUEUED_CHAT_VALIDATION_DB_WRITE_ONE_JOB_NO_MODEL_NO_WORKER_NO_SCHEDULER`

## Scope

This phase validated authenticated mock queued chat compatibility.

Validated routes:

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}
- GET /api/chat/queue/status?job_id={job_id}

## Validation result

The authenticated validation succeeded before the original evidence-smoke failure.

Observed validation results:

- Temporary validation bearer session was created.
- Temporary validation session id was recorded in terminal output as 261.
- The temporary validation session was revoked after validation.
- Authenticated POST /api/chat/queued returned HTTP 200.
- Created mock queued job id: 24.
- Created job status: queued.
- Created job type: companion.chat.
- Created job requested model: mock/no-model.
- Created job model call state: not_started.
- Authenticated GET /api/chat/queued/{job_id} returned HTTP 200.
- Authenticated GET /api/chat/queue/status?job_id={job_id} returned HTTP 200.
- Both polling endpoints returned result null and error null.

## Bounded DB changes observed

Before validation:

- app_users: 47
- user_sessions: 234
- jobs: 22
- job_results: 6
- router_logs: 0
- router_resolution_steps: 0
- router_feedback: 0
- workers: 2
- worker_events: 3

After validation:

- app_users: 47
- user_sessions: 235
- jobs: 23
- job_results: 6
- router_logs: 0
- router_resolution_steps: 0
- router_feedback: 0
- workers: 2
- worker_events: 3

Expected bounded changes were met:

- user_sessions plus one temporary validation session.
- jobs plus one mock companion.chat job.
- job_results unchanged.
- router_logs unchanged.
- router_resolution_steps unchanged.
- router_feedback unchanged.
- workers unchanged.
- worker_events unchanged.

## Safety boundaries preserved

No model call occurred.

No Ollama endpoint call occurred.

No /tick/ollama-direct call occurred.

No worker activation occurred.

No scheduler activation occurred.

No DB schema migration occurred.

No service restart or reload occurred during Stage 15-E validation.

No CT or VM restart occurred.

No nginx or cloudflared mutation occurred.

No Cloudflare, DNS, or tunnel mutation occurred.

No CT204 start occurred.

No private storage unlock or mount occurred.

No PVESO mutation occurred.

## What this proves

Authenticated browser-compatible queued chat backend contract is now validated with mock/no-model execution.

This proves:

1. the public route path accepts authenticated queued chat creation;
2. the backend writes a durable mock companion.chat job;
3. the direct queued job poll endpoint returns the job;
4. the compatibility queue status endpoint returns the job;
5. no model call occurs;
6. no worker or scheduler activation occurs.

## Note on recovery

The first Stage 15-E run failed before DB writes because it used system python and the controller dependency `httpx` was only available in the CT203 service venv.

The second Stage 15-E run succeeded using `/opt/edge-queue-controller/venv/bin/python`. The validation itself passed, but the evidence smoke failed because shell command substitution interpreted backtick characters inside a smoke assertion string.

This recovery records the already-completed validation evidence and intentionally performs no additional DB writes.

## Next recommended phase

Stage 15-F should decide whether to:

1. wire the Companion UI to display queued mock status clearly; or
2. move to a default-off scheduler/worker/model re-entry plan for one controlled local model call.

Model/Ollama/worker/scheduler activation still requires a separate explicit approval.
