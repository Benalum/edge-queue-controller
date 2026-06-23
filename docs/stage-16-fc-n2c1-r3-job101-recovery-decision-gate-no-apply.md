# Stage 16 FC-N2C1-R3 job101 recovery decision gate no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N2C1-R2.
- Base HEAD/origin/main: `5555212`.
- Base tag: `controller-stage-16-fc-n2c1-r2-job101-timeout-recovery-unknown-state-no-new-runtime-2026-06-22`.

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

    fc_n2c1_r2_evidence_verified_for_r3=true
    quick_check_fc_n2c1_r3=ok
    ct203_fc_n2c1_r3_read_only_acceptance_pass=true
    ct101_fc_n2c1_r3_failed_units_evidence_acceptance_pass=true

## Current FC-N state

| Job | Lane | Model | CT203 state | Attempts | Result rows | Semantic known? | Decision |
|---|---|---|---|---:|---:|---|---|
| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
| 97 | summary | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 99 | json_response | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 100 | companion_chat | gemma4:e4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 101 | companion_chat | gemma3:4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 102 | study_tutor | gemma4:e4b | queued | 0 | 0 | no | block until model runtime diagnosis |
| 103 | flashcards | gemma4:e4b | queued | 0 | 0 | no | block until model runtime diagnosis |
| 104 | safe_refusal | llama3.2:3b | queued | 0 | 0 | no | only remaining queued non-gemma/non-qwen3 probe |

## CT203 details

    job97_status_fc_n2c1_r3=running
    job97_result_rows_fc_n2c1_r3=0
    job99_status_fc_n2c1_r3=running
    job99_result_rows_fc_n2c1_r3=0
    job100_status_fc_n2c1_r3=running
    job100_result_rows_fc_n2c1_r3=0
    job101_status_fc_n2c1_r3=running
    job101_attempts_fc_n2c1_r3=1
    job101_result_rows_fc_n2c1_r3=0

    jobs95_99_completed_fc_n2c1_r3=3
    jobs95_99_running_fc_n2c1_r3=2
    jobs95_99_result_rows_fc_n2c1_r3=3
    jobs100_104_queued_fc_n2c1_r3=3
    jobs100_104_running_fc_n2c1_r3=2
    jobs100_104_completed_fc_n2c1_r3=0
    jobs100_104_failed_fc_n2c1_r3=0
    jobs100_104_result_rows_fc_n2c1_r3=0

## CT101 details

    active_exact_services_fc_n2c1_r3=0
    active_exact_timers_fc_n2c1_r3=0
    active_general_services_fc_n2c1_r3=0
    active_general_timers_fc_n2c1_r3=0
    failed_general_units_fc_n2c1_r3=4
    job97_service_state_fc_n2c1_r3=failed
    job99_service_state_fc_n2c1_r3=failed
    job100_service_state_fc_n2c1_r3=failed
    job101_service_state_fc_n2c1_r3=failed
    exact_timer_enabled_fc_n2c1_r3=disabled
    general_timer_enabled_fc_n2c1_r3=disabled
    edge_service_active_fc_n2c1_r3=inactive
    edge_service_enabled_fc_n2c1_r3=disabled
    legacy_main_active_fc_n2c1_r3=inactive
    legacy_main_enabled_fc_n2c1_r3=masked

## Decision

Preserve jobs97, 99, 100, and 101 as stale failed evidence.

Do not retry them now.

Do not reset them now.

Do not manually mark them failed now.

Do not clear failed unit evidence now.

Do not continue to gemma4 jobs102 or 103 until model runtime diagnosis exists.

Job104 remains the only queued, non-gemma/non-qwen3 FC-N probe. Running it may still be useful, but the system now has four preserved failed one-shot units and repeated non-qwen2.5 runtime failures. Treat job104 as optional final isolated probe, not productization evidence.

## Recommended next stage

Recommended next stage: `Stage 16 FC-N2D`.

Purpose:

- either run only job104 `llama3.2:3b` as a final isolated safe-refusal probe,
- or stop FC-N runtime and move to model-runtime diagnosis,
- skip jobs97, 99, 100, 101, 102, and 103,
- tolerate exactly four preserved failed general_queue units,
- run no scheduler,
- enable no persistent workers,
- drain no queue,
- verify default-off/no-active-runtime after job104 if run,
- produce a final FC-N partial model-tier matrix.

FC-N2D runtime requires explicit approval if job104 is run.
