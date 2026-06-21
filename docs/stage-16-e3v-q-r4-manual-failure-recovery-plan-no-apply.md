# Stage 16 E3V-Q-R4 — Manual Failure Recovery Plan, No Apply

## Purpose

E3V-Q-R4 defines the no-apply recovery plan for job 29 after the E3V-Q runtime timeout.

This phase does not modify the DB.

It does not rerun E3V-Q.

It does not execute the wrapper.

It does not call a model.

It does not kill any process.

## Current evidence

Latest recovery bundle:

    HEAD/origin/main: 068c67d
    tag: controller-stage-16-e3v-q-r1-r3-read-only-timeout-recovery-bundle-2026-06-21

E3V-Q-R1 through E3V-Q-R3 established:

    job_id=29
    status=running
    attempts=1
    result_rows=0
    requested_model=qwen2.5:32b-instruct-q4_K_M
    atomic claim succeeded
    E3V_Q_ATOMIC_CLAIM_CHANGES=1
    E3V_Q_JOB_STATUS_AFTER_CLAIM=running
    E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1
    E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM=0
    no model_adapter_result content
    no completion_result
    no active Ollama client or connection
    no runner process
    no job_result row

Final R3 classification:

    RECOVERY_R3_FINAL_CLASSIFICATION=running_zero_results_no_runner_no_artifact_manual_failure_plan_required

## Recovery decision

Because there is no model response artifact and no completion artifact, job 29 must not be completed as successful.

Because the job was already atomically claimed, it must not be claimed again.

Because E3V-Q already timed out after claim, it must not be rerun.

The recommended recovery is to mark job 29 as failed with a clear timeout/interrupted-before-model-result error, preserving:

    attempts=1
    result_rows=0
    requested_model=qwen2.5:32b-instruct-q4_K_M

## Future approval phrase

Future apply phase must require this exact approval phrase:

    APPROVE_STAGE_16_E3V_Q_R5_MARK_JOB_29_FAILED_AFTER_TIMEOUT_NO_RESULT_ONLY

## Future apply scope

The future apply phase may only:

    update jobs set status='failed'
    set last_error to a clear E3V-Q timeout/no-result recovery message
    update updated_at

The future apply phase must not:

- claim job 29
- increment attempts
- insert job_results
- call a model
- run the wrapper
- run execute-approved
- activate scheduler
- activate persistent workers
- start CT101
- pull a model
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Future DB preflight requirements

Before the failure update, the future apply phase must verify read-only:

    DB_INTEGRITY_BEFORE=ok
    job 29 exists
    job 29 status=running
    job 29 attempts=1
    job 29 result_rows=0
    job 29 requested_model=qwen2.5:32b-instruct-q4_K_M
    no duplicate job_results
    no active PVESO client or connection
    no model_adapter_result content
    no completion_result

If any of those are false, the future apply phase must refuse:

    REFUSE_JOB_NOT_RUNNING
    REFUSE_JOB_ATTEMPTS_NOT_ONE
    REFUSE_JOB_HAS_RESULT
    REFUSE_JOB_MODEL_MISMATCH
    REFUSE_DUPLICATE_JOB_RESULTS
    REFUSE_ACTIVE_MODEL_CLIENT_OR_CONNECTION
    REFUSE_MODEL_ARTIFACT_PRESENT
    REFUSE_COMPLETION_ARTIFACT_PRESENT

## Future failure SQL shape

The future apply phase must use a single guarded update:

    BEGIN IMMEDIATE;

    UPDATE jobs
    SET status='failed',
        last_error='E3V-Q timeout recovery: job was atomically claimed, but the bridge timed out before model output or completion; no model_adapter_result and no job_result artifact existed during read-only recovery.',
        updated_at=:now
    WHERE id=29
      AND status='running'
      AND attempts=1
      AND requested_model='qwen2.5:32b-instruct-q4_K_M'
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=29
      );

    SELECT changes();

    COMMIT;

Required marker:

    E3V_Q_R5_FAILURE_UPDATE_CHANGES=1

If changes is not exactly 1, refuse:

    REFUSE_FAILURE_UPDATE_NOT_ONE

## Future postflight requirements

After the failure update, future postflight must verify:

    DB_INTEGRITY_AFTER=ok
    job 29 status=failed
    job 29 attempts=1
    job 29 result_rows=0
    job 29 last_error contains E3V-Q timeout recovery
    job_results_total unchanged
    no duplicate job_results
    CT101_STATUS=stopped
    CT101_ONBOOT=0
    scheduler still not active
    persistent workers still not active

Required final marker:

    E3V_Q_R5_MARK_JOB_29_FAILED_AFTER_TIMEOUT_NO_RESULT_OK

## Runtime remains blocked

E3V-Q-R4 does not authorize recovery apply.

E3V-Q-R4 does not authorize rerun.

E3V-Q-R4 creates only this no-apply recovery plan and smoke.

Do not rerun E3V-Q.
