# Stage 16 FC-N2D1-R3 final FC-N matrix stop runtime no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N2D1-R2.
- Base HEAD/origin/main: `9404727`.
- Base tag: `controller-stage-16-fc-n2d1-r2-job104-timeout-recovery-unknown-state-no-new-runtime-2026-06-22`.

## Mutation boundary

This stage is no-apply and read-only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- process any jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama endpoints,
- pull or download models,
- restart CTs or VMs.

## Evidence verified

    fc_n2d1_r2_evidence_verified_for_r3=true
    quick_check_fc_n2d1_r3=ok
    ct203_fc_n2d1_r3_read_only_acceptance_pass=true
    ct101_fc_n2d1_r3_failed_units_evidence_acceptance_pass=true

## Final FC-N model-tier matrix

| Job | Lane | Model | CT203 state | Attempts | Result rows | Semantic known? | Decision |
|---|---|---|---|---:|---:|---|---|
| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | passed and keep as qwen2.5 evidence |
| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | failed semantic, keep evidence |
| 97 | summary | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | passed and keep as qwen2.5 evidence |
| 99 | json_response | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 100 | companion_chat | gemma4:e4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 101 | companion_chat | gemma3:4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 102 | study_tutor | gemma4:e4b | queued | 0 | 0 | no | blocked; do not run until diagnosis |
| 103 | flashcards | gemma4:e4b | queued | 0 | 0 | no | blocked; do not run until diagnosis |
| 104 | safe_refusal | llama3.2:3b | running/stale | 1 | 0 | no | preserve as stale failed evidence |

## CT203 final totals

    jobs95_99_completed_fc_n2d1_r3=3
    jobs95_99_running_fc_n2d1_r3=2
    jobs95_99_result_rows_fc_n2d1_r3=3
    jobs100_104_queued_fc_n2d1_r3=2
    jobs100_104_running_fc_n2d1_r3=3
    jobs100_104_completed_fc_n2d1_r3=0
    jobs100_104_failed_fc_n2d1_r3=0
    jobs100_104_result_rows_fc_n2d1_r3=0

## CT101 final default-off state

    active_exact_services_fc_n2d1_r3=0
    active_exact_timers_fc_n2d1_r3=0
    active_general_services_fc_n2d1_r3=0
    active_general_timers_fc_n2d1_r3=0
    failed_general_units_fc_n2d1_r3=5
    exact_timer_enabled_fc_n2d1_r3=disabled
    general_timer_enabled_fc_n2d1_r3=disabled
    edge_service_active_fc_n2d1_r3=inactive
    edge_service_enabled_fc_n2d1_r3=disabled
    legacy_main_active_fc_n2d1_r3=inactive
    legacy_main_enabled_fc_n2d1_r3=masked

## Final decision

Stop FC-N runtime.

Do not run jobs102 or 103.

Do not retry jobs97, 99, 100, 101, or 104.

Do not reset jobs97, 99, 100, 101, or 104.

Do not manually mark jobs97, 99, 100, 101, or 104 failed yet.

Do not clear failed unit evidence yet.

Do not activate scheduler or persistent workers.

Reason:

- qwen2.5 mechanical path can still produce useful small-output results.
- qwen2.5 semantic quality remains mixed.
- qwen3, gemma4, gemma3, and llama3.2 all hit the same general_queue failed/stale pattern with no result rows.
- The failure now looks like a worker/model-runtime path issue for non-qwen2.5 runs, not a productization readiness issue.

## Recommended next stage

Recommended next stage: `Stage 16 FC-O`.

Purpose:

- diagnose CT101 non-qwen2.5 model-runtime failure mode,
- inspect failed unit journals for jobs97, 99, 100, 101, and 104 without clearing evidence,
- inspect worker stdout/stderr and environment shape,
- confirm whether the failure is timeout, model name mismatch, prompt/profile issue, Ollama invocation issue, or worker exception,
- keep scheduler and persistent workers off,
- avoid model pulls,
- avoid additional runtime until the failure mode is known.

FC-O can begin with read-only journal/log diagnosis and does not require runtime approval if it remains read-only.
