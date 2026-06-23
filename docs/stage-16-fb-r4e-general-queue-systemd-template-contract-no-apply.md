# Stage 16 FB-R4E general_queue systemd template contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FB-R4D.
- Base HEAD/origin/main: `7e3a155`.
- Base tag: `controller-stage-16-fb-r4d-reset-failed-job58-service-only-no-runtime-2026-06-22`.

## Mutation boundary

This FB-R4E stage performed read-only CT101 unit inventory and repo doc/smoke only.

It did not:

- write CT101 unit files,
- deploy the worker,
- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- retry jobs 53 through 58,
- process jobs 59 through 64,
- apply schema,
- run daemon-reload,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- restart CTs or VMs.

## Read-only CT101 inventory

Worker state:

    ct101_worker_sha_fb_r4e_read_only=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

Existing exact-marker template state:

    exact_service=edge-ct101-exact-job-worker@.service
    exact_timer=edge-ct101-exact-job-worker@.timer
    exact_service_sha256_fb_r4e=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    exact_timer_sha256_fb_r4e=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390
    exact_timer_enabled_fb_r4e=disabled

General queue template state before install:

    general_service_exists_before_fb_r4e=false
    general_timer_exists_before_fb_r4e=false
    active_general_services_fb_r4e=0
    active_general_timers_fb_r4e=0

Default-off posture:

    active_exact_services_fb_r4e=0
    active_exact_timers_fb_r4e=0
    edge_service_active_fb_r4e=inactive
    edge_service_enabled_fb_r4e=disabled
    legacy_main_active_fb_r4e=inactive
    legacy_main_enabled_fb_r4e=masked
    ct101_fb_r4e_read_only_inventory_acceptance_pass=true

## General queue template goal

Future FB-R4F should install a separate general queue systemd template pair:

- `edge-ct101-general-queue-job-worker@.service`
- `edge-ct101-general-queue-job-worker@.timer`

The existing exact-marker templates must remain unchanged.

The new general queue service must set:

    EDGE_WORKER_MODE=general_queue

The new general queue service must keep the same strict one-job boundary:

    EDGE_ALLOWED_JOB_IDS=%i

The new general queue service must not enable persistent workers and must not broaden queue processing.

## Required general queue service properties

A future `edge-ct101-general-queue-job-worker@.service` should:

- be a one-shot service,
- run the deployed CT101 worker at `/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py`,
- set `EDGE_WORKER_MODE=general_queue`,
- set `EDGE_ALLOWED_JOB_IDS=%i`,
- preserve existing CT203 API/base URL environment behavior from exact-job service,
- preserve model profile environment behavior from exact-job service,
- preserve limited proof / default-off guard environment where applicable,
- not include broad queue dispatch,
- not start on boot,
- not be enabled by default,
- not mutate Docker,
- not call Ollama until a later explicit runtime stage starts a specific timer/service instance.

## Required general queue timer properties

A future `edge-ct101-general-queue-job-worker@.timer` should:

- invoke only `edge-ct101-general-queue-job-worker@.service`,
- remain disabled by default,
- have no persistent schedule enabled by default,
- be started only for a specific approved fresh job id,
- not reference the exact-marker service template,
- not trigger a broad queue drain.

## Future install stage boundary

Recommended future stage: `Stage 16 FB-R4F`.

FB-R4F may install the new general queue unit files and run daemon-reload, but must not process jobs.

FB-R4F requires explicit approval because it writes CT101 systemd unit files and runs daemon-reload.

FB-R4F must not:

- start any timer,
- start any service,
- enable any timer,
- enable any service,
- write CT203 DB,
- insert jobs,
- process jobs,
- call Ollama,
- mutate Docker,
- restart CTs or VMs.

## Future runtime after install

After FB-R4F installs units and verifies default-off posture, the corrected runtime proof should use fresh jobs 65 through 72.

Recommended split:

- FB-R5A: no-apply fresh corrected breadth batch contract for jobs 65 through 72.
- FB-R5B: approved insert-only for jobs 65 through 72.
- FB-R5C: approved serial runtime proof, job 65 via exact-marker template and jobs 66 through 72 via general queue template.

No concurrency yet.

## Evidence preservation

Current evidence remains locked:

- job 57: completed exact marker evidence,
- job 58: running failed evidence in DB but systemd failed marker cleared,
- jobs 59 through 64: queued evidence.

Do not reset, delete, manually complete, or silently retry them.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R4F`.

Purpose: install separate CT101 general_queue service/timer template pair, verify unit hashes/default-off posture, run daemon-reload if needed, and do no job processing.
