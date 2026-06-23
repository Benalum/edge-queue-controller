# Stage 16 FC-O32 run only job107 gemma4 companion chat after endpoint_type repair

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O32_RUN_ONLY_JOB107_GEMMA4_COMPANION_CHAT_AFTER_ENDPOINT_TYPE_REPAIR_NO_BULK_NO_OLD_JOB_MUTATION_NO_RESET_FAILED

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O31.
- Base HEAD/origin/main: `9f5e232`.
- Base tag: `controller-stage-16-fc-o31-repair-gemma-llama-profile-endpoint-type-schema-no-runtime-2026-06-23`.

## Mutation boundary

This stage started exactly one CT101 service instance:

    edge-ct101-general-queue-job-worker@107.service

It did not:

- run bulk jobs,
- mutate old jobs,
- reset-failed,
- reset, retry, delete, or manually complete job105,
- mutate jobs106 or 108-116,
- retry job107 beyond this one-shot,
- manually insert job_results rows,
- apply schema changes,
- mutate CT101 profile,
- mutate CT101 worker code,
- mutate Ollama concurrency,
- enable services or timers,
- start timers,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- pull models,
- restart CTs or VMs.

## CT101/Ollama state

    profile_sha_fc_o32=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7
    worker_sha_fc_o32=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    OLLAMA_NUM_PARALLEL_before_fc_o32=2
    OLLAMA_NUM_PARALLEL_after_fc_o32=2
    OLLAMA_KEEP_ALIVE_before_fc_o32=30m
    unit107_active_state_fc_o32=failed
    unit107_result_fc_o32=exit-code
    unit107_exec_main_code_fc_o32=1
    unit107_exec_main_status_fc_o32=1
    active_exact_services_after_fc_o32=0
    active_general_services_after_fc_o32=0
    active_exact_timers_after_fc_o32=0
    active_general_timers_after_fc_o32=0
    failed_general_units_before_fc_o32=7
    failed_general_units_after_fc_o32=7
    ct101_job107_one_service_fc_o32_observed=true

## CT203 result summary

    quick_check_after_fc_o32=ok
    job107_job_type_after_fc_o32=stage16_fc_companion_chat_semantic_probe
    job107_requested_model_after_fc_o32=gemma4:e4b
    job107_status_after_fc_o32=queued
    job107_attempts_after_fc_o32=0
    job107_result_rows_after_fc_o32=0
    job107_last_error_after_fc_o32=<none>
    job107_response_sha_fc_o32=<none>
    job107_mechanical_pass_fc_o32=false
    job107_output_hygiene_pass_fc_o32=false
    job107_semantic_pass_fc_o32=false
    job107_product_surface_candidate_fc_o32=false
    preserved_unrelated_jobs_fc_o32=true
    ct203_post_fc_o32_safety_acceptance_pass=true

## Response preview

    <none>

## Interpretation

Mechanical pass means job107 completed with attempts=1 and one result row.

Output hygiene pass means the output was non-empty and did not expose visible thinking, hidden thinking markers, traceback text, or worker refusal text.

Semantic pass means the output looked like a usable companion-chat response rather than merely echoing an exact marker or diagnostic JSON.

Product surface candidate means the result is good enough to continue toward the Companion surface with this model.

## Preserved jobs

Job105 remained running attempts=1 rows=0.

Job106 remained completed attempts=1 rows=1.

Jobs108-111 remained queued attempts=0 rows=0.

Jobs112-116 remained completed attempts=1 rows=1.

## Decision

This stage records job107's gemma4 companion-chat result after the endpoint_type profile repair.

Next recommended stage depends on classification:

- If job107_product_surface_candidate_fc_o32=true, continue to FC-O33 run only job108 gemma3 companion-chat one-shot.
- If false, stop and diagnose the next gemma4 companion blocker before running more gemma jobs.
