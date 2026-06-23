# Stage 16 FB-R4F install general_queue systemd templates no-runtime

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FB_R4F_INSTALL_GENERAL_QUEUE_SYSTEMD_TEMPLATES_NO_RUNTIME

## Base checkpoint

- Prior completed stage: Stage 16 FB-R4E.
- Base HEAD/origin/main: `75e84e3`.
- Base tag: `controller-stage-16-fb-r4e-general-queue-systemd-template-contract-no-apply-2026-06-22`.

## Mutation scope

FB-R4F installed separate CT101 general_queue systemd templates and ran daemon-reload.

It installed:

- `/etc/systemd/system/edge-ct101-general-queue-job-worker@.service`
- `/etc/systemd/system/edge-ct101-general-queue-job-worker@.timer`

It ran:

    systemctl daemon-reload

It did not:

- deploy the worker,
- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- retry jobs 53 through 58,
- process jobs 59 through 64,
- apply schema,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- restart CTs or VMs.

## Installed unit evidence

Exact-marker templates remained unchanged:

    exact_service_sha_after_general_units_install=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    exact_timer_sha_after_general_units_install=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390

General_queue templates installed:

    general_service_sha256_after_install=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d
    general_timer_sha256_after_install=c70c5495365b771d32ed787e35154c4bcb7c51bd8629d229ce87bdea937c766b
    general_service_mode_after_install=644
    general_timer_mode_after_install=644
    general_service_owner_after_install=root:root
    general_timer_owner_after_install=root:root

The general_queue service contains:

    EDGE_WORKER_MODE=general_queue
    EDGE_ALLOWED_JOB_IDS="$JOB_ID"

The general_queue timer invokes:

    Unit=edge-ct101-general-queue-job-worker@%i.service

## Default-off evidence

After install:

    general_service_enabled_after_install=static
    general_timer_enabled_after_install=disabled
    exact_service_enabled_after_general_units_install=static
    exact_timer_enabled_after_general_units_install=disabled
    active_exact_services_after_general_units_install=0
    active_exact_timers_after_general_units_install=0
    active_general_services_after_general_units_install=0
    active_general_timers_after_general_units_install=0
    edge_service_active_after_general_units_install=inactive
    edge_service_enabled_after_general_units_install=disabled
    legacy_main_active_after_general_units_install=inactive
    legacy_main_enabled_after_general_units_install=masked
    job58_service_active_after_general_units_install=inactive
    ct101_general_queue_units_install_acceptance_pass=true

CT101 worker remained deployed at sha:

    25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

Ollama remained running/healthy, but no model endpoint was called.

## CT203 preservation evidence

Read-only DB verification after unit install showed:

    quick_check_after_fb_r4f_general_units_install=ok
    jobs37_52_good_after_fb_r4f_general_units_install=16
    jobs57_64_existing_after_fb_r4f_general_units_install=8
    jobs57_64_completed_after_fb_r4f_general_units_install=1
    jobs57_64_running_after_fb_r4f_general_units_install=1
    jobs57_64_queued_after_fb_r4f_general_units_install=6
    jobs57_64_result_rows_after_fb_r4f_general_units_install=1
    ct203_preservation_after_fb_r4f_general_units_install_acceptance_pass=true

Job evidence remained unchanged:

- job 57 remains completed, attempts 1, result rows 1,
- job 58 remains running, attempts 1, result rows 0,
- jobs 59 through 64 remain queued, attempts 0, result rows 0.

## Result

CT101 now has two separated installed unit families:

- exact-marker proof units:
  - `edge-ct101-exact-job-worker@.service`
  - `edge-ct101-exact-job-worker@.timer`

- general_queue breadth units:
  - `edge-ct101-general-queue-job-worker@.service`
  - `edge-ct101-general-queue-job-worker@.timer`

Both timer families are disabled by default, and no timer or service is active.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R5A`.

Purpose: no-apply fresh corrected breadth batch contract for jobs 65 through 72.

Recommended runtime split remains:

- FB-R5A: no-apply contract for jobs 65 through 72,
- FB-R5B: approved insert-only for jobs 65 through 72,
- FB-R5C: approved serial runtime proof, job 65 via exact-marker template and jobs 66 through 72 via general_queue template.

No concurrency yet.
