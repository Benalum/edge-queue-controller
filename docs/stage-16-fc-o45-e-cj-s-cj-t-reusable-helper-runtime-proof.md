# Stage 16 FC-O45-E-CJ-S/CJ-T — Reusable Helper Runtime Proof

Date: 2026-06-26

## Summary

CJ-S-R2 added the reusable bounded deterministic Companion worker-client helper.

CJ-T proved that helper live against CT203 using one fresh exact-answer Companion job.

## Helper

Path:

    ops/workers/run-deterministic-companion-exact-once.py

Helper SHA used in CJ-T:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

The helper:

    - reads LAPTOP_QUEUE_INTERNAL_TOKEN from the environment,
    - sends it as X-Laptop-Queue-Token,
    - claims exactly one caller-provided job id,
    - handles the claim response key claimed,
    - requires companion_execution.mode=deterministic_exact_answer_short_circuit,
    - requires complete_without_model=true,
    - requires model_call_allowed=false,
    - completes through /internal/edge-worker/jobs/{job_id}/complete,
    - stores model backend-deterministic/no-model,
    - does not call PVESO, Ollama, or a model endpoint.

## CJ-T runtime proof

CJ-T staged the helper temporarily into CT203 /tmp.

It inserted one fresh exact-answer Companion proof job:

    id=577
    job_type=companion.chat
    requested_model=qwen2.5:0.5b
    marker=FC-O45-E-CJ-T-HELPER-RUNTIME-OK

The helper safe summary verified:

    claim_response_key=claimed
    complete_without_model=true
    job_id=577
    model_endpoint_called=false
    pveso_called=false
    response_text=FC-O45-E-CJ-T-HELPER-RUNTIME-OK
    result_model=backend-deterministic/no-model
    stage=stage16-fc-o45-e-cj-s

Final DB verification:

    id=577
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=1
    result_model=backend-deterministic/no-model
    response=FC-O45-E-CJ-T-HELPER-RUNTIME-OK

## What this proves

The reusable helper can complete a fresh exact-answer Companion job through the real internal edge-worker claim and complete endpoints without a model call.

This is stronger than the earlier manual proof because the reusable helper handles the actual API response shape and performs the claim-to-complete sequence itself.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation during runtime proof, no backend deploy during runtime proof, no service mutation, no CT203 runtime patch, no schema migration, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package/model pull, no PVESO call, no Ollama/model endpoint call, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Install this helper into the CT203 runtime ops path with a disabled-by-default one-shot service/template, then prove one bounded invocation. Keep persistent workers and timers disabled.
