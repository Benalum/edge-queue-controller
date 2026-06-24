# Stage 16 FC-O41 product profile policy update only no job processing

Date: 2026-06-23

## Purpose

FC-O41 switched only the target product model profiles from `exact_marker_only` to `product_visible_output_v1`.

This stage did not process jobs. It only updated the CT101 profile policy now that FC-O40-B-R4 and FC-O40-C installed and validated worker support.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O40-C.
- Base HEAD/origin/main: `99606cc`.
- Base tag: `controller-stage-16-fc-o40-c-patch-product-visible-output-validate-completion-dispatch-no-job-processing-2026-06-23`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O41_PRODUCT_PROFILE_POLICY_UPDATE_ONLY_NO_JOB_PROCESSING_NO_RESET_FAILED

## Mutation boundary

Allowed mutations:

- backup CT101 profile file,
- update only target product profile `completion_validation_policy`,
- parse/load profile validation,
- repo docs/smoke/commit/tag/push.

Explicitly not performed:

- CT101 worker mutation,
- CT203 DB write,
- job insert,
- job mutation,
- job reset/retry/delete/manual completion,
- job_results insert,
- job processing,
- runtime model call,
- service start,
- service enable,
- timer start,
- timer enable,
- systemd unit write,
- daemon-reload,
- reset-failed,
- clearing failed-unit evidence,
- Docker mutation,
- Ollama mutation,
- Ollama generation/model endpoint calls,
- Ollama model pull,
- scheduler activation,
- persistent worker activation,
- queue drain,
- CT/VM restart.

## Worker baseline

    deployed_worker_sha_fc_o41=1809af3a97e5b357d47b4ce3728ca4e5e8f6692de89e920b881f7b3b58b820d3

## Profile update

    old_profile_sha_fc_o41=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    new_profile_sha_fc_o41=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b
    profile_backup_path_fc_o41=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o41-pre-product-visible-output-policy.20260624T001122Z.bak
    profile_backup_sha_fc_o41=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740

Updated policies:

    gemma4_product_candidate=product_visible_output_v1
    gemma3_companion_candidate=product_visible_output_v1
    llama32_safe_refusal_candidate=product_visible_output_v1

Preserved intent:

    enabled_by_default=false
    max_concurrent_model_calls=1
    model_name unchanged
    allowed_job_types unchanged
    endpoint_type/container_name/timeout unchanged

## Profile validation

The deployed worker loaded the profile successfully after mutation.

    profile_load_validation_fc_o41=true
    ct101_fc_o41_profile_policy_acceptance_pass=true

## CT101 state

    OLLAMA_NUM_PARALLEL_after_profile_update_fc_o41=2
    OLLAMA_KEEP_ALIVE_after_profile_update_fc_o41=30m
    active_exact_services_after_profile_update_fc_o41=0
    active_general_services_after_profile_update_fc_o41=0
    active_exact_timers_after_profile_update_fc_o41=0
    active_general_timers_after_profile_update_fc_o41=0
    failed_general_units_before_profile_update_fc_o41=6
    failed_general_units_after_profile_update_fc_o41=6

No failed-unit evidence was cleared.

## CT203 queue state

Queue state was preserved before and after the profile policy update:

    job105=running,1,0
    job106=completed,1,1
    job107=completed,1,1
    job108=queued,0,0
    job109=queued,0,0
    job110=queued,0,0
    job111=queued,0,0
    job112=completed,1,1
    job113=completed,1,1
    job114=completed,1,1
    job115=completed,1,1
    job116=completed,1,1

## Rollback

Profile backup:

    /etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o41-pre-product-visible-output-policy.20260624T001122Z.bak

Rollback command, only if explicitly approved in a later rollback stage:

    install -o root -g root -m 0644 /etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o41-pre-product-visible-output-policy.20260624T001122Z.bak /etc/edge-ct101-worker/model-profiles.yaml

No rollback is required now because profile load validation passed and no jobs were processed.

## Decision

FC-O41 unblocked fresh product probes under `product_visible_output_v1`.

Next recommended stage: FC-O42 insert fresh product-style probes, preserving jobs108-111 as historical stale probes.
