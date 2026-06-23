# Stage 16 E3Z-EZ-R2 installed-unit repeatability recovered success checkpoint

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EY.
- Base HEAD/origin/main: `8a847ba`.
- Base tag: `controller-stage-16-e3z-ey-installed-unit-job56-repeatability-contract-no-apply-2026-06-22`.

## Why this checkpoint exists

E3Z-EZ performed the approved installed-unit repeatability runtime proof for fresh job 56.

The original runtime PPB block timed out after:

- repo guard passed,
- CT203 preflight passed,
- CT203 backup was created,
- fresh job 56 was inserted,
- PVESO/CT101 route was found,
- CT101 installed-unit preflight passed,
- the exact job56 installed timer was started,
- the job56 service began activating.

A follow-up recovery/reconciliation stage stopped only the exact job56 timer/service instance and verified the runtime result.

## Mutation scope recovered from E3Z-EZ

The E3Z-EZ runtime attempt used:

- one CT203 DB backup,
- one fresh job56 insert,
- one installed CT101 timer instance start for job56,
- one installed CT101 service instance for job56,
- one Ollama model call through the worker path.

The recovery/reconciliation used:

- exact stop of `edge-ct101-exact-job-worker@56.timer`,
- exact stop of `edge-ct101-exact-job-worker@56.service`,
- read-only CT203 DB verification,
- no repo commit until this checkpoint.

The recovery/reconciliation did not:

- write the CT203 DB,
- insert, reset, delete, manually complete, or retry jobs,
- retry job 53,
- retry job 54,
- retry job 55,
- retry job 56,
- apply schema,
- write CT101 unit files,
- run daemon-reload,
- enable or disable templates,
- activate scheduler or persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama,
- pull models,
- restart CTs or VMs.

## Fresh job contract

- Fresh job id: `56`.
- Marker: `E3Z-EY-OK`.
- Prompt: `Return exactly this text and nothing else: E3Z-EY-OK`.
- Requested model: `qwen2.5:0.5b`.
- Job type: `stage16_e3z_limited_persistent_worker_repeat_proof`.
- Prompt sha256: `7e6c4b8b777a78db6f8d2dce9772ad267a93a1511e78a048892bda23954b7684`.
- Expected response sha256: `64dc41fc92efb21ebdb29be384e1249946e47716af6dbcf018a9ac2c8ce51a85`.

## Pre-run backup

- Backup path: `/var/lib/edge-queue-controller/stage16-ez-backups/edge_queue.sqlite3.stage16-e3z-ez-pre-fresh-job56-insert.20260623T012907Z.bak`.
- Backup sha256: `36cefb2faad459438a25d8007db0bb0222d45c78b91e201b517a742eac60abd7`.
- Backup size bytes: `43823104`.

## Timeout point

The runtime PPB block timed out during the installed timer proof after these observed lines:

    timer_start_rc=0
    poll=1 timer_active=active service_active=inactive service_result=success exec_status=0
    poll=2 timer_active=active service_active=inactive service_result=success exec_status=0
    poll=3 timer_active=active service_activ...

The timeout reset the tmux session before the original runtime block could checkpoint the result.

## CT101 recovery result

Recovery/reconciliation observed before cleanup:

    timer56_active_before_cleanup=active
    timer56_enabled_before_cleanup=disabled
    timer56_unit_file_state_before_cleanup=disabled
    service56_active_before_cleanup=inactive
    service56_enabled_before_cleanup=static
    service56_unit_file_state_before_cleanup=static
    service56_result_before_cleanup=success
    service56_exec_status_before_cleanup=0

Recovery stopped only the exact job56 timer/service instances:

    stop_timer56_rc=0
    stop_service56_rc=0

Recovery/reconciliation observed after cleanup:

    timer56_active_after_cleanup=inactive
    timer56_enabled_after_cleanup=disabled
    timer56_unit_file_state_after_cleanup=disabled
    service56_active_after_cleanup=inactive
    service56_enabled_after_cleanup=static
    service56_unit_file_state_after_cleanup=static
    service56_result_after_cleanup=success
    service56_exec_status_after_cleanup=0
    edge_service_active_after_cleanup=inactive
    edge_service_enabled_after_cleanup=disabled
    legacy_main_active_after_cleanup=inactive
    legacy_main_enabled_after_cleanup=masked
    legacy_tiny_enabled_after_cleanup=masked
    legacy_small_enabled_after_cleanup=masked
    active_exact_job_services_after_cleanup=0
    active_exact_job_timers_after_cleanup=0
    service_template_enabled_after_cleanup=static
    timer_template_enabled_after_cleanup=disabled
    ollama_after_cleanup_container_status=running health=healthy restart_count=0
    ct101_cleanup_acceptance_pass=true

## CT101 journal evidence

The job56 service journal showed:

    Starting edge-ct101-exact-job-worker@56.service - AI Platform Control CT101 exact-job Ollama worker (56)...
    Started edge-ct101-exact-job-worker@56.service - AI Platform Control CT101 exact-job Ollama worker (56).
    edge-ct101-exact-job-worker@56.service: Deactivated successfully.

## CT203 recovered DB result

Read-only DB verification after cleanup showed:

    quick_check_after_ez_timeout_cleanup=ok
    jobs_37_52_seen_after_ez_timeout_cleanup=16
    jobs_37_52_completed_with_one_result_after_ez_timeout_cleanup=16
    job53_status_after_ez_timeout_cleanup=running
    job53_attempts_after_ez_timeout_cleanup=1
    job53_result_rows_after_ez_timeout_cleanup=0
    job54_status_after_ez_timeout_cleanup=running
    job54_attempts_after_ez_timeout_cleanup=1
    job54_result_rows_after_ez_timeout_cleanup=0
    job55_status_after_ez_timeout_cleanup=completed
    job55_attempts_after_ez_timeout_cleanup=1
    job55_result_rows_after_ez_timeout_cleanup=1
    job55_response_after_ez_timeout_cleanup=E3Z-EW-OK
    job55_response_sha_after_ez_timeout_cleanup=2a34b5fdc8772a2a06a097f3dddb5daa8c95bc829003c7079b784a980b4592f0
    job56_status_after_ez_timeout_cleanup=completed
    job56_attempts_after_ez_timeout_cleanup=1
    job56_result_rows_after_ez_timeout_cleanup=1
    job56_response_after_ez_timeout_cleanup=E3Z-EY-OK
    job56_response_sha_after_ez_timeout_cleanup=64dc41fc92efb21ebdb29be384e1249946e47716af6dbcf018a9ac2c8ce51a85
    max_job_id_after_ez_timeout_cleanup=56
    job56_exact_marker_after_ez_timeout_cleanup=true
    ez_recovered_success_candidate=true

## Acceptance result

E3Z-EZ-R2 passed as a recovered repeatability success checkpoint.

Job 56 completed successfully with exactly one result row and exact response `E3Z-EY-OK`.

Preserved evidence state:

- job 53: running, attempts 1, result rows 0,
- job 54: running, attempts 1, result rows 0,
- job 55: completed, attempts 1, result rows 1, response `E3Z-EW-OK`,
- job 56: completed, attempts 1, result rows 1, response `E3Z-EY-OK`.

Jobs 37 through 52 remained completed with exactly one result row each.

The installed timer/service path returned to default-off posture:

- job56 timer inactive and disabled,
- job56 service inactive/static with result success,
- no exact-job services active,
- no exact-job timers active,
- permanent CT101 worker inactive/disabled,
- legacy laptop worker units inactive/masked,
- installed timer template disabled,
- Ollama running/healthy.

## Installed-unit repeatability proof result

E3Z-EZ-R2 proves installed-unit repeatability after E3Z-EX-R2:

- E3Z-EX-R2 completed job 55 with exact compatible-marker response `E3Z-EW-OK`.
- E3Z-EZ-R2 completed job 56 with exact compatible-marker response `E3Z-EY-OK`.
- Both proofs used the installed CT101 timer/service path.
- Both proofs preserved failed evidence jobs 53 and 54.
- Both proofs returned CT101 exact-job runtime posture to default-off.

## Next recommended stage

Recommended next stage: `Stage 16 FA`.

Purpose: define the queue breadth and model-routing matrix contract, no-apply, before running multiple request types or any concurrency tests.
