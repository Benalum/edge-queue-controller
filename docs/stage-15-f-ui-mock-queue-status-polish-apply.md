# Stage 15-F — UI Mock Queue Status Polish Apply

Date: 2026-06-19  
Base checkpoint: Stage 15-E / HEAD 8be673e  
Approval: APPROVE_STAGE_15_F_UI_MOCK_QUEUE_STATUS_POLISH_APPLY_NO_BACKEND_NO_DB_NO_MODEL_NO_WORKER_NO_SCHEDULER

## Scope

Frontend-only polish for mock/no-model queued Companion jobs.

This phase changes only static frontend app.js behavior so deliberately queued mock/no-model jobs do not appear as timeout failures while model workers remain inactive.

## Behavior changed

When /api/chat/queued/{job_id} returns a mock queued job with:

- status queued, pending, waiting, or created
- requested_model mock/no-model, or model_call not_started

the Companion UI now displays:

Your message is queued safely. The model worker is not active yet, so no assistant reply has been generated.

The queue summary also displays Queued for queued/pending/waiting/created job states.

The queue display now understands the Stage 15-D top-level response shape where job_id, status, requested_model, and model_call are top-level fields.

## Safety boundaries preserved

No backend mutation.

No database write.

No service restart or reload.

No CT or VM restart.

No nginx or cloudflared mutation.

No Cloudflare, DNS, or tunnel mutation.

No worker activation.

No scheduler activation.

No Ollama endpoint call.

No live model endpoint call.

No /tick/ollama-direct call.

No CT204 start.

No private storage unlock or mount.

No PVESO mutation.

## Result

The Companion UI now accurately represents the current Stage 15 state:

- authenticated queued chat contract works;
- durable mock companion.chat jobs are created;
- model workers are intentionally not active yet;
- the UI no longer treats that intentional mock/no-model state as a failure.
