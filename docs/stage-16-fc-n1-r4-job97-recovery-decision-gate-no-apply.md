# Stage 16 FC-N1-R4 job97 recovery decision gate no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N1-R3.
- Base HEAD/origin/main: `35cf312`.
- Base tag: `controller-stage-16-fc-n1-r3-failed-unit-evidence-checkpoint-no-new-runtime-2026-06-22`.

## Mutation boundary

This stage is no-apply and read-only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- process any jobs,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
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

    fc_n1_r3_evidence_verified_for_r4=true
    quick_check_fc_n1_r4=ok
    ct203_fc_n1_r4_read_only_acceptance_pass=true
    ct101_fc_n1_r4_failed_unit_evidence_acceptance_pass=true

## Current FC-N1 state

| Job | Lane | Model | CT203 state | Attempts | Result rows | Semantic known? | Decision |
|---|---|---|---|---:|---:|---|---|
| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
| 97 | summary | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 98 | json_response | qwen2.5:0.5b | queued | 0 | 0 | no | eligible for later continuation |
| 99 | json_response | qwen3:1.7b | queued | 0 | 0 | no | eligible for later continuation |
| 100-104 | remaining lanes | mixed | queued | 0 | 0 | no | leave untouched for FC-N2 |

## CT203 details

    job95_status_fc_n1_r4=completed
    job95_result_rows_fc_n1_r4=1
    job95_semantic_pass_fc_n1_r4=true
    job96_status_fc_n1_r4=completed
    job96_result_rows_fc_n1_r4=1
    job96_semantic_pass_fc_n1_r4=false
    job97_status_fc_n1_r4=running
    job97_attempts_fc_n1_r4=1
    job97_result_rows_fc_n1_r4=0
    job98_status_fc_n1_r4=queued
    job99_status_fc_n1_r4=queued
    jobs95_99_completed_fc_n1_r4=2
    jobs95_99_queued_fc_n1_r4=2
    jobs95_99_running_fc_n1_r4=1
    jobs95_99_failed_fc_n1_r4=0
    jobs95_99_result_rows_fc_n1_r4=2
    jobs100_104_queued_fc_n1_r4=5
    jobs100_104_result_rows_fc_n1_r4=0

## CT101 details

    active_exact_services_fc_n1_r4=0
    active_exact_timers_fc_n1_r4=0
    active_general_services_fc_n1_r4=0
    active_general_timers_fc_n1_r4=0
    failed_general_units_fc_n1_r4=1
    job97_service_state_fc_n1_r4=failed
    job97_service_result_fc_n1_r4=exit-code
    job97_service_exec_status_fc_n1_r4=1
    exact_timer_enabled_fc_n1_r4=disabled
    general_timer_enabled_fc_n1_r4=disabled
    edge_service_active_fc_n1_r4=inactive
    edge_service_enabled_fc_n1_r4=disabled
    legacy_main_active_fc_n1_r4=inactive
    legacy_main_enabled_fc_n1_r4=masked

## Decision

Preserve job97 as stale failed evidence.

Do not retry job97 now.

Do not reset job97 now.

Do not manually mark job97 failed now.

Do not clear job97 failed unit evidence in this stage.

Reason:

- The failure involves a stronger model runtime path and should be preserved until we decide whether the issue is timeout, model profile, model runtime, worker deadline, or semantic/runtime incompatibility.
- Jobs98 and 99 are independent queued JSON probes and can be continued later without changing job97.
- Jobs100 through 104 are still queued and untouched.

## Recommended next stage

Recommended next stage: `Stage 16 FC-N2`.

Purpose:

- continue only queued jobs98 through 104,
- skip job97,
- preserve job97 stale/failed evidence,
- tolerate exactly one preserved failed general_queue unit,
- process one job at a time,
- run no scheduler,
- enable no persistent workers,
- drain no queue,
- verify default-off/no-active-runtime after each job,
- produce final FC-N matrix with job97 marked as stale failed evidence.

FC-N2 requires explicit approval because it will start one-shot timers and call local models.
