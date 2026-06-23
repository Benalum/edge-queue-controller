# Stage 16 FB-R4C deploy updated CT101 worker file only no-runtime

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FB_R4C_DEPLOY_UPDATED_CT101_WORKER_FILE_ONLY_NO_RUNTIME

## Base checkpoint

- Prior completed stage: Stage 16 FB-R4B.
- Base HEAD/origin/main: `2c6e82b`.
- Base tag: `controller-stage-16-fb-r4b-ct101-general-queue-worker-deployment-contract-no-apply-2026-06-22`.

## Mutation scope

FB-R4C deployed the updated worker file to CT101 only.

It did:

- verify repo worker sha,
- copy repo worker to PVESO temp path,
- verify PVESO temp sha,
- verify CT101 old worker sha before deploy,
- create a CT101 backup of the old worker,
- install updated worker at `/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py`,
- verify new CT101 worker sha,
- verify Python compile on CT101,
- verify default-off worker/timer posture,
- perform read-only CT203 DB preservation check,
- commit/tag/push this evidence.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- retry jobs 53 through 58,
- process jobs 59 through 64,
- apply schema,
- write systemd unit files,
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

## Worker deploy evidence

- Local repo worker sha: `25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca`.
- Old CT101 worker expected sha: `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
- New CT101 worker expected sha: `25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca`.
- CT101 backup path: `/opt/edge-queue-controller/stage16-fb-r4c-worker-backups/ct101_minimal_ollama_worker.py.pre-fb-r4c.20260623T020140Z.bak`.
- CT101 backup sha: `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
- CT101 worker sha after deploy: `25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca`.

Acceptance:

    ct101_pre_deploy_default_off_acceptance_pass=true
    ct101_worker_deploy_acceptance_pass=true
    ct101_post_deploy_default_off_acceptance_pass=true

## CT101 default-off evidence

After deployment:

    edge_service_active_after_deploy=inactive
    edge_service_enabled_after_deploy=disabled
    legacy_main_active_after_deploy=inactive
    legacy_main_enabled_after_deploy=masked
    legacy_tiny_enabled_after_deploy=masked
    legacy_small_enabled_after_deploy=masked
    active_exact_job_services_after_deploy=0
    active_exact_job_timers_after_deploy=0
    timer_template_enabled_after_deploy=disabled
    job58_service_active_after_deploy=failed
    job58_service_result_after_deploy=exit-code

Job58 failed systemd state remains preserved. No reset-failed was performed.

## CT203 preservation evidence

Read-only DB verification after deploy showed:

    quick_check_after_fb_r4c_deploy=ok
    jobs37_52_good_after_fb_r4c_deploy=16
    jobs57_64_existing_after_fb_r4c_deploy=8
    jobs57_64_completed_after_fb_r4c_deploy=1
    jobs57_64_running_after_fb_r4c_deploy=1
    jobs57_64_queued_after_fb_r4c_deploy=6
    jobs57_64_result_rows_after_fb_r4c_deploy=1
    ct203_preservation_after_fb_r4c_deploy_acceptance_pass=true

## Result

CT101 now has the updated worker source containing `EDGE_WORKER_MODE=general_queue`.

This still does not activate general queue runtime. The installed exact-job service/timer templates remain unchanged, and no worker/timer/service was started.

## Evidence preservation

Current evidence remains locked:

- job 57: completed exact marker evidence,
- job 58: running failed evidence,
- jobs 59 through 64: queued evidence.

Do not reset, delete, manually complete, or silently retry them.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R4D`.

Purpose: cleanup-only reset-failed for `edge-ct101-exact-job-worker@58.service`, with no DB change, no job retry, no service/timer start, and no model call.

After FB-R4D, define/install separate general queue service/timer templates in FB-R4E.
