# Stage 16 FC-O45-E-CK-D — Manual Wrapper Runtime Proof

Date: 2026-06-26

## Summary

CK-D proved the installed manual deterministic Companion systemd wrapper path.

It inserted one fresh exact-answer `companion.chat` job, ran the installed manual wrapper once for that exact job, and verified the job completed through the one-shot systemd service with no model endpoint call.

## Runtime components verified before proof

CT203 live backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Runtime helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Runtime wrapper SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

Template enabled state:

    static

## Fresh job proof

Fresh job id:

    579

Job type:

    companion.chat

Requested model:

    qwen2.5:0.5b

Exact marker:

    FC-O45-E-CK-D-WRAPPER-RUNTIME-OK

Installed wrapper invoked:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh

Wrapper service instance:

    edge-deterministic-companion-worker-once@579.service

## Wrapper proof lines

The wrapper verified the job before running:

    preflight_job id=579 status=queued attempts=0 job_type=companion.chat requested_model=qwen2.5:0.5b result_rows=0

The wrapper created the per-job env file:

    env_file_created=yes

The wrapper started exactly one systemd instance.

The service completed successfully:

    service_active_state=inactive
    service_result=success
    service_exec_main_status=0

The wrapper verified the final result:

    final_job id=579 status=completed attempts=1 job_type=companion.chat result_rows=1
    final_result_model=backend-deterministic/no-model
    final_response=FC-O45-E-CK-D-WRAPPER-RUNTIME-OK
    final_error=None

The wrapper removed the per-job env file:

    env_file_removed=yes

The wrapper completed:

    deterministic_companion_systemd_once_done=yes

## Final independent verification

Final job verification:

    id=579
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    type=companion.chat
    result_rows=1

Final result verification:

    result_model=backend-deterministic/no-model
    response=FC-O45-E-CK-D-WRAPPER-RUNTIME-OK
    error=None

## What this proves

The installed manual admin wrapper can safely run one approved exact-answer Companion job through the disabled-by-default systemd one-shot path.

This gives the platform a practical manual execution path:

    approved queued companion.chat job
    -> installed manual wrapper
    -> per-job env file
    -> one explicit systemd one-shot instance
    -> internal edge-worker claim/complete
    -> durable job_results row
    -> env cleanup

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation during runtime proof, no backend deploy, no CT203 backend runtime patch, no schema migration, no service enable, no timer install, no timer enable/start, no persistent-worker activation, no CT/VM restart, no package install, no model pull/download, no PVESO call, no Ollama/model endpoint call, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Keep this as the manual safe lane. Next, add a source-only controller/runbook endpoint or admin script that can select one eligible queued Companion job and invoke this wrapper, still without polling, timers, or persistent workers.
