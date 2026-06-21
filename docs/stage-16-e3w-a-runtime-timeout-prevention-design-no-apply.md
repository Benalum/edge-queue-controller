# Stage 16 E3W-A — Runtime Timeout Prevention Design, No Apply

## Purpose

E3W-A defines the timeout-safe runtime design for the next controlled one-job dispatch proof.

This is a no-apply phase.

It does not insert a job.
It does not claim a job.
It does not run the wrapper.
It does not call a model.
It does not mutate the DB.

## Carry-forward facts from E3V-Q

E3V-Q proved:

    atomic DB claim path works
    guarded claim changed exactly one row
    job 29 moved queued -> running
    attempts became 1
    result_rows stayed 0 at claim

E3V-Q also proved the current runtime wrapper is vulnerable to this outer-timeout failure mode:

    outer PPB/tmux runtime timeout or interruption can kill the wrapper after claim
    wrapper model timeout was longer than the outer execution window
    no model_adapter_result was produced
    no completion_result was produced
    job 29 had to be manually closed as failed

Final E3V closure:

    job 29 status=failed
    job 29 attempts=1
    job 29 result_rows=0
    job 29 must not be rerun
    E3V-Q must not be rerun

## Problem statement

A one-job runtime proof must not allow this sequence to be the normal failure mode:

    claim job
    start model wait
    outer runner times out
    wrapper is killed
    job remains running with no result

The runtime wrapper must have enough time to either:

1. complete the model call and write job_results, or
2. catch its own timeout/error and mark the claimed job failed cleanly.

## Required E3W design rule

For any future approved runtime proof:

    wrapper_model_timeout_seconds < wrapper_total_timeout_seconds < PPB_outer_timeout_seconds

The wrapper must fail the claimed job itself before the outer runner can kill the shell.

## E3W recommended timeout budget

Use conservative values for the next one-job runtime proof:

    PPB outer timeout target: at least 300 seconds
    wrapper total guard target: 180 seconds
    model call timeout target: 60 seconds
    model num_predict target: 16 or lower
    model temperature: 0
    stream: false

If the model call does not return inside the model timeout, the wrapper must perform a guarded failure update for that same claimed job.

## E3W next proof model rule

The next runtime proof should not use job 29 and should not use the previous long-running proof setup.

The next proof should use one of these approaches:

1. use a smaller known-present model from a read-only PVESO model inventory, or
2. keep the same model only if the request is made extremely small and the wrapper timeout is safely below the outer timeout.

Preferred next step:

    E3W-B read-only PVESO model inventory and timeout budget check

E3W-B should not call a model. It should only list local models and choose a candidate for the next proof.

## E3W next job rule

The next runtime proof must use a new job id.

It must not use job 29.

It must not reset job 29.

It must not rerun E3V-Q.

The next job should be inserted only after:

1. timeout-safe wrapper behavior is implemented and committed, and
2. a read-only dry-run proves exactly one eligible fresh job would be claimed.

## Required wrapper behavior for E3W runtime

A future timeout-safe runtime wrapper must do all of the following:

### Before claim

Verify:

    repo clean and expected HEAD
    scheduler disabled
    persistent workers disabled
    CT101 stopped and onboot=0
    PVESO Ollama active and localhost-only
    no active PVESO model client for the target job
    DB integrity ok
    no duplicate job_results
    exactly one eligible fresh job
    selected job id is the expected new job id
    selected job status=queued
    selected job attempts=0
    selected job result_rows=0

### Claim

Use the same atomic guarded claim pattern:

    BEGIN IMMEDIATE
    UPDATE jobs SET status='running', attempts=attempts+1, updated_at=:now
    WHERE id=:expected_new_job_id
      AND status='queued'
      AND attempts=0
      AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=:expected_new_job_id)
    SELECT changes()
    COMMIT

Required marker:

    E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1

If changes is not exactly 1:

    REFUSE_E3W_ATOMIC_CLAIM_NOT_ONE

### Model call

Use one model call only.

Required model-call constraints:

    stream=false
    temperature=0
    num_predict<=16
    model_timeout_seconds<=60
    no model pull
    no retry loop
    no second model call

Required success marker:

    E3W_ONE_SHOT_MODEL_RESULT=ok

### Internal timeout/failure path

If the model call times out or errors after a successful claim, the wrapper must perform a guarded failure update before exiting:

    UPDATE jobs
    SET status='failed',
        last_error=:timeout_or_error_message,
        updated_at=:now
    WHERE id=:expected_new_job_id
      AND status='running'
      AND attempts=1
      AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=:expected_new_job_id)

Required failure marker:

    E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1

This failure path must not insert job_results.

### Completion path

If the model call succeeds, the wrapper must:

    insert exactly one job_results row
    set job status=completed
    preserve attempts=1
    verify result_rows=1
    verify job_results_total increased by exactly 1
    verify no duplicate job_results

Required success marker:

    E3W_RUNTIME_COMPLETION_OK

## Required recovery discipline

For any E3W runtime timeout or failure:

    DO_NOT_RERUN
    RUN_READ_ONLY_RECOVERY_FIRST

Never rerun a claimed job.

Never reset a claimed job without a no-apply plan and explicit approval.

Never retry job 29.

## Recommended next stages

### E3W-B — Read-only PVESO model inventory and timeout budget

Scope:

    read-only PVESO model list
    no model call
    no model pull
    no DB write
    no wrapper execution

Goal:

    choose a known-present small/fast model for next proof
    confirm timeout budget

### E3W-C — Implement timeout-safe wrapper changes, no run

Scope:

    repo wrapper/docs/smoke only
    no DB write
    no model call
    no wrapper execution

Goal:

    implement internal model timeout and guarded failure update path

### E3W-D — Insert one fresh eligible timeout-safe proof job

Requires explicit approval.

Scope:

    one DB insert only
    no claim
    no model call

### E3W-E — Dry-run would-claim fresh timeout-safe proof job

Scope:

    wrapper --dry-run only
    read-only DB verification
    no claim
    no model call

### E3W-F — Approved one-job timeout-safe runtime proof

Requires explicit approval.

Scope:

    one atomic claim
    one model call
    one completion write or one internal failure update
    no rerun
    no retry

## Final rule

E3V-Q is closed.

Job 29 is closed failed.

Do not rerun E3V-Q.

Do not retry job 29.

E3W must use a new job and timeout-safe wrapper behavior.
