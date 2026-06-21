# Stage 16 E3T-A — Fresh Scheduler-Test Job Insert Plan, No Apply

## Purpose

E3T-A defines the next runtime-adjacent step without performing it.

The future E3T apply phase will insert exactly one fresh queued scheduler-test job into the CT203 DB so the E3S scheduler dry-run artifact can prove it would select one eligible job.

This document is no-apply only.

## Current baseline

    HEAD/origin/main: e930967
    Previous tag: controller-stage-16-e3s-r3-ct203-read-only-dry-run-result-docs-2026-06-21
    Working tree before E3T-A: clean

## Why E3T is needed

E3S-R2 inspected the live CT203 DB read-only and found two queued jobs:

    job 23 requested_model=gemma4:e4b
    job 24 requested_model=mock/no-model

Both were rejected by the current E3S allowlist, so the dry-run correctly printed:

    ELIGIBLE_WOULD_CLAIM_COUNT=0
    WOULD_CLAIM none

E3T should create one fresh queued job that is intentionally eligible for the E3S dry-run allowlist.

## Future E3T apply boundary

The future apply phase requires explicit approval because it writes to the CT203 DB.

Required approval phrase:

    APPROVE_STAGE_16_E3T_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_ONLY

Allowed only after approval:

- insert one fresh queued scheduler-test job into CT203 DB
- verify exactly one new job row
- verify zero result rows for the new job
- verify job status is queued
- verify DB integrity is ok
- document the new job id

Denied even after E3T approval:

- scheduler activation
- DB claim
- claim/lease write
- helper call
- adapter call
- operator dispatch call
- model call
- job completion
- job_result insert
- persistent worker activation
- lane worker activation
- CT101 start
- service/CT/VM/Cloudflare/private-storage mutation
- reuse of job 27

## Proposed future queued job shape

The future E3T apply phase should create a single queued job with the smallest useful payload.

Recommended values:

    status: queued
    job_type: stage16_e3t_scheduler_dry_run_eligible_model_smoke
    requested_model: qwen2.5:32b-instruct-q4_K_M
    worker_lane/job_lane/lane: model
    prompt/input marker: APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE

The exact column mapping must be discovered read-only from the live CT203 schema before inserting.

## Future E3T apply preflight

Before any insert, classify the CT203 DB read-only:

- jobs count
- job_results count
- DB integrity
- jobs table columns
- existing queued jobs
- current max job id
- absence of any existing E3T marker job

The apply must refuse if an E3T marker job already exists.

## Future E3T apply postflight

After insertion, verify:

- exactly one new job row
- new job has status queued
- new job has zero result rows
- DB integrity remains ok
- no helper/adapter/operator/model path was called
- scheduler remains inactive
- persistent workers remain inactive

## Expected E3S follow-up

After E3T inserts a fresh eligible queued job, E3S-R4 should run the already committed scheduler dry-run artifact read-only again.

Expected result:

    ELIGIBLE_WOULD_CLAIM_COUNT=1
    WOULD_CLAIM job_id=<new_e3t_job_id>
    NO_DB_WRITE

The DB stat before/after the E3S-R4 dry-run should remain unchanged.

## Do-not-rerun rule

Do not reuse job 27.

Job 27 is closed and completed exactly once from E3P-D-R7.
