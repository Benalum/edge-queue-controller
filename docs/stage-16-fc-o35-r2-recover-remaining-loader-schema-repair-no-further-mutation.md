# Stage 16 FC-O35-R2 recover remaining loader schema repair no further mutation

Date: 2026-06-23

## Why this recovery exists

FC-O35 failed after it had already written the CT101 profile repair. The profile mutation succeeded, but the validation script crashed while importing the worker module through importlib without registering it in sys.modules first.

The failed validation error was:

    AttributeError: 'NoneType' object has no attribute '__dict__'

This is a validation-script bug, not a worker-runtime finding.

FC-O35 had already copied the remaining missing loader-required fields:

    timeout_seconds
    exact_marker_supported

## Base checkpoint

- Prior repo checkpoint: Stage 16 FC-O34.
- Base HEAD/origin/main before this recovery: `a50cedb`.
- Base tag: `controller-stage-16-fc-o34-run-only-job107-gemma4-companion-chat-after-container-name-repair-2026-06-23`.

## Recovery mutation boundary

This recovery performed only:

- read-only CT101 verification,
- read-only CT203 verification,
- repo docs/smoke/commit/tag/push.

It did not perform any further CT101 profile write.

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

## Profile state recovered from failed FC-O35

    profile_sha_after_failed_fc_o35_now=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    profile_backup_path_fc_o35_r2=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o35-pre-remaining-loader-schema-repair.20260623T185429Z.bak
    profile_backup_sha_fc_o35_r2=ffcb5278d6a6f470e7f9a1341eaaf2235820880d4677f2c8c4f6bbd3aba95f98
    worker_sha_now_fc_o35_r2=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

The profile sha is the sha written by the failed FC-O35 run.

The backup sha matches the pre-FC-O35 profile.

## Loader-required keys

    worker_required_raw_keys_fc_o35_r2=profile_id,model_name,role,endpoint_type,container_name,timeout_seconds,max_concurrent_model_calls,claim_policy,exact_marker_supported,thinking_mode,hidethinking_required,completion_validation_policy,enabled_by_default
    profile_validation_after_failed_fc_o35_r2_pass=true
    worker_load_model_profiles_after_failed_fc_o35_r2_pass=true
    profile_model_name_count_after_failed_fc_o35_r2 gemma4:e4b=1
    profile_model_name_count_after_failed_fc_o35_r2 gemma3:4b=1
    profile_model_name_count_after_failed_fc_o35_r2 llama3.2:3b=1

For all target profiles, the audited loader-required keys are present.

The corrected worker-loader validation imported the module with sys.modules registration before exec_module, then called load_model_profiles read-only. That passed.

## CT101/Ollama verification

    OLLAMA_NUM_PARALLEL_fc_o35_r2=2
    OLLAMA_KEEP_ALIVE_fc_o35_r2=30m
    ollama_container_state_fc_o35_r2=running
    ollama_container_health_fc_o35_r2=healthy
    active_exact_services_fc_o35_r2=0
    active_general_services_fc_o35_r2=0
    active_exact_timers_fc_o35_r2=0
    active_general_timers_fc_o35_r2=0
    failed_general_units_fc_o35_r2=7
    ct101_fc_o35_r2_read_only_acceptance_pass=true

Failed general unit evidence intentionally remains at 7. FC-O35-R2 did not reset-failed.

## CT203 verification

    quick_check_fc_o35_r2=ok
    job105_status_fc_o35_r2=running
    job105_attempts_fc_o35_r2=1
    job105_result_rows_fc_o35_r2=0
    job107_status_fc_o35_r2=queued
    job107_attempts_fc_o35_r2=0
    job107_result_rows_fc_o35_r2=0
    job108_status_fc_o35_r2=queued
    job108_attempts_fc_o35_r2=0
    job108_result_rows_fc_o35_r2=0
    job109_status_fc_o35_r2=queued
    job109_attempts_fc_o35_r2=0
    job109_result_rows_fc_o35_r2=0
    job110_status_fc_o35_r2=queued
    job110_attempts_fc_o35_r2=0
    job110_result_rows_fc_o35_r2=0
    job111_status_fc_o35_r2=queued
    job111_attempts_fc_o35_r2=0
    job111_result_rows_fc_o35_r2=0
    jobs107_111_remain_queued_fc_o35_r2=true
    ct203_fc_o35_r2_read_only_acceptance_pass=true

## Decision

The failed FC-O35 profile repair is recovered and validated.

Gemma/llama target profiles now satisfy the audited loader-required key set, and the worker load_model_profiles function can load them.

No runtime occurred during recovery.

Next recommended stage: rerun job107 only as FC-O36 gemma4 companion_chat one-shot after recovered remaining-loader-schema repair.
