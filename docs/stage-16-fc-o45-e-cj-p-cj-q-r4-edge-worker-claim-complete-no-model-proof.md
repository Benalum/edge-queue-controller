# Stage 16 FC-O45-E-CJ-P/CJ-Q-R4 — Edge-Worker Claim/Complete Deterministic No-Model Proof

Date: 2026-06-26

## Summary

CJ-P deployed the CJ-O edge-worker claim wiring to CT203.

CJ-Q-R3 proved the internal claim endpoint returns the deterministic Companion execution payload for exact-answer `companion.chat` jobs.

CJ-Q-R4 completed the already-claimed job through the internal complete endpoint with `backend-deterministic/no-model`.

## CJ-P live backend deploy

Active CT203 backend file:

    /opt/edge-queue-controller/current/edge_controller.py

Before SHA:

    313b4eb9f2cd0577d8fb5fa2c5c93bc1fadcdc4dfa3418b113af7fa9c64cda46

After SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Backup path:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-cj-p-edge-worker-claim-short-circuit-deploy-20260626T041007Z

Only this service was restarted:

    edge-queue-controller.service

The controller remained active on port 7070.

## CJ-Q initial failure and correction

CJ-Q inserted fresh job 576 but failed before claim/complete because the script looked for the wrong worker token variable.

CJ-Q-R2 verified the correct internal token variable is:

    LAPTOP_QUEUE_INTERNAL_TOKEN

The token is sent through:

    X-Laptop-Queue-Token

No secret value was printed.

## CJ-Q-R3 claim proof

CJ-Q-R3 claimed existing queued job 576 through:

    POST /internal/edge-worker/jobs/claim

The claim returned HTTP 200.

The endpoint response used key:

    claimed

not:

    job

The claimed payload included:

    id=576
    status=running
    attempts=1
    job_type=companion.chat
    requested_model=qwen2.5:0.5b

The claim response also included:

    companion_execution.mode=deterministic_exact_answer_short_circuit
    companion_execution.complete_without_model=true
    companion_execution.model=backend-deterministic/no-model
    companion_execution.model_call_allowed=false
    companion_execution.semantic_exact_marker_pass=true
    companion_execution.response_text=FC-O45-E-CJ-Q-INTERNAL-CLAIM-COMPLETE-OK

CJ-Q-R3 stopped before completion because the proof script expected `claim_data["job"]` instead of the actual `claim_data["claimed"]`.

This was a script-shape issue, not a backend claim failure.

## CJ-Q-R4 completion proof

CJ-Q-R4 completed already-running job 576 through:

    POST /internal/edge-worker/jobs/576/complete

The complete endpoint returned HTTP 200.

Preflight before completion:

    id=576
    status=running
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=0

Final verification after completion:

    id=576
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=1
    result_model=backend-deterministic/no-model
    response=FC-O45-E-CJ-Q-INTERNAL-CLAIM-COMPLETE-OK
    error=None

## What this proves

The internal edge-worker API path can now complete exact-answer Companion jobs without calling Ollama:

1. Claim a bounded exact job through `/internal/edge-worker/jobs/claim`.
2. Read the deterministic `companion_execution` payload.
3. Complete through `/internal/edge-worker/jobs/{job_id}/complete`.
4. Store result model `backend-deterministic/no-model`.
5. Preserve exact marker response.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation during runtime proof, no backend deploy during runtime proof, no service mutation during runtime proof, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package/model pull, no PVESO call, no Ollama/model endpoint call, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Add a tiny bounded worker-client proof script or helper that correctly handles the `claimed` response key and completes deterministic exact-answer Companion jobs without a model call. Keep persistent workers disabled.
