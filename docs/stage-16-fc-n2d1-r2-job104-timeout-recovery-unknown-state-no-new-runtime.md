# Stage 16 FC-N2D1-R2 job104 timeout recovery unknown state no-new-runtime

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N2C1-R3.
- Base HEAD/origin/main: `e0abc87`.
- Base tag: `controller-stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply-2026-06-22`.

## Recovery reason

The first FC-N2D1 attempt timed out at the Project Pilot Bridge/tmux layer before returning internal output.

Because no internal output was returned, job104 had to be treated as unknown until inspected.

This recovery checkpoint:

- stops only possible lingering job104 general_queue timer/service,
- does not start new runtime,
- does not reset or retry any job,
- preserves failed evidence,
- captures CT203 and CT101 state.

## CT203 state after cleanup

    quick_check_after_cleanup_fc_n2d1_r2=ok
    ct203_after_cleanup_fc_n2d1_r2_acceptance_pass=true

    job97_status_after_cleanup_fc_n2d1_r2=running
    job99_status_after_cleanup_fc_n2d1_r2=running
    job100_status_after_cleanup_fc_n2d1_r2=running
    job101_status_after_cleanup_fc_n2d1_r2=running

    job102_status_after_cleanup_fc_n2d1_r2=queued
    job103_status_after_cleanup_fc_n2d1_r2=queued

    job104_status_after_cleanup_fc_n2d1_r2=running
    job104_attempts_after_cleanup_fc_n2d1_r2=1
    job104_result_rows_after_cleanup_fc_n2d1_r2=0
    job104_semantic_pass_after_cleanup_fc_n2d1_r2=false

    jobs100_104_queued_after_cleanup_fc_n2d1_r2=2
    jobs100_104_running_after_cleanup_fc_n2d1_r2=3
    jobs100_104_completed_after_cleanup_fc_n2d1_r2=0
    jobs100_104_failed_after_cleanup_fc_n2d1_r2=0
    jobs100_104_result_rows_after_cleanup_fc_n2d1_r2=0

## CT101 cleanup/no-active-runtime evidence

    ct101_fc_n2d1_r2_cleanup_no_active_runtime_acceptance_pass=true
    active_exact_services_after_cleanup_fc_n2d1_r2=0
    active_exact_timers_after_cleanup_fc_n2d1_r2=0
    active_general_services_after_cleanup_fc_n2d1_r2=0
    active_general_timers_after_cleanup_fc_n2d1_r2=0
    failed_general_units_after_cleanup_fc_n2d1_r2=5
    job104_service_state_after_cleanup_fc_n2d1_r2=failed
    job104_timer_state_after_cleanup_fc_n2d1_r2=inactive
    exact_timer_enabled_after_cleanup_fc_n2d1_r2=disabled
    general_timer_enabled_after_cleanup_fc_n2d1_r2=disabled
    edge_service_active_after_cleanup_fc_n2d1_r2=inactive
    edge_service_enabled_after_cleanup_fc_n2d1_r2=disabled
    legacy_main_active_after_cleanup_fc_n2d1_r2=inactive
    legacy_main_enabled_after_cleanup_fc_n2d1_r2=masked

## Decision

Do not run more FC-N runtime.

Job104 now needs a final no-apply decision gate.

If job104 completed, validate and record it in the final FC-N matrix.

If job104 remains running/stale or failed, preserve it as stale failed evidence.

After the final FC-N matrix, move to model-runtime diagnosis before any further non-qwen2.5 semantic probes.
