# Stage 16 FC-O31 repair gemma/llama profile endpoint_type schema no-runtime

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O31_REPAIR_GEMMA_LLAMA_PROFILE_ENDPOINT_TYPE_SCHEMA_NO_RUNTIME_NO_JOB_PROCESSING_NO_RESET_FAILED

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O30.
- Base HEAD/origin/main: `c4eda7e`.
- Base tag: `controller-stage-16-fc-o30-run-only-job107-gemma4-companion-chat-after-model-name-repair-2026-06-23`.

## Why this stage was needed

FC-O30 safely failed before claim/model execution with:

    KeyError: 'endpoint_type'

Job107 remained queued attempts=0 rows=0, so no DB result cleanup was required.

The target gemma/llama profile entries had `model_name` after FC-O29, but the worker profile loader also requires `endpoint_type`.

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

    profile_backup_path_fc_o31=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o31-pre-endpoint-type-schema-repair.20260623T183326Z.bak
    profile_backup_sha_fc_o31=0e68ab762c920d4514587ef94f4c6d816b6b2e9f3879ae034aa8559e414ef34b

## Profile sha

    profile_sha_before_fc_o31=0e68ab762c920d4514587ef94f4c6d816b6b2e9f3879ae034aa8559e414ef34b
    profile_sha_after_fc_o31=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7
    worker_sha_after_fc_o31=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

The profile sha changed and the worker sha remained unchanged.

## Repair

    reference_endpoint_type_fc_o31=ollama_cli_in_container
    profile_endpoint_type_schema_repaired_ids_fc_o31=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate
    profile_endpoint_type_key_present_for_targets_fc_o31=true
    profile_model_name_key_still_present_for_targets_fc_o31=true
    profile_model_key_absent_for_targets_fc_o31=true

For each target profile, FC-O31:

- added `endpoint_type: ollama_cli_in_container`,
- used the existing proven qwen3:1.7b profile as the endpoint_type reference,
- preserved `model_name`,
- kept the stale `model` key absent,
- preserved max_concurrent_model_calls=1,
- preserved claim_policy=one_at_a_time,
- preserved completion_validation_policy=exact_marker_only,
- preserved enabled_by_default=false,
- preserved allowed job types.

## Post-repair profile verification

    profile_parse_after_fc_o31=true
    profile_validation_after_fc_o31_pass=true
    profile_endpoint_type_uniform_for_targets_fc_o31=true
    profile_model_name_count_after_fc_o31 gemma4:e4b=1
    profile_model_name_count_after_fc_o31 gemma3:4b=1
    profile_model_name_count_after_fc_o31 llama3.2:3b=1

## CT101/Ollama verification

    OLLAMA_NUM_PARALLEL_after_fc_o31=2
    ollama_container_state_after_fc_o31=running
    ollama_container_health_after_fc_o31=healthy
    active_exact_services_after_fc_o31=0
    active_general_services_after_fc_o31=0
    active_exact_timers_after_fc_o31=0
    active_general_timers_after_fc_o31=0
    failed_general_units_after_fc_o31=7
    ct101_endpoint_type_repair_fc_o31_acceptance_pass=true

Failed general unit evidence intentionally remains at 7. FC-O31 did not reset-failed.

## CT203 post-repair verification

    quick_check_after_fc_o31=ok
    job105_status_after_fc_o31=running
    job105_attempts_after_fc_o31=1
    job105_result_rows_after_fc_o31=0
    job107_status_after_fc_o31=queued
    job107_attempts_after_fc_o31=0
    job107_result_rows_after_fc_o31=0
    job108_status_after_fc_o31=queued
    job108_attempts_after_fc_o31=0
    job108_result_rows_after_fc_o31=0
    job109_status_after_fc_o31=queued
    job109_attempts_after_fc_o31=0
    job109_result_rows_after_fc_o31=0
    job110_status_after_fc_o31=queued
    job110_attempts_after_fc_o31=0
    job110_result_rows_after_fc_o31=0
    job111_status_after_fc_o31=queued
    job111_attempts_after_fc_o31=0
    job111_result_rows_after_fc_o31=0
    jobs107_111_remain_queued_after_fc_o31=true
    ct203_post_fc_o31_read_only_acceptance_pass=true

## Decision

Gemma/llama target profile endpoint_type schema is repaired.

No runtime occurred.

Next recommended stage: rerun job107 only as FC-O32 gemma4 companion_chat one-shot after endpoint_type repair.
