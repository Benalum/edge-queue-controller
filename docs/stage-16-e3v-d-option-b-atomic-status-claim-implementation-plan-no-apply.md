# Stage 16 E3V-D — Option B Atomic-Status-Claim Implementation Plan, No Apply

## Purpose

E3V-D defines the no-apply implementation plan for the near-term Option B scheduler-controlled lane:

    atomic status transition claim using existing DB fields

This phase does not apply the design.

No DB write is performed.

No job is claimed.

No helper, adapter, model, scheduler, or worker action is performed.

## Baseline

E3U-C2 proved one scheduler-selected controlled dispatch:

    job_28_status=completed
    job_28_attempts=1
    job_28_result_rows=1
    job_results_total=10
    pveso_runner_count_after=0

E3V-B recommended:

    near-term path: Option B atomic status transition claim using existing fields
    long-term path: Option C dedicated lease columns before persistent scheduler activation

E3V-C confirmed the live schema can support the near-term Option B design without schema migration:

    OPTION_B_SCHEMA_CAPABLE=true
    OPTION_B_REQUIRED_COLUMNS_PRESENT=True
    OPTION_B_REQUIRED_COLUMNS_MISSING=none
    JOB_RESULTS_HAS_JOB_ID_COLUMN=true
    OPTION_C_LEASE_COLUMNS_PRESENT=none
    OPTION_C_MIGRATION_REQUIRED_FOR_DEDICATED_LEASE=true

## Current known live DB state

Current counts after E3U-C2 and E3V-C:

    JOBS_TOTAL=27
    JOB_RESULTS_TOTAL=10

Current important job states:

    job 23: queued, attempts=3, requested_model=gemma4:e4b, result_rows=0
    job 24: queued, attempts=0, requested_model=mock/no-model, result_rows=0
    job 27: completed, attempts=1, result_rows=1
    job 28: completed, attempts=1, result_rows=1

Do not dispatch job 23.

Do not dispatch job 24.

Do not rerun job 27.

Do not rerun job 28.

## Design boundary

Option B is allowed only as a future one-shot, explicitly approved, scheduler-selected model dispatch.

It is not a persistent scheduler activation.

It is not persistent worker activation.

It is not a broad queue drain.

It is not a schema migration.

It is not the long-term lease design.

## Key implementation issue

The existing helper path was proven for queued jobs.

Option B changes the selected job status from queued to running before model dispatch.

Therefore the future apply must either:

1. add a claim-aware helper mode that accepts a pre-claimed running job, or
2. add a new controlled completion function for already-claimed jobs, or
3. perform claim and completion inside one tightly guarded wrapper that owns both steps.

The future apply must not blindly reuse the old helper if that helper requires status=queued after the claim.

## Recommended implementation shape

Recommended near-term implementation:

    create a new one-shot wrapper for E3V Option B

Suggested path:

    ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh

The wrapper should:

1. verify repo checkpoint
2. verify explicit approval phrase
3. verify scheduler and persistent workers are disabled
4. verify CT101 is stopped and onboot=0
5. verify PVESO Ollama is active on 127.0.0.1:11434 only
6. run the E3S scheduler selection gate read-only
7. require exactly one eligible scheduler-selected queued job
8. refuse jobs 23, 24, 27, and 28
9. atomically claim the selected job with status transition to running
10. run the PVESO one-shot adapter for that claimed job
11. complete exactly the claimed job
12. insert exactly one job_results row
13. verify no duplicate result row
14. verify PVESO runner count returns to zero
15. write durable run artifacts and recovery hint
16. refuse immediate rerun after timeout

## Future approval phrase

The future runtime apply must require this exact approval phrase:

    APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY

That approval should allow at most:

- one scheduler-selected eligible queued job
- one atomic status transition claim
- one helper or claim-aware completion path
- one adapter call
- one localhost-only PVESO model call
- one CT203 job completion
- one CT203 job_results insert

It must still deny:

- schema migration
- persistent scheduler activation
- persistent worker activation
- broad queue draining
- job 23 dispatch
- job 24 dispatch
- job 27 reuse
- job 28 rerun
- CT101 start
- PVESO/Ollama public exposure
- service/CT/VM/Cloudflare/private-storage mutation

## Atomic claim SQL

The candidate atomic claim SQL shape is:

    UPDATE jobs
    SET status='running',
        attempts=attempts+1,
        updated_at=?
    WHERE id=?
      AND status='queued'
      AND requested_model=?
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=?
      )

The wrapper must run the claim in a transaction.

Recommended transaction shape:

    BEGIN IMMEDIATE;
    UPDATE jobs
    SET status='running',
        attempts=attempts+1,
        updated_at=:now
    WHERE id=:job_id
      AND status='queued'
      AND requested_model=:expected_model
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=:job_id
      );
    SELECT changes();
    COMMIT;

The wrapper must require:

    changes() == 1

If changes() is zero, the wrapper must classify and exit without model dispatch.

## Status values

Near-term Option B should use:

    queued
    running
    completed
    failed

The atomic claim changes:

    queued -> running

Successful completion changes:

    running -> completed

Failure classification may change:

    running -> failed

Timeout is special and must not automatically mark failed unless the wrapper has proven the model call failed and no DB completion occurred.

## Attempts behavior

Attempts should increment exactly once during atomic claim:

    attempts=attempts+1

Completion must not increment attempts again.

If claim succeeds and model dispatch later fails, the attempt has already been consumed.

If claim fails with changes() == 0, attempts must not change.

## Completion SQL shape

The completion step must only complete the already-claimed job.

Candidate shape:

    UPDATE jobs
    SET status='completed',
        updated_at=:now,
        last_error=NULL
    WHERE id=:job_id
      AND status='running'

Then insert the result:

    INSERT INTO job_results(
        job_id,
        model,
        response_text,
        response_json,
        error,
        created_at,
        updated_at
    )
    VALUES(
        :job_id,
        :model,
        :response_text,
        :response_json,
        NULL,
        :now,
        :now
    )

Because job_results.job_id is the primary key, duplicate result inserts should fail structurally.

The wrapper must still check before and after:

    SELECT COUNT(*) FROM job_results WHERE job_id=:job_id

Expected counts:

    before claim: 0
    after completion: 1

## Failure SQL shape

If the adapter returns a real failure and no result row was inserted, the wrapper may classify the claimed job as failed:

    UPDATE jobs
    SET status='failed',
        last_error=:error_summary,
        updated_at=:now
    WHERE id=:job_id
      AND status='running'
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=:job_id
      )

This failure transition must not run after a timeout until recovery proves that no completion occurred.

## Scheduler selection requirements

The wrapper must not accept arbitrary job ids from a user for normal operation.

The job id must come from scheduler selection logic.

For the next controlled test, the wrapper may accept an expected selected job id only as a safety assertion.

Selection must require:

    status=queued
    result_rows=0
    requested_model allowlisted
    lane=model
    oldest eligible job first
    exactly one selected target for the one-shot run

The scheduler gate must continue to reject:

    job 23 because requested_model=gemma4:e4b is not allowlisted
    job 24 because requested_model=mock/no-model is not allowlisted

## Model allowlist

Near-term model allowlist should include only the already-proven model:

    qwen2.5:32b-instruct-q4_K_M

Additional models require separate readiness and safety gates.

## PVESO guard

Before runtime:

    PVESO Tailscale target must resolve
    SSH to PVESO must succeed
    ollama.service must be active
    127.0.0.1:11434 listener count must be 1
    non-localhost 11434 listener count must be 0
    Ollama runner count must be 0
    target model must already be present
    no model pull is allowed

After runtime:

    ollama.service must still be active
    non-localhost 11434 listener count must be 0
    runner/adapter process count must return to 0

## CT101 guard

Before and after runtime:

    CT101_STATUS=stopped
    CT101_ONBOOT=0

Any deviation must stop the wrapper before dispatch.

The wrapper must not start CT101.

## Timeout recovery

If the wrapper times out, do not rerun immediately.

The recovery sequence must be read-only:

1. inspect run directory artifacts
2. inspect CT203 DB state read-only
3. classify selected job status
4. inspect result row count
5. inspect PVESO runner/adapter process count
6. inspect CT101 status
7. produce recovery decision

Recovery classifications:

    completed_with_one_result_do_not_rerun
    running_zero_results_runner_active_do_not_rerun
    running_zero_results_no_runner_manual_recovery_required
    queued_zero_results_no_claim_new_approval_required
    failed_zero_results_do_not_rerun_without_review
    duplicate_result_failure_do_not_rerun
    ambiguous_preserve_artifacts_do_not_rerun

## Required run artifacts

Each future one-shot Option B runtime must preserve:

    run_dir
    recovery_hint.txt
    repo_preflight.txt
    ct203_db_stat_before.txt
    scheduler_selection_before.txt
    selected_job_before.txt
    pveso_preflight.txt
    ct101_preflight.txt
    atomic_claim.sql.txt
    atomic_claim_result.txt
    selected_job_after_claim.txt
    adapter.stdout.raw.txt
    adapter.stderr.raw.txt
    completion_result.txt
    selected_job_after_completion.txt
    ct203_db_stat_after.txt
    pveso_postflight.txt
    ct101_postflight.txt
    final_status.txt

## Apply refusal cases

The future wrapper must refuse before model dispatch if:

- repo checkpoint mismatch
- dirty repo
- approval phrase missing
- scheduler or persistent workers active
- CT101 running or onboot not zero
- PVESO unavailable
- Ollama not localhost-only
- model missing
- more than one selected eligible target
- no selected eligible target
- selected target is job 23
- selected target is job 24
- selected target is job 27
- selected target is job 28
- selected target already has a result row
- selected target is not queued
- atomic claim changes() is not 1

## No persistent activation

Even after Option B succeeds, persistent scheduler activation remains blocked.

Option B is a bridge toward repeatability, not the final unattended scheduler.

Persistent activation should wait for either:

- proven multiple one-shot atomic claims across fresh jobs, plus strong recovery policy, or
- Option C dedicated lease columns with tested migration and rollback.

## Recommended next phases

Recommended next phases:

1. E3V-E no-apply code design for the one-shot Option B wrapper
2. E3V-F static smoke for wrapper guard strings and refusal paths
3. E3V-G read-only live preflight with no eligible fresh job
4. E3V-H fresh eligible job insert plan, no apply
5. E3V-I explicitly approved insert of one fresh eligible job
6. E3V-J read-only scheduler selection of the fresh job
7. E3V-K explicitly approved Option B atomic-claim one-shot dispatch

## E3V-D result

E3V-D performs no apply.

It does not write the DB.

It does not claim a job.

It does not run the helper.

It does not run the adapter.

It does not call a model.

It does not activate scheduler or workers.

It defines the implementation boundary for a future explicit Option B one-shot atomic claim dispatch.
