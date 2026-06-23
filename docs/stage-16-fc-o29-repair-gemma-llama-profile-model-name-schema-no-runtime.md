# Stage 16 FC-O29 repair gemma/llama profile model_name schema no-runtime

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O29_REPAIR_GEMMA_LLAMA_PROFILE_MODEL_NAME_SCHEMA_NO_RUNTIME_NO_JOB_PROCESSING_NO_RESET_FAILED

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O28.
- Base HEAD/origin/main: `d850d50`.
- Base tag: `controller-stage-16-fc-o28-run-only-job107-gemma4-companion-chat-one-shot-2026-06-23`.

## R2 recovery note

The initial FC-O29 run repaired CT101 profile schema successfully, then failed during the repo smoke/doc phase.

This R2 performed no further CT101 profile write and no runtime. It read back and documented the already-applied repair, fixed the repo smoke/doc content, and committed the checkpoint.

## Why FC-O29 was needed

FC-O28 safely failed before claim/model execution with:

    REFUSE_PROFILE_EMPTY_MODEL_NAME

Job107 remained queued attempts=0 rows=0, so no DB result cleanup was required.

The profile entries from FC-O27 used `model`, but the worker profile loader requires non-empty `model_name`.

## Mutation boundary

The initial FC-O29 run mutated only the CT101 profile file:

    /etc/edge-ct101-worker/model-profiles.yaml

This R2 mutated only repo docs/smoke.

Neither FC-O29 nor this R2 did any of the following:

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

    profile_backup_path_fc_o29=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o29-pre-model-name-schema-repair.20260623T181640Z.bak
    profile_backup_sha_fc_o29=7464d59fc66fd63e6676980e7f8253b1de0b4046c447dc23e68ed024520d2127

## Profile sha

    profile_sha_before_fc_o29=7464d59fc66fd63e6676980e7f8253b1de0b4046c447dc23e68ed024520d2127
    profile_sha_after_fc_o29=0e68ab762c920d4514587ef94f4c6d816b6b2e9f3879ae034aa8559e414ef34b
    worker_sha_after_fc_o29=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

The profile sha changed during the initial FC-O29 repair and the worker sha remained unchanged.

## Repair

    profile_schema_repaired_ids_fc_o29=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate
    profile_model_key_removed_for_targets_fc_o29=true
    profile_model_name_key_present_for_targets_fc_o29=true

For each target profile, FC-O29:

- added the exact required `model_name`,
- removed the target profile's stale `model` key,
- preserved max_concurrent_model_calls=1,
- preserved completion_validation_policy=exact_marker_only,
- preserved enabled_by_default=false,
- preserved allowed job types.

## Post-repair profile verification

    profile_parse_after_fc_o29=true
    profile_validation_after_fc_o29_pass=true
    profile_model_name_count_after_fc_o29 gemma4:e4b=1
    profile_model_name_count_after_fc_o29 gemma3:4b=1
    profile_model_name_count_after_fc_o29 llama3.2:3b=1
    profile_model_key_removed_for_targets_fc_o29=true
    profile_model_name_key_present_for_targets_fc_o29=true
    ct101_profile_repair_fc_o29_r2_read_only_acceptance_pass=true

## CT101/Ollama verification

    OLLAMA_NUM_PARALLEL_after_fc_o29=2
    ollama_container_state_after_fc_o29=running
    ollama_container_health_after_fc_o29=healthy
    active_exact_services_after_fc_o29=0
    active_general_services_after_fc_o29=0
    active_exact_timers_after_fc_o29=0
    active_general_timers_after_fc_o29=0
    failed_general_units_after_fc_o29=7

Failed general unit evidence intentionally remains at 7. FC-O29 did not reset-failed.

## CT203 post-repair verification

    quick_check_after_fc_o29=ok
    job105_status_after_fc_o29=running
    job105_attempts_after_fc_o29=1
    job105_result_rows_after_fc_o29=0
    job107_status_after_fc_o29=queued
    job107_attempts_after_fc_o29=0
    job107_result_rows_after_fc_o29=0
    job108_status_after_fc_o29=queued
    job108_attempts_after_fc_o29=0
    job108_result_rows_after_fc_o29=0
    job109_status_after_fc_o29=queued
    job109_attempts_after_fc_o29=0
    job109_result_rows_after_fc_o29=0
    job110_status_after_fc_o29=queued
    job110_attempts_after_fc_o29=0
    job110_result_rows_after_fc_o29=0
    job111_status_after_fc_o29=queued
    job111_attempts_after_fc_o29=0
    job111_result_rows_after_fc_o29=0
    jobs107_111_remain_queued_after_fc_o29=true
    ct203_post_fc_o29_read_only_acceptance_pass=true

## Decision

Gemma/llama target profile schema is repaired.

No runtime occurred.

Next recommended stage: rerun job107 only as FC-O30 gemma4 companion_chat one-shot after model_name repair.
