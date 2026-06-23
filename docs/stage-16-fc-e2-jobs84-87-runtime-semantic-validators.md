# Stage 16 FC-E2 jobs84-87 runtime semantic validators

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_E_SERIAL_RUNTIME_JOBS_81_87_WITH_SEMANTIC_VALIDATORS

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-E1.
- Base HEAD/origin/main: `6d77c57`.
- Base tag: `controller-stage-16-fc-e1-jobs81-83-runtime-semantic-validators-2026-06-22`.

## Runtime scope

FC-E2 processed jobs84 through 87 only through the general_queue unit family.

It did:

- process job84 summary semantic probe,
- process job85 JSON semantic probe,
- process job86 router_label semantic probe,
- process job87 safe_refusal semantic probe,
- start one one-shot timer at a time,
- wait for that exact job to complete,
- stop that job timer/service after completion,
- verify each job completed with exactly one result row,
- run semantic validators for jobs84 through 87,
- produce a final jobs81 through 87 semantic matrix,
- preserve jobs57 through 80 evidence,
- verify final CT101 default-off posture,
- commit/tag/push this evidence.

It did not:

- process jobs81 through 83 again,
- process jobs59 through 80,
- retry job65,
- reset, delete, retry, or manually complete jobs,
- insert jobs,
- mutate the CT101 profile,
- enable or disable timers/services,
- reset-failed services,
- write systemd unit files,
- run daemon-reload,
- activate scheduler or persistent workers,
- drain the queue,
- mutate Docker,
- pull models,
- restart CTs or VMs.

## Mechanical result

    job84_runtime_outcome=completed
    job84_status_after_fc_e2=completed
    job84_attempts_after_fc_e2=1
    job84_result_rows_after_fc_e2=1

    job85_runtime_outcome=completed
    job85_status_after_fc_e2=completed
    job85_attempts_after_fc_e2=1
    job85_result_rows_after_fc_e2=1

    job86_runtime_outcome=completed
    job86_status_after_fc_e2=completed
    job86_attempts_after_fc_e2=1
    job86_result_rows_after_fc_e2=1

    job87_runtime_outcome=completed
    job87_status_after_fc_e2=completed
    job87_attempts_after_fc_e2=1
    job87_result_rows_after_fc_e2=1

    jobs81_87_completed_after_fc_e2=7
    jobs81_87_result_rows_after_fc_e2=7
    ct203_fc_e2_mechanical_acceptance_pass=true

## Semantic result

    job84_semantic_pass_fc_e2=false
    job85_semantic_pass_fc_e2=false
    job86_semantic_pass_fc_e2=true
    job87_semantic_pass_fc_e2=false
    jobs84_87_semantic_pass_count_fc_e2=1
    jobs84_87_semantic_fail_count_fc_e2=3

Final FC-E semantic matrix:

    job81_semantic_pass_final_fc_e2=true
    job82_semantic_pass_final_fc_e2=false
    job83_semantic_pass_final_fc_e2=false
    job84_semantic_pass_final_fc_e2=false
    job85_semantic_pass_final_fc_e2=false
    job86_semantic_pass_final_fc_e2=true
    job87_semantic_pass_final_fc_e2=false
    jobs81_87_semantic_pass_count_final_fc_e2=2
    jobs81_87_semantic_fail_count_final_fc_e2=5
    fc_e2_semantic_all_pass=false

Semantic failures are not runtime failures. They block productization for the failed lane until prompt/model/validator strategy is improved.

## Protected evidence preserved

    jobs73_80_completed_after_fc_e2=8
    jobs73_80_result_rows_after_fc_e2=8
    jobs65_72_queued_after_fc_e2=7
    jobs65_72_running_after_fc_e2=1
    jobs65_72_result_rows_after_fc_e2=0
    jobs57_64_existing_after_fc_e2=8
    jobs57_64_completed_after_fc_e2=1
    jobs57_64_running_after_fc_e2=1
    jobs57_64_queued_after_fc_e2=6
    jobs57_64_result_rows_after_fc_e2=1

## CT101 cleanup/default-off evidence

    job84_unit_cleanup_acceptance_pass=true
    job85_unit_cleanup_acceptance_pass=true
    job86_unit_cleanup_acceptance_pass=true
    job87_unit_cleanup_acceptance_pass=true
    active_exact_services_after_fc_e2=0
    active_exact_timers_after_fc_e2=0
    active_general_services_after_fc_e2=0
    active_general_timers_after_fc_e2=0
    exact_timer_enabled_after_fc_e2=disabled
    general_timer_enabled_after_fc_e2=disabled
    edge_service_active_after_fc_e2=inactive
    edge_service_enabled_after_fc_e2=disabled
    legacy_main_active_after_fc_e2=inactive
    legacy_main_enabled_after_fc_e2=masked
    ct101_final_default_off_after_fc_e2_acceptance_pass=true

## FC-E conclusion

FC-E proves:

- all seven FC semantic probe jobs can be processed mechanically,
- each job completed with attempts=1 and result_rows=1,
- the profile mutation from FC-C works for all seven lane-specific job_types,
- the general_queue unit path can process lane-specific semantic jobs serially,
- default-off posture is restored after every job and final.

FC-E also proves why semantic gates are necessary:

- a mechanical pass is not enough,
- failed semantic validators must block lane productization,
- tiny smoke model output quality is not sufficient for all production lanes.

## Recommended next stage

Recommended next stage: `Stage 16 FC-F`.

Purpose: no-apply FC semantic result review and productization decision gate.

FC-F should decide which lanes, if any, are allowed to move forward, and define remediation for failed semantic lanes before any persistent worker, scheduler, or public product route activation.
