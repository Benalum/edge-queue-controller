# Stage 16 FC-N2A-R2 timeout recovery unknown state no-new-runtime

Date: 2026-06-22

## Approval context

Original FC-N2 approval phrase:

    APPROVE_STAGE_16_FC_N2_CONTINUE_QUEUED_JOBS_98_104_SKIP_JOB97_PRESERVE_FAILED_EVIDENCE

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N1-R4.
- Base HEAD/origin/main: `e8d69ec`.
- Base tag: `controller-stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply-2026-06-22`.

## Recovery reason

The first FC-N2A attempt timed out at the Project Pilot Bridge/tmux layer before returning internal stage output.

Because no internal output was returned, jobs98 and 99 had to be treated as unknown until inspected.

This recovery checkpoint:

- does not start new runtime,
- does not retry jobs,
- does not reset jobs,
- does not manually complete jobs,
- stops only possible lingering jobs98 and 99 general_queue one-shot units,
- captures CT203 state after cleanup,
- verifies CT101 has no active runtime,
- preserves job97 stale/failed evidence.

## Mutation boundary

Allowed cleanup only:

- stop `edge-ct101-general-queue-job-worker@98.timer` if lingering,
- stop `edge-ct101-general-queue-job-worker@98.service` if lingering,
- stop `edge-ct101-general-queue-job-worker@99.timer` if lingering,
- stop `edge-ct101-general-queue-job-worker@99.service` if lingering.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- start new job runtime,
- process jobs100 through 104,
- touch job97,
- clear failed unit evidence,
- reset-failed services,
- mutate CT101 profile,
- enable or disable timers/services,
- write systemd unit files,
- run daemon-reload,
- activate scheduler or persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama endpoints,
- pull models,
- restart CTs or VMs.

## CT203 state after cleanup

    quick_check_after_cleanup_fc_n2a_r2=ok

    job97_status_after_cleanup_fc_n2a_r2=running
    job97_result_rows_after_cleanup_fc_n2a_r2=0

    job98_status_after_cleanup_fc_n2a_r2=completed
    job98_attempts_after_cleanup_fc_n2a_r2=1
    job98_result_rows_after_cleanup_fc_n2a_r2=1
    job98_json_semantic_pass_after_cleanup_fc_n2a_r2=true

    job99_status_after_cleanup_fc_n2a_r2=running
    job99_attempts_after_cleanup_fc_n2a_r2=1
    job99_result_rows_after_cleanup_fc_n2a_r2=0
    job99_json_semantic_pass_after_cleanup_fc_n2a_r2=false

    jobs95_99_completed_after_cleanup_fc_n2a_r2=3
    jobs95_99_queued_after_cleanup_fc_n2a_r2=0
    jobs95_99_running_after_cleanup_fc_n2a_r2=2
    jobs95_99_failed_after_cleanup_fc_n2a_r2=0
    jobs95_99_result_rows_after_cleanup_fc_n2a_r2=3

    jobs100_104_queued_after_cleanup_fc_n2a_r2=5
    jobs100_104_running_after_cleanup_fc_n2a_r2=0
    jobs100_104_completed_after_cleanup_fc_n2a_r2=0
    jobs100_104_result_rows_after_cleanup_fc_n2a_r2=0

    jobs88_94_completed_after_cleanup_fc_n2a_r2=7
    jobs88_94_result_rows_after_cleanup_fc_n2a_r2=7
    jobs81_87_completed_after_cleanup_fc_n2a_r2=7
    jobs81_87_result_rows_after_cleanup_fc_n2a_r2=7
    jobs65_72_queued_after_cleanup_fc_n2a_r2=7
    jobs65_72_running_after_cleanup_fc_n2a_r2=1
    jobs65_72_result_rows_after_cleanup_fc_n2a_r2=0
    ct203_after_fc_n2a_r2_read_only_acceptance_pass=true

## CT101 cleanup/no-active-runtime evidence

    active_general_services_after_cleanup_fc_n2a_r2=0
    active_general_timers_after_cleanup_fc_n2a_r2=0
    failed_general_units_after_cleanup_fc_n2a_r2=2
    ct101_fc_n2a_r2_cleanup_no_active_runtime_acceptance_pass=true

## Decision

Do not continue FC-N runtime yet.

Next stage should be `Stage 16 FC-N2A-R3`, a no-apply decision gate based on whether jobs98 and 99 completed, remain queued, remain running, or failed.

No retry, reset, manual completion, or failed-unit clearing is authorized by this recovery checkpoint.
