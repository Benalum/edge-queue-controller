# Stage 16 FC-N2B1-R4 job100 recovery decision gate no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-N2B1-R3.
- Base HEAD/origin/main: `1b6ef39`.
- Base tag: `controller-stage-16-fc-n2b1-r3-job100-timeout-recovery-no-new-runtime-2026-06-22`.

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

    fc_n2b1_r3_evidence_verified_for_r4=true
    quick_check_fc_n2b1_r4=ok
    ct203_fc_n2b1_r4_read_only_acceptance_pass=true
    ct101_fc_n2b1_r4_failed_units_evidence_acceptance_pass=true

## Current FC-N state

| Job | Lane | Model | CT203 state | Attempts | Result rows | Semantic known? | Decision |
|---|---|---|---|---:|---:|---|---|
| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 | false | keep evidence |
| 97 | summary | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |
| 99 | json_response | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 100 | companion_chat | gemma4:e4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |
| 101 | companion_chat | gemma3:4b | queued | 0 | 0 | no | eligible only after decision |
| 102 | study_tutor | gemma4:e4b | queued | 0 | 0 | no | block until gemma4 diagnosis |
| 103 | flashcards | gemma4:e4b | queued | 0 | 0 | no | block until gemma4 diagnosis |
| 104 | safe_refusal | llama3.2:3b | queued | 0 | 0 | no | eligible only after decision |

## CT203 details

    job97_status_fc_n2b1_r4=running
    job97_result_rows_fc_n2b1_r4=0
    job99_status_fc_n2b1_r4=running
    job99_result_rows_fc_n2b1_r4=0
    job100_status_fc_n2b1_r4=running
    job100_attempts_fc_n2b1_r4=1
    job100_result_rows_fc_n2b1_r4=0

    jobs95_99_completed_fc_n2b1_r4=3
    jobs95_99_running_fc_n2b1_r4=2
    jobs95_99_result_rows_fc_n2b1_r4=3
    jobs100_104_queued_fc_n2b1_r4=4
    jobs100_104_running_fc_n2b1_r4=1
    jobs100_104_completed_fc_n2b1_r4=0
    jobs100_104_failed_fc_n2b1_r4=0
    jobs100_104_result_rows_fc_n2b1_r4=0

## CT101 details

    active_exact_services_fc_n2b1_r4=0
    active_exact_timers_fc_n2b1_r4=0
    active_general_services_fc_n2b1_r4=0
    active_general_timers_fc_n2b1_r4=0
    failed_general_units_fc_n2b1_r4=3
    job97_service_state_fc_n2b1_r4=failed
    job99_service_state_fc_n2b1_r4=failed
    job100_service_state_fc_n2b1_r4=failed
    exact_timer_enabled_fc_n2b1_r4=disabled
    general_timer_enabled_fc_n2b1_r4=disabled
    edge_service_active_fc_n2b1_r4=inactive
    edge_service_enabled_fc_n2b1_r4=disabled
    legacy_main_active_fc_n2b1_r4=inactive
    legacy_main_enabled_fc_n2b1_r4=masked

## Decision

Preserve job97, job99, and job100 as stale failed evidence.

Do not retry them now.

Do not reset them now.

Do not manually mark them failed now.

Do not clear failed unit evidence now.

Do not continue to gemma4 jobs102 or 103 until there is a separate gemma4 runtime diagnosis.

Reason:

- qwen3:1.7b has two stale/failed one-shot outcomes.
- gemma4:e4b now has one stale/failed one-shot outcome on companion job100.
- The remaining gemma4 jobs102 and 103 are likely to hit the same runtime path.
- Jobs101 and 104 use different models and may still be useful probes, but continuing requires a narrowed approval that skips qwen3 and gemma4 evidence jobs.

## Recommended next stage

Recommended next stage: `Stage 16 FC-N2C`.

Purpose:

- continue only job101 `gemma3:4b` and job104 `llama3.2:3b`,
- skip jobs97, 99, and 100,
- skip gemma4 jobs102 and 103,
- tolerate exactly three preserved failed general_queue units,
- process one job at a time,
- run no scheduler,
- enable no persistent workers,
- drain no queue,
- verify default-off/no-active-runtime after each job,
- produce a final FC-N partial model-tier matrix.

FC-N2C requires explicit approval because it will start one-shot timers and call local models.
