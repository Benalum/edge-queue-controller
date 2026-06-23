# Stage 16 E3Z-EX-R2 compatible-marker runtime success cleanup checkpoint

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EW.
- Base HEAD/origin/main: `86526b7`.
- Base tag: `controller-stage-16-e3z-ew-installed-unit-job55-compatible-marker-retry-contract-no-apply-2026-06-22`.

## Why this checkpoint exists

The first E3Z-EX runtime block exited early from the PPB wrapper path before documenting the result.

Read-only reconciliation showed that the runtime operation had actually completed successfully:

- fresh job 55 exists,
- job 55 is completed,
- job 55 attempts is 1,
- job 55 has exactly one result row,
- the response exactly matched `E3Z-EW-OK`,
- jobs 53 and 54 remained preserved as evidence,
- jobs 37 through 52 remained completed with one result row each.

The reconciliation also showed the job55 installed timer instance was still active, so this stage stopped only the exact job55 timer/service instance and then checkpointed the recovered success.

## Mutation scope used

This stage used:

- read-only CT203 DB verification,
- exact CT101 stop of `edge-ct101-exact-job-worker@55.timer`,
- exact CT101 stop of `edge-ct101-exact-job-worker@55.service`,
- repo doc/smoke/commit/tag/push.

This stage did not:

- write the CT203 DB,
- insert, reset, delete, or retry jobs,
- retry job 53,
- retry job 54,
- retry job 55,
- apply schema,
- write CT101 unit files,
- run daemon-reload,
- enable or disable templates,
- start any worker/timer,
- activate scheduler or persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama,
- pull models,
- restart CTs or VMs.

## Runtime result recovered

    job55_status_after_ex_reconcile=completed
    job55_attempts_after_ex_reconcile=1
    job55_result_rows_after_ex_reconcile=1
    job55_result_response_after_ex_reconcile=E3Z-EW-OK
    job55_result_response_sha_after_ex_reconcile=2a34b5fdc8772a2a06a097f3dddb5daa8c95bc829003c7079b784a980b4592f0
    job55_expected_response_sha=2a34b5fdc8772a2a06a097f3dddb5daa8c95bc829003c7079b784a980b4592f0

## Preserved evidence jobs

    job53_status_after_ex_reconcile=running
    job53_attempts_after_ex_reconcile=1
    job53_result_rows_after_ex_reconcile=0
    job54_status_after_ex_reconcile=running
    job54_attempts_after_ex_reconcile=1
    job54_result_rows_after_ex_reconcile=0

## Timer cleanup result

    timer55_active_before_cleanup=active
    timer55_active_after_cleanup=inactive
    active_exact_job_timers_after_cleanup=0
    ct101_cleanup_acceptance_pass=true

## Acceptance result

E3Z-EX-R2 passed as a recovered runtime success checkpoint.

Job 55 completed successfully with exactly one result row and exact response `E3Z-EW-OK`.

Jobs 53 and 54 remained preserved as failed-proof evidence.

The job55 timer/service instance was returned to default-off posture:

- job55 timer inactive and disabled,
- job55 service inactive with result success,
- no exact-job services active,
- no exact-job timers active,
- permanent CT101 worker inactive/disabled,
- installed timer template disabled,
- Ollama running/healthy.

## Installed-unit proof result

E3Z-EX proves that the installed-unit one-tick CT101 worker path can complete a fresh queued job when using the marker-extraction-compatible prompt:

    Return exactly this text and nothing else: E3Z-EW-OK

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-EY`.

Purpose: no-apply repeatability contract for a final fresh installed-unit proof using the same compatible prompt shape, preserving jobs 53 and 54 as failed evidence and job 55 as the recovered success evidence.
