# Stage 16 E3V-K — Fresh Eligible Job Insert Plan, No Apply

## Purpose

E3V-K defines the no-apply plan for inserting exactly one fresh eligible queued job for the Option B atomic-status-claim wrapper path.

This phase does not insert the job.

It does not write the DB.

It does not execute the wrapper.

It does not claim a job.

It does not call an adapter.

It does not call a model.

## Baseline

Latest completed checkpoint before E3V-K:

    HEAD/origin/main: c8bd88d
    tag: controller-stage-16-e3v-j-dry-run-wrapper-guard-execution-result-2026-06-21

E3V-J dry-run result:

    E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME
    E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=0
    CT203 DB stat unchanged
    PVESO_PREFLIGHT_OK
    CT101_STATUS=stopped
    CT101_ONBOOT=0

## Why a fresh job is needed

The wrapper dry-run path is now executable and read-only.

It proved there is currently no eligible fresh job to claim.

Known excluded jobs:

    job 23 queued but requested_model=gemma4:e4b and not allowlisted
    job 24 queued but requested_model=mock/no-model and not allowlisted
    job 27 completed and must not be reused
    job 28 completed and must not be rerun

A new fresh queued job is needed so the wrapper dry-run can report:

    E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME
    E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1
    WOULD_ATOMIC_CLAIM job_id=<fresh_job_id>

## Future insert phase

Future phase name:

    Stage 16 E3V-L — Insert One Fresh Eligible Option B Job

Future approval phrase:

    APPROVE_STAGE_16_E3V_L_INSERT_ONE_FRESH_ELIGIBLE_OPTION_B_JOB_ONLY

The insert phase must be explicit-approval only.

It must insert exactly one job into CT203 DB.

It must not execute the wrapper.

It must not claim the job.

It must not call the helper.

It must not call the adapter.

It must not call a model.

## Future job shape

The future inserted job should be a synthetic model-smoke job for the already-present PVESO model:

    status=queued
    attempts=0
    requested_model=qwen2.5:32b-instruct-q4_K_M
    job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke
    prompt=Stage 16 E3V fresh eligible Option B atomic-claim smoke. Reply with a short deterministic confirmation.
    user_id=stage16-e3v

The future insert must leave result rows at zero:

    job_results_for_fresh_job=0

The future inserted job must not be one of the forbidden ids:

    23
    24
    27
    28

## Insert safety rules

The future insert phase must:

1. verify repo checkpoint
2. verify working tree clean
3. verify CT203 DB integrity before insert
4. verify current eligible job count is zero before insert
5. insert exactly one queued job
6. verify exactly one new job id was created
7. verify inserted job has requested_model=qwen2.5:32b-instruct-q4_K_M
8. verify inserted job has status=queued
9. verify inserted job has attempts=0
10. verify inserted job has result_rows=0
11. verify total eligible job count is exactly one after insert
12. verify no duplicate job_results
13. document the fresh job id
14. refuse if any unexpected eligible job already exists

## Future insert SQL shape

The future insert should use a single explicit SQLite transaction.

Recommended SQL shape:

    BEGIN IMMEDIATE;

    INSERT INTO jobs (
      job_type,
      prompt,
      requested_model,
      status,
      attempts,
      user_id,
      created_at,
      updated_at
    )
    VALUES (
      'stage16_e3v_option_b_atomic_claim_fresh_model_smoke',
      'Stage 16 E3V fresh eligible Option B atomic-claim smoke. Reply with a short deterministic confirmation.',
      'qwen2.5:32b-instruct-q4_K_M',
      'queued',
      0,
      'stage16-e3v',
      :now,
      :now
    );

    SELECT last_insert_rowid();

    COMMIT;

If the live jobs schema requires nullable/default handling for omitted columns, the future phase must inspect schema first and only use columns known safe from E3V-C.

## Future post-insert markers

A successful future insert phase should emit:

    E3V_L_INSERTED_FRESH_JOB_ID=<id>
    E3V_L_INSERTED_JOB_STATUS=queued
    E3V_L_INSERTED_JOB_ATTEMPTS=0
    E3V_L_INSERTED_JOB_MODEL=qwen2.5:32b-instruct-q4_K_M
    E3V_L_INSERTED_JOB_RESULT_ROWS=0
    E3V_L_ELIGIBLE_JOB_COUNT_AFTER=1
    E3V_L_INSERT_ONE_FRESH_ELIGIBLE_JOB_OK

## Required refusal markers

The future insert phase must preserve these refusal markers:

    REFUSE_APPROVAL_MISSING
    REFUSE_REPO_CHECKPOINT_MISMATCH
    REFUSE_REPO_DIRTY
    REFUSE_DB_INTEGRITY_NOT_OK
    REFUSE_EXISTING_ELIGIBLE_JOB_PRESENT
    REFUSE_MULTIPLE_ELIGIBLE_JOBS
    REFUSE_INSERT_NOT_EXACTLY_ONE
    REFUSE_INSERTED_JOB_HAS_RESULT
    REFUSE_INSERTED_JOB_NOT_QUEUED
    REFUSE_INSERTED_JOB_MODEL_MISMATCH
    REFUSE_INSERTED_JOB_ATTEMPTS_NOT_ZERO
    REFUSE_FORBIDDEN_JOB_ID
    REFUSE_DB_STAT_UNEXPECTED
    REFUSE_RUNTIME_MARKER_FOUND

## Expected phase after insert

After E3V-L inserts one fresh eligible job, E3V-M should run the wrapper dry-run again.

Expected E3V-M wrapper dry-run result:

    E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1
    E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME
    WOULD_ATOMIC_CLAIM job_id=<fresh_job_id>
    CT203_DB_STAT_UNCHANGED=true
    E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK

Only after that should we plan the actual runtime atomic claim dispatch.

## Runtime remains blocked

E3V-K does not authorize runtime.

The execute-approved path remains blocked.

No atomic claim dispatch is approved by this phase.

## E3V-K result

E3V-K is no-apply.

It creates only this plan and smoke.

It does not insert a job.

It does not execute the wrapper.

It does not write the DB.

It does not call a model.
