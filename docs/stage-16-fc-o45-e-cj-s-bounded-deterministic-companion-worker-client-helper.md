# Stage 16 FC-O45-E-CJ-S — Bounded Deterministic Companion Worker-Client Helper

Date: 2026-06-26

## Scope

Repo ops helper/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No DB write. No schema migration. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No service change. No CT/VM restart.

## Why this exists

CJ-Q-R3 proved the internal claim endpoint works and returns deterministic exact-answer Companion execution payload under the `claimed` key.

CJ-Q-R4 proved the internal complete endpoint can complete the already-claimed job with:

    model=backend-deterministic/no-model
    response=FC-O45-E-CJ-Q-INTERNAL-CLAIM-COMPLETE-OK

CJ-S adds a reusable bounded one-shot worker-client helper that handles this response shape correctly.

## Helper path

    ops/workers/run-deterministic-companion-exact-once.py

## Helper behavior

The helper:

1. Reads `LAPTOP_QUEUE_INTERNAL_TOKEN` from the environment.
2. Sends the token as `X-Laptop-Queue-Token`.
3. Claims exactly one caller-provided job id.
4. Requires the claim response to contain `claimed` or legacy `job`.
5. Requires `companion_execution.mode=deterministic_exact_answer_short_circuit`.
6. Requires `complete_without_model=true`.
7. Requires `model_call_allowed=false`.
8. Requires `semantic_exact_marker_pass=true`.
9. Completes the same job through `/internal/edge-worker/jobs/{job_id}/complete`.
10. Stores result model `backend-deterministic/no-model`.
11. Does not call PVESO, Ollama, or any model endpoint.

## Safety boundary

The helper does not create jobs.

The helper does not enable persistent workers.

The helper does not activate timers or schedulers.

The helper refuses if the claim response does not include deterministic no-model Companion execution.

## Next recommendation

Run one fresh exact-answer Companion job through this helper from CT203 in a bounded one-shot proof, with persistent workers still disabled.
