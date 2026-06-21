# Stage 16 E3V-N — Runtime Atomic-Claim Dispatch Plan, No Apply

## Purpose

E3V-N defines the no-apply runtime plan for the first Option B atomic-status-claim dispatch of fresh job 29.

This phase does not run the dispatch.

It does not implement the runtime path.

It does not execute the wrapper.

It does not write the DB.

It does not claim job 29.

It does not call the adapter.

It does not call a model.

## Baseline

Latest completed checkpoint before E3V-N:

    HEAD/origin/main: 7843a44
    tag: controller-stage-16-e3v-m-dry-run-wrapper-would-claim-fresh-job-result-2026-06-21

E3V-M proved the wrapper dry-run would select exactly one fresh eligible job:

    E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1
    E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME
    WOULD_ATOMIC_CLAIM job_id=29
    CT203_DB_STAT_UNCHANGED=true
    E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK

Fresh job 29 remained unchanged after dry-run:

    status=queued
    attempts=0
    result_rows=0
    requested_model=qwen2.5:32b-instruct-q4_K_M
    job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke

## Current blocker

The wrapper execute-approved path is intentionally still blocked:

    REFUSE_E3V_EXECUTE_NOT_ENABLED

Therefore runtime dispatch must not be attempted until a later implementation phase safely enables exactly one execute-approved path.

## Recommended next phases

Recommended next phases:

1. E3V-O implement execute-approved runtime path for job 29 only, but do not run it
2. E3V-P static smoke and commit the execute-approved implementation
3. E3V-Q explicitly approved one-job Option B atomic-claim dispatch of job 29
4. E3V-R read-only recovery/documentation if the runtime phase times out after DB/model completion
5. E3V-S post-dispatch result commit/tag/push

## Future runtime approval phrase

Future runtime dispatch must require this exact approval phrase:

    APPROVE_STAGE_16_E3V_Q_RUN_JOB_29_OPTION_B_ATOMIC_CLAIM_DISPATCH_ONLY

The approval scope must be exactly:

    job_id=29 only
    one atomic claim only
    one adapter/model call only
    one completion write only
    no scheduler activation
    no persistent worker activation
    no CT101 start
    no schema migration
    no model pull

## Future execute-approved preflight requirements

Before any claim, the future execute-approved path must verify:

    repo checkpoint matches expected runtime implementation commit
    working tree is clean
    explicit approval phrase is present
    selected job id is exactly 29
    job 29 status=queued
    job 29 attempts=0
    job 29 result_rows=0
    job 29 requested_model=qwen2.5:32b-instruct-q4_K_M
    job 29 is not forbidden
    eligible job count is exactly 1
    scheduler is not active
    persistent workers are not active
    CT101_STATUS=stopped
    CT101_ONBOOT=0
    PVESO is reachable through Tailscale
    Ollama is active on PVESO
    OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
    OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
    PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0
    TARGET_MODEL_PRESENT=true
    no model pull is required

## Future atomic claim SQL

The future execute-approved path must use a single atomic claim transaction.

Required claim SQL shape:

    BEGIN IMMEDIATE;

    UPDATE jobs
    SET status='running',
        attempts=attempts+1,
        updated_at=:now
    WHERE id=:job_id
      AND id=29
      AND status='queued'
      AND attempts=0
      AND requested_model='qwen2.5:32b-instruct-q4_K_M'
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=:job_id
      );

    SELECT changes();

    COMMIT;

Required claim result:

    E3V_Q_ATOMIC_CLAIM_CHANGES=1
    E3V_Q_JOB_STATUS_AFTER_CLAIM=running
    E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1
    E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM=0

If changes() is not exactly 1, the future runtime path must refuse:

    REFUSE_ATOMIC_CLAIM_NOT_ONE

No adapter/model call may happen unless claim changes() equals exactly 1.

## Future adapter/model call boundary

The future runtime path may call the one-shot adapter only after successful claim.

Allowed model call:

    one adapter/model call for job 29 only
    requested_model=qwen2.5:32b-instruct-q4_K_M
    PVESO localhost Ollama only
    no model pull
    no browser/user direct model call
    no CT101 model call

Forbidden model behavior:

    no direct frontend model call
    no persistent worker model call
    no scheduler activation
    no retry loop
    no second model call
    no model pull

Expected adapter marker:

    ONE_SHOT_MODEL_ADAPTER_RESULT=ok

If model/adapter fails after claim, future completion must mark job failed with one clear error and must not insert a success result.

## Future completion SQL

If and only if adapter/model returns a valid response, completion must be claim-aware and must transition running to completed.

Required completion SQL shape:

    BEGIN IMMEDIATE;

    UPDATE jobs
    SET status='completed',
        last_error=NULL,
        updated_at=:now
    WHERE id=:job_id
      AND id=29
      AND status='running'
      AND requested_model='qwen2.5:32b-instruct-q4_K_M'
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=:job_id
      );

    INSERT INTO job_results (
      job_id,
      model,
      response_text,
      response_json,
      error,
      created_at,
      updated_at
    )
    VALUES (
      :job_id,
      :model,
      :response_text,
      :response_json,
      NULL,
      :now,
      :now
    );

    COMMIT;

Required completion result:

    E3V_Q_COMPLETION_CHANGES=1
    E3V_Q_JOB_STATUS_AFTER_COMPLETION=completed
    E3V_Q_JOB_ATTEMPTS_AFTER_COMPLETION=1
    E3V_Q_JOB_RESULT_ROWS_AFTER_COMPLETION=1

If completion changes are not exactly 1, future runtime must refuse and preserve artifacts:

    REFUSE_COMPLETION_NOT_ONE
    DO_NOT_RERUN
    RUN_READ_ONLY_RECOVERY_FIRST

## Future postflight requirements

After runtime dispatch, future postflight must verify:

    job 29 status=completed
    job 29 attempts=1
    job 29 result_rows=1
    job_results_total increased by exactly 1
    no duplicate job_results
    DB_INTEGRITY_AFTER=ok
    PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT_AFTER=0
    CT101_STATUS_AFTER=stopped
    CT101_ONBOOT_AFTER=0
    scheduler still not active
    persistent workers still not active

Expected final runtime marker:

    E3V_Q_OPTION_B_ATOMIC_CLAIM_DISPATCH_JOB_29_OK

## Timeout recovery rules

If the runtime phase times out, do not rerun automatically.

First run read-only recovery and classify:

    completed_with_one_result_do_not_rerun
    running_zero_results_runner_active_do_not_rerun
    running_zero_results_no_runner_manual_recovery_required
    queued_zero_results_no_claim_new_approval_required
    failed_zero_results_do_not_rerun_without_review
    duplicate_result_failure_do_not_rerun
    ambiguous_preserve_artifacts_do_not_rerun

Required recovery markers:

    DO_NOT_RERUN
    RUN_READ_ONLY_RECOVERY_FIRST

## Required future refusal markers

The future runtime path must preserve:

    REFUSE_APPROVAL_MISSING
    REFUSE_REPO_CHECKPOINT_MISMATCH
    REFUSE_REPO_DIRTY
    REFUSE_SELECTED_JOB_ID_NOT_29
    REFUSE_SELECTED_JOB_NOT_QUEUED
    REFUSE_SELECTED_JOB_HAS_RESULT
    REFUSE_SELECTED_JOB_ATTEMPTS_NOT_ZERO
    REFUSE_SELECTED_JOB_MODEL_MISMATCH
    REFUSE_MULTIPLE_ELIGIBLE_JOBS
    REFUSE_FORBIDDEN_JOB_ID
    REFUSE_SCHEDULER_ACTIVE
    REFUSE_PERSISTENT_WORKERS_ACTIVE
    REFUSE_CT101_NOT_STOPPED
    REFUSE_PVESO_UNAVAILABLE
    REFUSE_OLLAMA_NOT_LOCALHOST_ONLY
    REFUSE_MODEL_MISSING
    REFUSE_ATOMIC_CLAIM_NOT_ONE
    REFUSE_COMPLETION_NOT_ONE
    REFUSE_RUNTIME_MARKER_MISSING

## Runtime remains blocked by E3V-N

E3V-N does not authorize runtime.

E3V-N does not authorize the execute-approved path.

E3V-N creates only this plan and smoke.

No atomic claim dispatch is approved by this phase.
