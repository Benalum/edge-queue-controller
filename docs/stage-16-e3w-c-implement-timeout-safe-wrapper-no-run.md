# Stage 16 E3W-C — Implement Timeout-Safe Wrapper, No Run

## Result

E3W-C created a timeout-safe one-job runtime wrapper but did not run it.

Wrapper path:

    ops/scheduler/stage-16-e3w-timeout-safe-one-job-dispatch.sh

Final marker:

    E3W_C_TIMEOUT_SAFE_WRAPPER_IMPLEMENTED_NO_RUN_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 27b3bb3
    Previous tag: controller-stage-16-e3w-b-read-only-pveso-model-inventory-timeout-budget-2026-06-21
    Working tree: clean

## Safety boundary

E3W-C did not:

- write the DB
- apply a schema migration
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper in runtime mode
- run execute-approved
- call the helper
- call the adapter
- call a model
- call prompt/completion/generate/chat/embed
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Wrapper design

The wrapper supports two modes:

    --dry-run
    --run

Runtime mode requires this approval phrase:

    APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY

The wrapper requires:

    E3W_EXPECTED_JOB_ID
    E3W_EXPECTED_MODEL
    E3W_EXPECTED_JOB_TYPE

The wrapper explicitly refuses job 29.

## Timeout rules

The wrapper enforces:

    model timeout < wrapper total timeout

Default timeout budget:

    E3W_MODEL_TIMEOUT_SECONDS=45
    E3W_WRAPPER_TOTAL_SECONDS=120
    E3W_NUM_PREDICT=8
    E3W_TEMPERATURE=0

## Required markers implemented

Dry-run marker:

    E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME

Atomic claim marker:

    E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1
    E3W_RUNTIME_ATOMIC_CLAIM_OK

Model-call success marker:

    E3W_ONE_SHOT_MODEL_RESULT=ok

Internal failure markers:

    E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1
    E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_OK
    E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK

Completion marker:

    E3W_RUNTIME_COMPLETION_OK

## Internal failure behavior

If the model call times out or fails after a successful claim, the wrapper performs a guarded failure update:

    status='failed'
    attempts=1
    no job_results row exists
    requested_model matches
    job id matches the expected new job id

The failure path does not insert job_results.

## Completion behavior

If the model call succeeds, the wrapper attempts one completion transaction:

    insert exactly one job_results row
    set job status completed
    keep attempts=1
    verify result_rows=1

If completion fails after model success, the wrapper falls back to the same guarded internal failure update, provided no job_results row exists.

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not run this wrapper in runtime mode until a new eligible E3W job is inserted and a dry-run would-claim check passes.

## Recommended next phase

Recommended next phase:

    E3W-D — insert one fresh timeout-safe proof job

That phase requires explicit approval because it is a DB insert.
