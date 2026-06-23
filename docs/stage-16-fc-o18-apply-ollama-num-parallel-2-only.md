# Stage 16 FC-O18 apply Ollama NUM_PARALLEL=2 only

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O18_APPLY_OLLAMA_NUM_PARALLEL_2_ONLY_NO_PROFILE_CHANGE_NO_PERSISTENT_WORKER_NO_BULK_QUEUE_DRAIN

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O17.
- Base HEAD/origin/main: `3baf555`.
- Base tag: `controller-stage-16-fc-o17-bounded-ollama-concurrency-design-no-apply-2026-06-23`.

## Mutation boundary

This stage applied only the approved Ollama concurrency setting:

    OLLAMA_NUM_PARALLEL=2

It did not:

- change CT101 model profiles,
- change CT101 worker code,
- write CT203 DB,
- insert/reset/delete/retry jobs,
- process jobs,
- enable persistent workers,
- bulk drain the queue,
- reset job105,
- process jobs107-113,
- manually insert job_results,
- apply schema changes,
- start timers,
- enable services or timers,
- reset failed units,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- restart CTs or VMs,
- pull Docker images,
- call Ollama generation/model endpoints,
- pull models.

## Apply method

The Ollama container was managed by Docker Compose. FC-O18 added a Compose override file and recreated/restarted only the Ollama service/container through Compose.

    compose_override_path_fc_o18=/opt/llm-stack/compose.stage16-fc-o18-ollama-num-parallel-2.yml
    compose_override_sha_fc_o18=28d4d600697458511183011de2127bbd6d5283b125be99a943854dd68ba3c01c
    backup_dir_fc_o18=/root/stage16-fc-o18-ollama-num-parallel-2-20260623T163445Z

## Ollama container state

    ollama_container_id_before_fc_o18=e5506b82c47a
    ollama_container_id_after_fc_o18=2fca0c24a138
    ollama_container_state_after_fc_o18=running
    ollama_container_health_after_fc_o18=healthy

## Ollama environment

    OLLAMA_NUM_PARALLEL_before_fc_o18=1
    OLLAMA_NUM_PARALLEL_after_fc_o18=2
    OLLAMA_KEEP_ALIVE_after_fc_o18=30m

Unchanged by this stage:

    OLLAMA_MAX_LOADED_MODELS remains unset
    OLLAMA_MAX_QUEUE remains unset
    OLLAMA_CONTEXT_LENGTH remains unset

## CT101 posture

    profile_sha_before_fc_o18=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    profile_sha_after_fc_o18=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_before_fc_o18=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    worker_sha_after_fc_o18=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    active_exact_services_after_fc_o18=0
    active_exact_timers_after_fc_o18=0
    active_general_services_after_fc_o18=0
    active_general_timers_after_fc_o18=0
    failed_general_units_after_fc_o18=6
    ct101_fc_o18_apply_acceptance_pass=true

## CT203 no-job-processing check

    quick_check_after_fc_o18=ok
    job105_status_after_fc_o18=running
    job105_attempts_after_fc_o18=1
    job105_result_rows_after_fc_o18=0
    job106_status_after_fc_o18=completed
    job106_attempts_after_fc_o18=1
    job106_result_rows_after_fc_o18=1
    jobs107_111_remain_queued_attempts0_rows0=true
    job112_status_after_fc_o18=completed
    job112_result_rows_after_fc_o18=1
    job113_status_after_fc_o18=completed
    job113_result_rows_after_fc_o18=1
    ct203_post_fc_o18_no_job_processing_acceptance_pass=true

## Decision

Ollama NUM_PARALLEL is now 2.

CT203 remains the durable queue and claim authority.

Ollama still does not own durable job state.

Do not enable persistent workers or bulk queue draining yet.

The next stage should insert one fresh qwen3 proof job after the concurrency change, no runtime, then run only that fresh proof in a separate approval.
