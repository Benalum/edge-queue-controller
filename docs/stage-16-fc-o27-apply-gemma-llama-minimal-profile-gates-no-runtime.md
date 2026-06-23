# Stage 16 FC-O27 apply gemma/llama minimal profile gates no-runtime

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O27_APPLY_GEMMA_LLAMA_MINIMAL_PROFILE_GATES_NO_RUNTIME_NO_JOB_PROCESSING

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O26.
- Base HEAD/origin/main: `4c5ab30`.
- Base tag: `controller-stage-16-fc-o26-gemma-llama-profile-remediation-contract-no-apply-2026-06-23`.

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

    profile_backup_path_fc_o27=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o27-pre-gemma-llama-profile-gates.20260623T171746Z.bak
    profile_backup_sha_fc_o27=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899

## Profile sha

    profile_sha_before_fc_o27=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    profile_sha_after_fc_o27=7464d59fc66fd63e6676980e7f8253b1de0b4046c447dc23e68ed024520d2127
    worker_sha_after_fc_o27=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

The profile sha changed and the worker sha remained unchanged.

## Profile shape and strategy

    profile_container_shape_fc_o27=profiles:list
    profile_target_entries_removed_fc_o27=gemma3_study_light_candidate:gemma3:4b,gemma4_companion_candidate:gemma4:e4b,llama32_safe_refusal_candidate:llama3.2:3b
    profile_target_entries_written_fc_o27=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate
    gemma4_profile_strategy_fc_o27=merged_gemma4_product_candidate

FC-O27 used the merged gemma4 profile strategy to avoid ambiguous duplicate model routing for `gemma4:e4b`.

## Added/corrected target profiles

### gemma4_product_candidate

    model: gemma4:e4b
    role: companion_study_flashcards_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_companion_chat_semantic_probe
      - stage16_fc_study_tutor_semantic_probe
      - stage16_fc_flashcards_semantic_probe

### gemma3_companion_candidate

    model: gemma3:4b
    role: companion_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_companion_chat_semantic_probe

### llama32_safe_refusal_candidate

    model: llama3.2:3b
    role: safe_refusal_candidate
    max_concurrent_model_calls: 1
    claim_policy: one_at_a_time
    completion_validation_policy: exact_marker_only
    enabled_by_default: false
    thinking_mode: off
    hidethinking_required: false
    cli_flags: []
    allowed_job_types:
      - stage16_fc_safe_refusal_semantic_probe

## Post-apply verification

    profile_parse_after_fc_o27=true
    profile_validation_after_fc_o27_pass=true
    profile_model_count_after_fc_o27 gemma4:e4b=1
    profile_model_count_after_fc_o27 gemma3:4b=1
    profile_model_count_after_fc_o27 llama3.2:3b=1
    OLLAMA_NUM_PARALLEL_after_fc_o27=2
    ollama_container_state_after_fc_o27=running
    ollama_container_health_after_fc_o27=healthy
    active_exact_services_after_fc_o27=0
    active_general_services_after_fc_o27=0
    active_exact_timers_after_fc_o27=0
    active_general_timers_after_fc_o27=0
    failed_general_units_after_fc_o27=6
    ct101_profile_apply_fc_o27_acceptance_pass=true

## CT203 post-apply verification

    quick_check_after_fc_o27=ok
    job105_status_after_fc_o27=running
    job105_attempts_after_fc_o27=1
    job105_result_rows_after_fc_o27=0
    job107_status_after_fc_o27=queued
    job107_attempts_after_fc_o27=0
    job107_result_rows_after_fc_o27=0
    job108_status_after_fc_o27=queued
    job108_attempts_after_fc_o27=0
    job108_result_rows_after_fc_o27=0
    job109_status_after_fc_o27=queued
    job109_attempts_after_fc_o27=0
    job109_result_rows_after_fc_o27=0
    job110_status_after_fc_o27=queued
    job110_attempts_after_fc_o27=0
    job110_result_rows_after_fc_o27=0
    job111_status_after_fc_o27=queued
    job111_attempts_after_fc_o27=0
    job111_result_rows_after_fc_o27=0
    jobs107_111_remain_queued_after_fc_o27=true
    ct203_post_fc_o27_read_only_acceptance_pass=true

## Decision

Gemma/llama minimal profile gates are now applied.

No runtime occurred.

Jobs107-111 remain queued and ready for separately approved one-job proof stages.

Next recommended stage: FC-O28 run only job107 gemma4:e4b companion_chat proof.
