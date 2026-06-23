# Stage 16 FC-C add semantic probe job_types to CT101 profile only no-runtime

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_C_ADD_SEMANTIC_PROBE_JOB_TYPES_TO_CT101_PROFILE_ONLY_NO_RUNTIME

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-B.
- Base HEAD/origin/main: `166a213`.
- Base tag: `controller-stage-16-fc-b-semantic-probe-jobs-contract-no-apply-2026-06-22`.

## Mutation scope

FC-C performed a CT101 profile-only mutation.

It did:

- verify CT203 read-only baseline,
- verify CT101 profile preimage hash,
- back up `/etc/edge-ct101-worker/model-profiles.yaml`,
- add exactly the seven FC semantic probe job_types to the target profile,
- preserve existing allowed_job_types,
- validate YAML parse,
- verify the CT101 worker still compiles,
- verify exact/general unit hashes unchanged,
- verify CT101 default-off posture,
- commit/tag/push this evidence.

It did not:

- write CT203 DB,
- insert jobs81 through 87,
- reset, delete, retry, or manually complete jobs,
- process any jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama/model endpoints,
- pull or download models,
- restart CTs or VMs.

## CT203 read-only baseline

    quick_check_before_fc_c=ok
    max_job_id_before_fc_c=80
    jobs81_87_existing_before_fc_c=0
    jobs73_80_completed_before_fc_c=8
    jobs73_80_result_rows_before_fc_c=8
    jobs65_72_existing_before_fc_c=8
    jobs65_72_queued_before_fc_c=7
    jobs65_72_running_before_fc_c=1
    jobs65_72_result_rows_before_fc_c=0
    jobs57_64_existing_before_fc_c=8
    jobs57_64_completed_before_fc_c=1
    jobs57_64_running_before_fc_c=1
    jobs57_64_queued_before_fc_c=6
    jobs57_64_result_rows_before_fc_c=1
    ct203_before_fc_c_read_only_acceptance_pass=true

## Profile backup and mutation evidence

Profile path:

    /etc/edge-ct101-worker/model-profiles.yaml

Profile backup:

    profile_backup_path_fc_c=/etc/edge-ct101-worker/stage16-fc-c-profile-backups/model-profiles.yaml.pre-fc-c.20260623T030837Z.bak
    profile_backup_sha256_fc_c=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d

Profile hashes:

    profile_sha_before_fc_c=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
    profile_sha_after_fc_c=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c

Target profile:

    profile_target_index_fc_c=0

Added job_types:

- `stage16_fc_companion_chat_semantic_probe`
- `stage16_fc_study_tutor_semantic_probe`
- `stage16_fc_flashcards_semantic_probe`
- `stage16_fc_summary_semantic_probe`
- `stage16_fc_json_semantic_probe`
- `stage16_fc_router_label_semantic_probe`
- `stage16_fc_safe_refusal_semantic_probe`

Verification:

    profile_fc_job_type_memberships_fc_c=7
    profile_fc_all_job_types_present_fc_c=true
    ct101_fc_c_profile_mutation_acceptance_pass=true

## CT101 worker/unit/default-off verification

Worker and units unchanged:

    ct101_worker_sha=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    exact_service_sha=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    exact_timer_sha=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390
    general_service_sha=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d
    general_timer_sha=c70c5495365b771d32ed787e35154c4bcb7c51bd8629d229ce87bdea937c766b

Default-off state after profile mutation:

    active_exact_services_after_fc_c=0
    active_exact_timers_after_fc_c=0
    active_general_services_after_fc_c=0
    active_general_timers_after_fc_c=0
    exact_timer_enabled_after_fc_c=disabled
    general_timer_enabled_after_fc_c=disabled
    edge_service_active_after_fc_c=inactive
    edge_service_enabled_after_fc_c=disabled
    legacy_main_active_after_fc_c=inactive
    legacy_main_enabled_after_fc_c=masked

## Result

The CT101 profile now allows the seven FC semantic probe job_types.

This enables the next approved insert-only stage to create jobs81 through 87 using lane-specific FC job_types.

## Recommended next stage

Recommended next stage: `Stage 16 FC-D`.

Purpose: approved CT203 insert-only stage for jobs81 through 87, no runtime.

FC-D must:

- create a CT203 DB backup,
- verify max job id is 80,
- verify jobs81 through 87 do not exist,
- insert exactly jobs81 through 87,
- use lane-specific FC job_type per job,
- use requested_model `qwen2.5:0.5b`,
- set status queued,
- set attempts 0,
- produce no result rows,
- perform no runtime,
- preserve jobs57 through 80 evidence,
- verify CT101 default-off posture after insert.
