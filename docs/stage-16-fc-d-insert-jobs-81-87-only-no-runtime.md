# Stage 16 FC-D insert jobs 81-87 only no-runtime

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_D_INSERT_JOBS_81_87_ONLY_NO_RUNTIME

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-C.
- Base HEAD/origin/main: `b63f0f5`.
- Base tag: `controller-stage-16-fc-c-add-semantic-probe-job-types-to-ct101-profile-only-no-runtime-2026-06-22`.

## Mutation scope

FC-D inserted exactly jobs81 through 87 into CT203.

It did:

- verify CT101 profile contains the seven FC job_types,
- verify CT101 default-off posture before insert,
- create a CT203 DB backup,
- verify max job id was 80,
- verify jobs81 through 87 did not exist,
- insert exactly jobs81 through 87,
- use lane-specific FC job_type per job,
- use requested_model `qwen2.5:0.5b`,
- set status queued,
- set attempts 0,
- verify jobs81 through 87 have no result rows,
- preserve jobs57 through 80 evidence,
- verify CT101 profile unchanged after insert,
- verify CT101 default-off posture after insert,
- commit/tag/push this evidence.

It did not:

- process any jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- mutate CT101 profile,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama/model endpoints,
- pull or download models,
- restart CTs or VMs.

## CT101 profile/default-off preflight

    profile_sha_before_fc_d_insert=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    profile_fc_job_type_memberships_before_fc_d_insert=7
    profile_fc_all_job_types_present_before_fc_d_insert=true
    active_exact_services_before_fc_d_insert=0
    active_exact_timers_before_fc_d_insert=0
    active_general_services_before_fc_d_insert=0
    active_general_timers_before_fc_d_insert=0
    ct101_before_fc_d_insert_acceptance_pass=true

## CT203 backup

    backup_path_fc_d=/var/lib/edge-queue-controller/stage16-fc-backups/edge_queue.sqlite3.stage16-fc-d-pre-jobs81-87-insert.20260623T031138Z.bak
    backup_sha256_fc_d=0195f2c434ed830c9c45c23357669357bafd4b647d510f6ca607b888efdd2511

## Insert evidence

Pre-insert:

    quick_check_before_fc_d_insert=ok
    max_job_id_before_fc_d_insert=80
    jobs81_87_existing_before_fc_d_insert=0

Inserted:

    inserted_jobs_count_fc_d=7

Post-insert:

    quick_check_after_fc_d_insert=ok
    max_job_id_after_fc_d_insert=87
    jobs81_87_existing_after_fc_d_insert=7
    jobs81_87_queued_after_fc_d_insert=7
    jobs81_87_attempts_zero_after_fc_d_insert=7
    jobs81_87_requested_model_count_after_fc_d_insert=7
    jobs81_87_result_rows_after_fc_d_insert=0
    jobs81_87_expected_job_types_match_after_fc_d_insert=true
    ct203_fc_d_insert_acceptance_pass=true

## Jobs81-87 inserted

- job81: `stage16_fc_companion_chat_semantic_probe`
- job82: `stage16_fc_study_tutor_semantic_probe`
- job83: `stage16_fc_flashcards_semantic_probe`
- job84: `stage16_fc_summary_semantic_probe`
- job85: `stage16_fc_json_semantic_probe`
- job86: `stage16_fc_router_label_semantic_probe`
- job87: `stage16_fc_safe_refusal_semantic_probe`

All are queued with attempts 0, no result rows, requested_model `qwen2.5:0.5b`.

## Protected evidence preserved

    jobs73_80_completed_after_fc_d_insert=8
    jobs73_80_result_rows_after_fc_d_insert=8
    jobs65_72_existing_after_fc_d_insert=8
    jobs65_72_queued_after_fc_d_insert=7
    jobs65_72_running_after_fc_d_insert=1
    jobs65_72_result_rows_after_fc_d_insert=0
    jobs57_64_existing_after_fc_d_insert=8
    jobs57_64_completed_after_fc_d_insert=1
    jobs57_64_running_after_fc_d_insert=1
    jobs57_64_queued_after_fc_d_insert=6
    jobs57_64_result_rows_after_fc_d_insert=1

## CT101 final default-off verification

    profile_sha_after_fc_d_insert=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    active_exact_services_after_fc_d_insert=0
    active_exact_timers_after_fc_d_insert=0
    active_general_services_after_fc_d_insert=0
    active_general_timers_after_fc_d_insert=0
    exact_timer_enabled_after_fc_d_insert=disabled
    general_timer_enabled_after_fc_d_insert=disabled
    edge_service_active_after_fc_d_insert=inactive
    edge_service_enabled_after_fc_d_insert=disabled
    legacy_main_active_after_fc_d_insert=inactive
    legacy_main_enabled_after_fc_d_insert=masked
    ct101_after_fc_d_insert_default_off_acceptance_pass=true

## Recommended next stage

Recommended next stage: `Stage 16 FC-E`.

Purpose: approved serial runtime for jobs81 through 87 with semantic validators.

FC-E must:

- process jobs81 through 87 one at a time,
- use the general_queue unit family,
- start no persistent workers,
- activate no scheduler,
- perform no queue drain,
- verify exactly one result row per job,
- run semantic validators after result capture,
- preserve jobs57 through 80 evidence,
- restore default-off after every job and final,
- classify each job as mechanical pass/fail and semantic pass/fail.
