# Stage 16 E3U-A — Scheduler-Controlled Dispatch Runtime Plan, No Apply

## Purpose

E3U-A defines the next runtime boundary after E3S/E3T.

E3S proved a scheduler dry-run artifact can read CT203 DB read-only and identify the job it would claim.

E3T inserted one fresh eligible queued scheduler-test job.

E3S-R4 proved the dry-run would select that job:

    WOULD_CLAIM job_id=28

E3U should be the first scheduler-controlled dispatch runtime smoke, but this E3U-A document is no-apply only.

## Current baseline

    HEAD/origin/main: f03650f
    Previous tag: controller-stage-16-e3t-c-e3s-r4-insert-and-read-only-would-claim-result-2026-06-21
    Working tree before E3U-A: clean

## Current CT203 DB state

    jobs=27
    job_results=9
    job 28 status=queued
    job 28 attempts=0
    job 28 result rows=0
    job 28 model=qwen2.5:32b-instruct-q4_K_M
    job 28 prompt=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE

## Current scheduler posture

Scheduler activation has not been performed.

Persistent worker activation has not been performed.

Lane worker activation has not been performed.

E3U must not turn on a persistent scheduler or persistent worker.

## E3U runtime goal

The future E3U apply phase should dispatch exactly one scheduler-selected job through the already-proven controlled dispatch path:

    CT203 queued job 28
    scheduler selection boundary
    controlled operator dispatch artifact
    manual helper
    PVESO one-shot adapter
    localhost-only Ollama on PVESO
    CT203 DB completion

The target job is job 28 only.

Do not reuse job 27.

## Required approval phrase

The future E3U runtime apply phase requires this exact approval phrase:

    APPROVE_STAGE_16_E3U_RUN_ONE_SCHEDULER_CONTROLLED_DISPATCH_FOR_JOB_28_ONLY

## Allowed only after approval

After explicit approval, E3U may perform exactly one runtime attempt for job 28:

- classify CT203 DB before execution
- verify job 28 is queued
- verify job 28 has zero result rows
- verify job 28 matches the E3T marker
- verify the E3S dry-run would claim job 28
- verify PVESO Ollama is localhost-only
- verify CT101 is stopped/onboot=0
- run one controlled dispatch for job 28
- verify job 28 completes exactly once
- verify exactly one result row for job 28
- verify job_results increments by one
- verify no duplicate result rows
- verify PVESO runner count returns to zero
- document the run directory and result markers

## Denied even after approval

The E3U approval does not allow:

- persistent scheduler activation
- persistent worker activation
- lane worker activation
- reuse of job 27
- a second run for job 28
- dispatch of jobs 23 or 24
- broad queue draining
- schema migration
- claim/lease schema apply unless separately approved
- service start/stop/restart/reload/enable/disable
- CT/VM start/stop/restart/config mutation
- CT101 start
- PVESO/Ollama public exposure
- Cloudflare/DNS/nginx/private-storage mutation
- GitHub branch/repo deletion

## Required preflight before E3U runtime

Before execution, E3U must classify state read-only:

- repo HEAD/origin/remote/tag/dirty status
- CT203 DB integrity
- total jobs
- total job_results
- job 28 status
- job 28 attempts
- job 28 result row count
- job 28 requested_model
- job 28 prompt marker
- queued job inventory
- E3S dry-run still selects job 28
- PVESO Ollama service/listener state
- PVESO non-localhost 11434 listener count is zero
- PVESO runner count before execution is zero
- CT101 status is stopped
- CT101 onboot is 0

## Required runtime constraints

The future E3U runtime must be one-shot and job-id-guarded.

It must refuse unless:

    target_job_id=28
    job_status=queued
    result_rows_for_job_28=0
    requested_model=qwen2.5:32b-instruct-q4_K_M
    prompt contains APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE
    E3S dry-run WOULD_CLAIM job_id=28
    PVESO Ollama listens only on 127.0.0.1:11434
    CT101 is stopped and onboot=0

## Timeout/recovery rule

If E3U runtime times out, do not rerun immediately.

Run read-only recovery first:

- CT203 job 28 status
- CT203 job 28 result row count
- CT203 total job_results
- PVESO runner count
- PVESO Ollama listener state
- run directory artifacts
- CT101 status/onboot

If job 28 completed with one result row, document success and do not rerun.

If job 28 remains queued with zero result rows and PVESO runner count is zero, rerun only after a new explicit approval.

If PVESO runner count is nonzero, do not rerun.

## Expected success result

The future successful E3U runtime should end with:

    job 28 status=completed
    job 28 attempts=1
    job 28 result rows=1
    job_results total=10
    PVESO runner count after completion=0
    CT101 status=stopped
    CT101 onboot=0

## Source-of-truth rule

CT203 DB remains the source of truth.

Frontend users do not call models directly.

PVESO/Ollama remains private and localhost-only.
