# Stage 16 FC-N1-R3 failed unit evidence checkpoint no-new-runtime

Date: 2026-06-22

## Approval context

Original FC-N approval phrase:

    APPROVE_STAGE_16_FC_N_SERIAL_RUNTIME_JOBS_95_104_WITH_MODEL_TIER_VALIDATORS

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-M.
- Base HEAD/origin/main: `7d06e6d`.
- Base tag: `controller-stage-16-fc-m-insert-jobs-95-104-only-no-runtime-2026-06-22`.

## Recovery reason

The original FC-N1 runtime timed out at the Project Pilot Bridge/tmux layer.

The first recovery attempt showed:

- job95 completed,
- job96 completed,
- job97 was running in CT203 with no result row,
- job97 one-shot service was in failed state,
- job97 timer was stopped to inactive,
- cleanup script failed because it expected `systemctl is-active` to return `inactive`, but failed units return `failed`.

This checkpoint records the failed unit as evidence without clearing it.

## Mutation boundary

This stage is read-only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- start new job runtime,
- process jobs97 through 104,
- stop services or timers,
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

## CT203 state

    quick_check_fc_n1_r3=ok
    job95_status_fc_n1_r3=completed
    job95_result_rows_fc_n1_r3=1
    job96_status_fc_n1_r3=completed
    job96_result_rows_fc_n1_r3=1
    job97_status_fc_n1_r3=running
    job97_result_rows_fc_n1_r3=0
    job98_status_fc_n1_r3=queued
    job99_status_fc_n1_r3=queued
    jobs95_99_completed_fc_n1_r3=2
    jobs95_99_queued_fc_n1_r3=2
    jobs95_99_running_fc_n1_r3=1
    jobs95_99_failed_fc_n1_r3=0
    jobs95_99_result_rows_fc_n1_r3=2
    jobs100_104_queued_fc_n1_r3=5
    jobs100_104_result_rows_fc_n1_r3=0
    jobs88_94_completed_fc_n1_r3=7
    jobs88_94_result_rows_fc_n1_r3=7
    jobs81_87_completed_fc_n1_r3=7
    jobs81_87_result_rows_fc_n1_r3=7
    jobs73_80_completed_fc_n1_r3=8
    jobs73_80_result_rows_fc_n1_r3=8
    jobs65_72_queued_fc_n1_r3=7
    jobs65_72_running_fc_n1_r3=1
    jobs65_72_result_rows_fc_n1_r3=0
    ct203_fc_n1_r3_read_only_acceptance_pass=true

## CT101 runtime state

    active_exact_services_fc_n1_r3=0
    active_exact_timers_fc_n1_r3=0
    active_general_services_fc_n1_r3=0
    active_general_timers_fc_n1_r3=0
    failed_general_units_fc_n1_r3=1
    job97_service_state_fc_n1_r3=failed
    job97_service_result_fc_n1_r3=exit-code
    job97_service_exec_status_fc_n1_r3=1
    exact_timer_enabled_fc_n1_r3=disabled
    general_timer_enabled_fc_n1_r3=disabled
    edge_service_active_fc_n1_r3=inactive
    edge_service_enabled_fc_n1_r3=disabled
    legacy_main_active_fc_n1_r3=inactive
    legacy_main_enabled_fc_n1_r3=masked
    ct101_fc_n1_r3_no_active_runtime_acceptance_pass=true

## Decision

Do not continue FC-N runtime yet.

Job97 is stale/failed evidence and CT203 still marks it as non-complete.

Next stage should be `Stage 16 FC-N1-R4`: a no-apply decision gate for job97 recovery options.

Possible options to evaluate:

1. Preserve job97 as failed/stale evidence and continue later with jobs98-104 only.
2. Explicitly mark job97 failed, then insert a fresh replacement summary/qwen3 job later.
3. Retry job97 only after a separate explicit approval, with timeout increased and failed unit reset handled explicitly.

No option is authorized by this checkpoint.
