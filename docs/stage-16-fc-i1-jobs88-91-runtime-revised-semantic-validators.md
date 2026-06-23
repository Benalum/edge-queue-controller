# Stage 16 FC-I1 jobs88-91 runtime revised semantic validators

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_I_SERIAL_RUNTIME_JOBS_88_94_WITH_REVISED_SEMANTIC_VALIDATORS

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-H-R2.
- Base HEAD/origin/main: `2ad0cde`.
- Base tag: `controller-stage-16-fc-h-r2-insert-jobs-88-94-recovery-checkpoint-no-runtime-2026-06-22`.

## Runtime scope

FC-I1 processed jobs88 through 91 only through the general_queue unit family.

It did:

- process job88 study_tutor remediation probe,
- process job89 flashcards remediation probe,
- process job90 summary remediation probe,
- process job91 JSON remediation probe,
- start one one-shot timer at a time,
- wait for that exact job to complete,
- stop that job timer/service after completion,
- verify each job completed with exactly one result row,
- run revised semantic validators for jobs88 through 91,
- leave jobs92 through 94 queued and untouched,
- preserve jobs57 through 87 evidence,
- verify final CT101 default-off posture,
- commit/tag/push this evidence.

It did not:

- process jobs92 through 94,
- process jobs57 through 87,
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

    job88_runtime_outcome=completed
    job88_status_after_fc_i1=completed
    job88_attempts_after_fc_i1=1
    job88_result_rows_after_fc_i1=1

    job89_runtime_outcome=completed
    job89_status_after_fc_i1=completed
    job89_attempts_after_fc_i1=1
    job89_result_rows_after_fc_i1=1

    job90_runtime_outcome=completed
    job90_status_after_fc_i1=completed
    job90_attempts_after_fc_i1=1
    job90_result_rows_after_fc_i1=1

    job91_runtime_outcome=completed
    job91_status_after_fc_i1=completed
    job91_attempts_after_fc_i1=1
    job91_result_rows_after_fc_i1=1

    ct203_fc_i1_mechanical_acceptance_pass=true

## Revised semantic result

    job88_semantic_pass_fc_i1=false
    job89_semantic_pass_fc_i1=false
    job90_semantic_pass_fc_i1=true
    job91_semantic_pass_fc_i1=true
    jobs88_91_semantic_pass_count_fc_i1=2
    jobs88_91_semantic_fail_count_fc_i1=2
    fc_i1_semantic_all_pass=false

Semantic failures are not runtime failures. They remain productization blockers.

## Remaining queue evidence

    jobs92_94_queued_after_fc_i1=3
    jobs92_94_result_rows_after_fc_i1=0
    jobs88_94_completed_after_fc_i1=4
    jobs88_94_result_rows_after_fc_i1=4
    jobs81_87_completed_after_fc_i1=7
    jobs81_87_result_rows_after_fc_i1=7
    jobs73_80_completed_after_fc_i1=8
    jobs73_80_result_rows_after_fc_i1=8
    jobs65_72_queued_after_fc_i1=7
    jobs65_72_running_after_fc_i1=1
    jobs65_72_result_rows_after_fc_i1=0

## CT101 cleanup/default-off evidence

    job88_unit_cleanup_acceptance_pass=true
    job89_unit_cleanup_acceptance_pass=true
    job90_unit_cleanup_acceptance_pass=true
    job91_unit_cleanup_acceptance_pass=true
    active_exact_services_after_fc_i1=0
    active_exact_timers_after_fc_i1=0
    active_general_services_after_fc_i1=0
    active_general_timers_after_fc_i1=0
    exact_timer_enabled_after_fc_i1=disabled
    general_timer_enabled_after_fc_i1=disabled
    edge_service_active_after_fc_i1=inactive
    edge_service_enabled_after_fc_i1=disabled
    legacy_main_active_after_fc_i1=inactive
    legacy_main_enabled_after_fc_i1=masked
    ct101_final_default_off_after_fc_i1_acceptance_pass=true

## Recommendation

Continue under the same FC-I approval with `Stage 16 FC-I2`.

FC-I2 should process jobs92 through 94 one at a time through the general_queue unit family, run revised validators for safe_refusal, companion repeatability, and router repeatability, and then produce the final FC-I remediation matrix.
