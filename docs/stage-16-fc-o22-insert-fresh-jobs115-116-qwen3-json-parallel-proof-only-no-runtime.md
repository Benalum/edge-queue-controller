# Stage 16 FC-O22 insert fresh jobs115-116 qwen3 JSON parallel proof only no-runtime

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O22_INSERT_FRESH_JOBS115_116_QWEN3_JSON_PARALLEL_PROOF_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O21.
- Base HEAD/origin/main: `4e56bd8`.
- Base tag: `controller-stage-16-fc-o21-two-job-qwen3-parallel-proof-design-no-apply-2026-06-23`.

## Mutation boundary

This stage mutated only the CT203 DB by inserting two fresh queued qwen3 JSON parallel proof jobs: jobs115 and 116.

It did not:

- run jobs115 or 116,
- process jobs,
- reset, retry, delete, or manually complete job105,
- mutate jobs106-114,
- create job_results rows,
- apply schema changes,
- mutate CT101 profile,
- mutate CT101 worker code,
- mutate Ollama concurrency,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- mutate Docker,
- call Ollama generation/model endpoints,
- pull models,
- restart CTs or VMs.

## DB backup

    db_backup_path_fc_o22=/var/lib/edge-queue-controller/stage16-fc-backups/edge_queue.sqlite3.stage16-fc-o22-pre-jobs115-116-insert.20260623T164929Z.bak
    db_backup_sha_fc_o22=802fc69fc6d3bccbfd5c2cc3c1c276e0d63543cb6812dcc395de1a4feb220018

## Inserted fresh jobs

| Job | Source | Job type | Model | Status | Attempts | Result rows |
|---:|---:|---|---|---|---:|---:|
| 115 | 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |
| 116 | 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |

## Verification

    quick_check_before_fc_o22=ok
    quick_check_after_fc_o22=ok
    inserted_job_ids_fc_o22=115,116
    job115_status_fc_o22=queued
    job115_attempts_fc_o22=0
    job115_result_rows_fc_o22=0
    job116_status_fc_o22=queued
    job116_attempts_fc_o22=0
    job116_result_rows_fc_o22=0
    max_job_id_after_fc_o22=116
    ct203_fc_o22_insert_acceptance_pass=true

## Preserved state

    job105_status_after_fc_o22=running
    job105_attempts_after_fc_o22=1
    job105_result_rows_after_fc_o22=0
    job106_status_after_fc_o22=completed
    job106_attempts_after_fc_o22=1
    job106_result_rows_after_fc_o22=1
    jobs107_111_remain_queued_attempts0_rows0=true
    job112_status_after_fc_o22=completed
    job112_result_rows_after_fc_o22=1
    job113_status_after_fc_o22=completed
    job113_result_rows_after_fc_o22=1
    job114_status_after_fc_o22=completed
    job114_result_rows_after_fc_o22=1

## CT101/Ollama default-off posture

    profile_sha_fc_o22=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_fc_o22=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    ollama_container_state_fc_o22=running
    ollama_container_health_fc_o22=healthy
    OLLAMA_NUM_PARALLEL_fc_o22=2
    OLLAMA_KEEP_ALIVE_fc_o22=30m
    active_exact_services_fc_o22=0
    active_exact_timers_fc_o22=0
    active_general_services_fc_o22=0
    active_general_timers_fc_o22=0
    failed_general_units_fc_o22=6
    ct101_fc_o22_read_only_acceptance_pass=true

## Decision

Fresh qwen3 JSON parallel proof jobs115 and 116 are queued.

Do not run bulk jobs.

Do not enable persistent workers.

The next stage should run only jobs115 and 116 by starting exactly these two service instances back-to-back:

    edge-ct101-general-queue-job-worker@115.service
    edge-ct101-general-queue-job-worker@116.service

That runtime proof must use separate explicit approval.
