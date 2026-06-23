# Stage 16 FC-O33 repair gemma/llama profile container_name schema no-runtime

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O33_REPAIR_GEMMA_LLAMA_PROFILE_CONTAINER_NAME_SCHEMA_NO_RUNTIME_NO_JOB_PROCESSING_NO_RESET_FAILED

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O32.
- Base HEAD/origin/main: `3b85d91`.
- Base tag: `controller-stage-16-fc-o32-run-only-job107-gemma4-companion-chat-after-endpoint-type-repair-2026-06-23`.

## Why this stage was needed

FC-O32 safely failed before claim/model execution with:

    KeyError: 'container_name'

Job107 remained queued attempts=0 rows=0, so no DB result cleanup was required.

The target gemma/llama profile entries had `model_name` and `endpoint_type`, but the worker profile loader also requires `container_name`.

## Mutation boundary

This stage mutated only the CT101 profile file:

    /etc/edge-ct101-worker/model-profiles.yaml

It did not:

- write CT203 DB,
- insert jobs,
- mutate jobs,
- reset, retry, delete, or manually complete jobs,
- insert job_results rows,
- run jobs,
- start services,
- enable services or timers,
- start timers,
- write systemd units,
- run daemon-reload,
- reset failed units,
- clear failed unit evidence,
- mutate CT101 worker code,
- mutate Docker,
- mutate Ollama,
- call Ollama generation/model endpoints,
- pull models,
- activate scheduler,
- activate persistent workers,
- drain the queue,
- restart CTs or VMs.

## Backup

    profile_backup_path_fc_o33=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o33-pre-container-name-schema-repair.20260623T184654Z.bak
    profile_backup_sha_fc_o33=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7

## Profile sha

    profile_sha_before_fc_o33=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7
    profile_sha_after_fc_o33=ffcb5278d6a6f470e7f9a1341eaaf2235820880d4677f2c8c4f6bbd3aba95f98
    worker_sha_after_fc_o33=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

The profile sha changed and the worker sha remained unchanged.

## Repair

    reference_container_name_fc_o33=ollama
    profile_container_name_schema_repaired_ids_fc_o33=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate
    profile_container_name_key_present_for_targets_fc_o33=true
    profile_endpoint_type_key_still_present_for_targets_fc_o33=true
    profile_model_name_key_still_present_for_targets_fc_o33=true
    profile_model_key_absent_for_targets_fc_o33=true

For each target profile, FC-O33:

- added `container_name: ollama`,
- used the existing proven qwen3:1.7b profile as the container_name reference,
- preserved `model_name`,
- preserved `endpoint_type`,
- kept the stale `model` key absent,
- preserved max_concurrent_model_calls=1,
- preserved claim_policy=one_at_a_time,
- preserved completion_validation_policy=exact_marker_only,
- preserved enabled_by_default=false,
- preserved allowed job types.

## Post-repair profile verification

    profile_parse_after_fc_o33=true
    profile_validation_after_fc_o33_pass=true
    profile_container_name_uniform_for_targets_fc_o33=true
    profile_model_name_count_after_fc_o33 gemma4:e4b=1
    profile_model_name_count_after_fc_o33 gemma3:4b=1
    profile_model_name_count_after_fc_o33 llama3.2:3b=1

## CT101/Ollama verification

    OLLAMA_NUM_PARALLEL_after_fc_o33=2
    ollama_container_state_after_fc_o33=running
    ollama_container_health_after_fc_o33=healthy
    active_exact_services_after_fc_o33=0
    active_general_services_after_fc_o33=0
    active_exact_timers_after_fc_o33=0
    active_general_timers_after_fc_o33=0
    failed_general_units_after_fc_o33=7
    ct101_container_name_repair_fc_o33_acceptance_pass=true

Failed general unit evidence intentionally remains at 7. FC-O33 did not reset-failed.

## CT203 post-repair verification

    quick_check_after_fc_o33=ok
    job105_status_after_fc_o33=running
    job105_attempts_after_fc_o33=1
    job105_result_rows_after_fc_o33=0
    job107_status_after_fc_o33=queued
    job107_attempts_after_fc_o33=0
    job107_result_rows_after_fc_o33=0
    job108_status_after_fc_o33=queued
    job108_attempts_after_fc_o33=0
    job108_result_rows_after_fc_o33=0
    job109_status_after_fc_o33=queued
    job109_attempts_after_fc_o33=0
    job109_result_rows_after_fc_o33=0
    job110_status_after_fc_o33=queued
    job110_attempts_after_fc_o33=0
    job110_result_rows_after_fc_o33=0
    job111_status_after_fc_o33=queued
    job111_attempts_after_fc_o33=0
    job111_result_rows_after_fc_o33=0
    jobs107_111_remain_queued_after_fc_o33=true
    ct203_post_fc_o33_read_only_acceptance_pass=true

## Decision

Gemma/llama target profile container_name schema is repaired.

No runtime occurred.

Next recommended stage: rerun job107 only as FC-O34 gemma4 companion_chat one-shot after container_name repair.
