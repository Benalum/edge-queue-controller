# Stage 16 FC-O45-E-CK-I — Selector Wrapper Runtime Proof

Date: 2026-06-26

## Summary

CK-I proved the installed marker-selected Companion selector wrapper path.

It inserted one fresh exact-answer `companion.chat` job, ran the installed selector wrapper once by exact marker, verified the selector found exactly one queued job, delegated to the installed manual wrapper, and completed the job through the disabled-by-default systemd one-shot service path with no model endpoint call.

## Runtime components verified before proof

CT203 live backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Runtime helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Runtime manual wrapper SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

Runtime selector SHA:

    1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41

Template enabled state:

    static

## Fresh job proof

Fresh job id:

    580

Job type:

    companion.chat

Requested model:

    qwen2.5:0.5b

Exact marker:

    FC-O45-E-CK-I-SELECTOR-RUNTIME-OK

Installed selector invoked:

    /opt/edge-queue-controller/ops/workers/run-next-deterministic-companion-systemd-once.sh

Selector delegate:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh

Delegate service instance:

    edge-deterministic-companion-worker-once@580.service

## Selector proof lines

The selector had exactly one eligible candidate before running:

    CK_I_SELECTOR_CANDIDATE_COUNT=1
    CK_I_SELECTOR_CANDIDATE id=580 status=queued attempts=0 type=companion.chat requested_model=qwen2.5:0.5b result_rows=0

The selector selected the same job:

    candidate_count=1
    selected_job id=580 status=queued attempts=0 job_type=companion.chat requested_model=qwen2.5:0.5b result_rows=0
    marker_selected_wrapper_job_id=580

The selector delegated to the manual wrapper:

    deterministic_companion_systemd_once_job_id=580
    deterministic_companion_systemd_once_service=edge-deterministic-companion-worker-once@580.service

## Delegate wrapper proof lines

The delegate wrapper verified the job before running:

    preflight_job id=580 status=queued attempts=0 job_type=companion.chat requested_model=qwen2.5:0.5b result_rows=0

The delegate wrapper created the per-job env file:

    env_file_created=yes

The one-shot service completed successfully:

    service_active_state=inactive
    service_result=success
    service_exec_main_status=0

The delegate wrapper verified the final result:

    final_job id=580 status=completed attempts=1 job_type=companion.chat result_rows=1
    final_result_model=backend-deterministic/no-model
    final_response=FC-O45-E-CK-I-SELECTOR-RUNTIME-OK
    final_error=None

The delegate wrapper removed the per-job env file:

    env_file_removed=yes

The delegate wrapper completed:

    deterministic_companion_systemd_once_done=yes

## Final independent verification

Final job verification:

    id=580
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    type=companion.chat
    result_rows=1

Final result verification:

    result_model=backend-deterministic/no-model
    response=FC-O45-E-CK-I-SELECTOR-RUNTIME-OK
    error=None

## What this proves

The installed selector wrapper can safely find exactly one approved queued Companion job by marker and complete it through the manual wrapper and disabled-by-default systemd one-shot path.

This gives the platform a practical operator-safe execution path:

    approved queued companion.chat job
    -> explicit marker
    -> selector finds exactly one eligible job
    -> manual wrapper delegate
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

Keep this as the safest manual lane. Next, add a read-only runbook/status check that reports eligible queued Companion jobs without starting anything.
