# Stage 16 FC-O45-E-CJ-Y — Systemd One-Shot Deterministic Companion Worker Proof

Date: 2026-06-26

## Summary

CJ-Y completed the first bounded systemd one-shot proof for the deterministic Companion exact-answer worker path.

It inserted one fresh `companion.chat` proof job, created one per-job runtime env file, started exactly one systemd service instance, completed the job through the internal edge-worker API, and removed the per-job env file after proof.

## Installed runtime pieces used

Helper:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-exact-once.py

Helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Systemd template:

    /etc/systemd/system/edge-deterministic-companion-worker-once@.service

Unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Template enabled state:

    static

CT203 backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

## Job proof

Fresh job id:

    578

Job type:

    companion.chat

Requested model:

    qwen2.5:0.5b

Exact marker:

    FC-O45-E-CJ-Y-SYSTEMD-ONESHOT-OK

Service instance:

    edge-deterministic-companion-worker-once@578.service

Per-job env file was created under:

    /run/edge-queue-controller/deterministic-companion-worker

The env file was removed after proof.

## Service result

The one-shot service completed and did not stay active:

    service_active_state=inactive
    service_result=success
    service_exec_main_status=0

## Final DB verification

Final job state:

    id=578
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=1

Final result:

    result_model=backend-deterministic/no-model
    response=FC-O45-E-CJ-Y-SYSTEMD-ONESHOT-OK
    error=None

## What this proves

A disabled-by-default systemd one-shot service instance can complete one approved exact-answer Companion job without calling PVESO, Ollama, or any model endpoint.

This gives the platform a controller-owned bounded execution path:

    queued companion.chat job
    -> explicit systemd one-shot instance
    -> internal edge-worker claim
    -> deterministic no-model completion
    -> durable job_results row

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation during runtime proof, no backend deploy, no CT203 backend runtime patch, no schema migration, no service enable, no timer install, no timer enable/start, no persistent-worker activation, no CT/VM restart, no package install, no model pull/download, no PVESO call, no Ollama/model endpoint call, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Add a tiny controller-side admin/runbook wrapper that creates the per-job env file and starts exactly one service instance for an approved job id. Keep it manual and disabled-by-default before considering any queue polling or timers.
