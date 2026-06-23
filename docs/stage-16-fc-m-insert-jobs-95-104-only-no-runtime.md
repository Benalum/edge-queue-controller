# Stage 16 FC-M insert jobs 95-104 only no-runtime

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_M_INSERT_JOBS_95_104_ONLY_NO_RUNTIME

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-L.
- Base HEAD/origin/main: `695deab`.
- Base tag: `controller-stage-16-fc-l-model-inventory-readiness-no-apply-2026-06-22`.

## Mutation scope

FC-M inserted exactly jobs95 through 104 into CT203.

It did:

- verify CT101 profile hash,
- verify CT101 default-off posture,
- verify required installed model manifests through filesystem inventory,
- create a CT203 DB backup,
- verify max job id was 94,
- verify jobs95 through 104 did not exist,
- insert exactly jobs95 through 104,
- use lane-specific FC job_type per job,
- use planned requested_model per job,
- set status queued,
- set attempts 0,
- verify jobs95 through 104 have no result rows,
- preserve jobs57 through 94 evidence,
- commit/tag/push this evidence.

It did not:

- process any jobs,
- call model endpoints,
- run Ollama list/version/generate/chat/embed,
- pull or download models,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- mutate CT101 profile,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- restart CTs or VMs.

## CT101 preflight

    profile_sha_before_fc_m=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    active_exact_services_before_fc_m=0
    active_exact_timers_before_fc_m=0
    active_general_services_before_fc_m=0
    active_general_timers_before_fc_m=0
    exact_timer_enabled_before_fc_m=disabled
    general_timer_enabled_before_fc_m=disabled
    edge_service_active_before_fc_m=inactive
    edge_service_enabled_before_fc_m=disabled
    legacy_main_active_before_fc_m=inactive
    legacy_main_enabled_before_fc_m=masked
    ct101_before_fc_m_inventory_default_off_acceptance_pass=true

Model manifests verified by filesystem:

- `qwen2.5:0.5b`
- `qwen3:1.7b`
- `gemma4:e4b`
- `gemma3:4b`
- `llama3.2:3b`

## CT203 backup

    backup_path_fc_m=/var/lib/edge-queue-controller/stage16-fc-backups/edge_queue.sqlite3.stage16-fc-m-pre-jobs95-104-insert.20260623T034539Z.bak
    backup_sha256_fc_m=0d3b36249b085183045d1dd331a7e25039beaf30d35b633a4ba99083e6ce33e6
    backup_size_bytes_fc_m=43851776

## Insert evidence

Pre-insert:

    quick_check_before_fc_m_insert=ok
    max_job_id_before_fc_m_insert=94
    jobs95_104_existing_before_fc_m_insert=0

Inserted:

    inserted_jobs_count_fc_m=10

Post-insert:

    quick_check_after_fc_m_insert=ok
    max_job_id_after_fc_m_insert=104
    jobs95_104_existing_after_fc_m_insert=10
    jobs95_104_queued_after_fc_m_insert=10
    jobs95_104_attempts_zero_after_fc_m_insert=10
    jobs95_104_result_rows_after_fc_m_insert=0
    jobs95_104_expected_shape_match_after_fc_m_insert=true
    ct203_fc_m_insert_acceptance_pass=true

## Jobs95-104 inserted

- job95: `stage16_fc_router_label_semantic_probe`, requested_model `qwen2.5:0.5b`
- job96: `stage16_fc_summary_semantic_probe`, requested_model `qwen2.5:0.5b`
- job97: `stage16_fc_summary_semantic_probe`, requested_model `qwen3:1.7b`
- job98: `stage16_fc_json_semantic_probe`, requested_model `qwen2.5:0.5b`
- job99: `stage16_fc_json_semantic_probe`, requested_model `qwen3:1.7b`
- job100: `stage16_fc_companion_chat_semantic_probe`, requested_model `gemma4:e4b`
- job101: `stage16_fc_companion_chat_semantic_probe`, requested_model `gemma3:4b`
- job102: `stage16_fc_study_tutor_semantic_probe`, requested_model `gemma4:e4b`
- job103: `stage16_fc_flashcards_semantic_probe`, requested_model `gemma4:e4b`
- job104: `stage16_fc_safe_refusal_semantic_probe`, requested_model `llama3.2:3b`

All are queued with attempts 0 and no result rows.

## Protected evidence preserved

    jobs88_94_completed_after_fc_m_insert=7
    jobs88_94_result_rows_after_fc_m_insert=7
    jobs81_87_completed_after_fc_m_insert=7
    jobs81_87_result_rows_after_fc_m_insert=7
    jobs73_80_completed_after_fc_m_insert=8
    jobs73_80_result_rows_after_fc_m_insert=8
    jobs65_72_queued_after_fc_m_insert=7
    jobs65_72_running_after_fc_m_insert=1
    jobs65_72_result_rows_after_fc_m_insert=0
    jobs57_64_existing_after_fc_m_insert=8
    jobs57_64_completed_after_fc_m_insert=1
    jobs57_64_running_after_fc_m_insert=1
    jobs57_64_queued_after_fc_m_insert=6
    jobs57_64_result_rows_after_fc_m_insert=1

## Recommended next stage

Recommended next stage: `Stage 16 FC-N`.

Purpose: approved serial runtime for jobs95 through 104 with model-tier and output-control validators.

FC-N should likely be split into bounded batches:

- FC-N1: jobs95 through 99,
- FC-N2: jobs100 through 104,
- FC-N3: final decision matrix if needed.

FC-N must:

- process only jobs95 through 104,
- process one job at a time,
- use general_queue only,
- run no scheduler,
- enable no persistent workers,
- drain no queue,
- preserve jobs57 through 94 evidence,
- verify exactly one result row per processed job,
- restore CT101 default-off after every job and final.
