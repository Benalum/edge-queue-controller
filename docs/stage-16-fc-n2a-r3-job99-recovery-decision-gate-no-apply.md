# Stage 16 FC-N2A-R3 job99 recovery decision gate no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N2A-R2.
- Base HEAD/origin/main: `fc21d87`.
- Base tag: `controller-stage-16-fc-n2a-r2-timeout-recovery-unknown-state-no-new-runtime-2026-06-22`.

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

    fc_n2a_r2_evidence_verified_for_r3=true
    quick_check_fc_n2a_r3=ok
    ct203_fc_n2a_r3_read_only_acceptance_pass=true
    ct101_fc_n2a_r3_failed_units_evidence_acceptance_pass=true

## Current FC-N state

| Job | Lane | Model | CT203 state | Attempts | Result rows | Semantic known? | Decision |
|---|---|---|---|---:|---:|---|---|
| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
| 97 | summary | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 99 | json_response | qwen3:1.7b | running/stale | 1 | 0 | false | preserve as stale failed evidence |
| 100-104 | remaining lanes | mixed | queued | 0 | 0 | no | eligible for later continuation |

## CT203 details

    job95_semantic_pass_fc_n2a_r3=true
    job96_semantic_pass_fc_n2a_r3=false
    job98_semantic_pass_fc_n2a_r3=true
    job99_semantic_pass_fc_n2a_r3=false

    job97_status_fc_n2a_r3=running
    job97_attempts_fc_n2a_r3=1
    job97_result_rows_fc_n2a_r3=0
    job99_status_fc_n2a_r3=running
    job99_attempts_fc_n2a_r3=1
    job99_result_rows_fc_n2a_r3=0

    jobs95_99_completed_fc_n2a_r3=3
    jobs95_99_queued_fc_n2a_r3=0
    jobs95_99_running_fc_n2a_r3=2
    jobs95_99_failed_fc_n2a_r3=0
    jobs95_99_result_rows_fc_n2a_r3=3

    jobs100_104_queued_fc_n2a_r3=5
    jobs100_104_running_fc_n2a_r3=0
    jobs100_104_completed_fc_n2a_r3=0
    jobs100_104_result_rows_fc_n2a_r3=0

## CT101 details

    active_exact_services_fc_n2a_r3=0
    active_exact_timers_fc_n2a_r3=0
    active_general_services_fc_n2a_r3=0
    active_general_timers_fc_n2a_r3=0
    failed_general_units_fc_n2a_r3=2
    job97_service_state_fc_n2a_r3=failed
    job99_service_state_fc_n2a_r3=failed
    exact_timer_enabled_fc_n2a_r3=disabled
    general_timer_enabled_fc_n2a_r3=disabled
    edge_service_active_fc_n2a_r3=inactive
    edge_service_enabled_fc_n2a_r3=disabled
    legacy_main_active_fc_n2a_r3=inactive
    legacy_main_enabled_fc_n2a_r3=masked

## Decision

Preserve job97 and job99 as stale failed evidence.

Do not retry job97 or job99 now.

Do not reset job97 or job99 now.

Do not manually mark job97 or job99 failed now.

Do not clear failed unit evidence in this stage.

Reason:

- qwen3:1.7b now has two stale/failed one-shot outcomes: job97 summary and job99 JSON.
- qwen2.5 completed the matching router and JSON probes; job98 JSON passed semantically.
- The qwen3 path needs a separate runtime diagnosis before more qwen3 work.
- Jobs100 through 104 do not depend on qwen3 and remain queued.

## Recommended next stage

Recommended next stage: `Stage 16 FC-N2B`.

Purpose:

- continue only queued jobs100 through 104,
- skip jobs97 and 99,
- preserve stale/failed evidence,
- tolerate exactly two preserved failed general_queue units,
- process one job at a time,
- run no scheduler,
- enable no persistent workers,
- drain no queue,
- verify default-off/no-active-runtime after each job,
- produce final FC-N model-tier matrix.

FC-N2B requires explicit approval because it will start one-shot timers and call local models.
