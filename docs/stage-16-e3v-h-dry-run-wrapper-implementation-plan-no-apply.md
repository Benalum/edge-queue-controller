# Stage 16 E3V-H — Dry-Run Wrapper Implementation Plan, No Apply

## Purpose

E3V-H defines the no-apply plan for replacing the E3V-F static default-refuse scaffold with a real dry-run-only guard implementation.

This phase does not implement the wrapper.

It does not execute the wrapper.

It does not write the DB.

It does not claim a job.

It does not call an adapter.

It does not call a model.

It does not activate scheduler or persistent workers.

## Baseline

Latest completed checkpoint before E3V-H:

    HEAD/origin/main: 09bd140
    tag: controller-stage-16-e3v-g-static-wrapper-refusal-execution-smoke-result-2026-06-21

E3V-G proved the static wrapper refusal paths executed safely:

    no-mode refused with rc=2
    dry-run refused with rc=2
    execute-approved without approval refused with rc=2
    execute-approved with approval still refused with rc=2
    CT203 DB stat was unchanged

## Current wrapper scaffold

Wrapper path:

    ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh

Current state:

    static artifact
    default-refuse
    not runtime-enabled
    no DB writes
    no DB claims
    no helper calls
    no adapter calls
    no model calls

## E3V-H target

E3V-H prepares the next code phase.

The next code phase should replace only the dry-run path with a real read-only preflight implementation.

The execute-approved path must remain refused.

The wrapper should become:

    --dry-run: real read-only guard checks
    --execute-approved: still refused until a later explicit apply phase

## Required dry-run behavior

The future dry-run implementation must perform only read-only checks:

- repo checkpoint check
- git clean check
- scheduler disabled check
- persistent workers disabled check
- CT203 DB stat before
- CT203 DB read-only candidate inspection
- E3S scheduler selection dry-run
- forbidden job id refusal check
- PVESO availability check
- PVESO Ollama localhost-only check
- PVESO runner count check
- CT101 stopped/onboot check
- CT203 DB stat after
- final dry-run classification

It must not:

- write the DB
- change job status
- increment attempts
- insert job_results
- call helper
- call adapter
- call model
- pull model
- start CT101
- activate scheduler
- activate persistent workers

## Required dry-run markers

A successful future dry-run should emit:

    MODE=dry-run
    NO_DB_WRITE
    NO_SCHEMA_MIGRATION
    NO_DB_CLAIM
    NO_HELPER_CALL
    NO_ADAPTER_CALL
    NO_MODEL_CALL
    SCHEDULER_ACTIVATION=not_performed
    PERSISTENT_WORKER_ACTIVATION=not_performed
    DB_INTEGRITY=ok
    CT203_DB_STAT_UNCHANGED=true
    PVESO_PREFLIGHT_OK
    CT101_STATUS=stopped
    CT101_ONBOOT=0
    E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK

If no eligible fresh job exists, dry-run should still be successful if all guards pass:

    E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=0
    E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME

If exactly one eligible fresh job exists, dry-run should report but not claim:

    E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1
    WOULD_ATOMIC_CLAIM job_id=<id>
    E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME

If more than one eligible job exists, dry-run should refuse:

    REFUSE_MULTIPLE_ELIGIBLE_JOBS

## Candidate selection rules

The dry-run candidate selection must match E3S-style selection.

Required job criteria:

    status=queued
    result_rows=0
    requested_model allowlisted
    lane=model
    oldest eligible job first

Initial model allowlist:

    qwen2.5:32b-instruct-q4_K_M

Forbidden job ids:

    23
    24
    27
    28

The dry-run must refuse or exclude forbidden job ids even if they otherwise appear selectable.

## Current expected candidate state

Current live DB state from E3V-C:

    jobs_total=27
    job_results_total=10
    job 23 queued, rejected model gemma4:e4b
    job 24 queued, rejected model mock/no-model
    job 27 completed
    job 28 completed

Expected dry-run result before inserting a fresh job:

    no eligible fresh job
    no runtime
    no DB change

## PVESO checks

The dry-run should verify PVESO without calling a model.

Checks:

    PVESO target found through Tailscale status
    no hardcoded pveso DNS dependency
    SSH to PVESO succeeds
    ollama.service active
    127.0.0.1:11434 listener count is 1
    non-localhost 11434 listener count is 0
    runner/adapter process count is 0
    target model is already present
    no model pull

## CT101 checks

The dry-run should verify:

    CT101_STATUS=stopped
    CT101_ONBOOT=0

Any deviation must refuse before runtime.

The wrapper must never start CT101.

## Scheduler and worker checks

The dry-run should verify:

    scheduler activation not performed
    persistent worker activation not performed
    EDGE_PERSISTENT_LANE_WORKERS_ENABLED is absent or not true
    no active persistent lane worker process is detected

If the implementation cannot safely inspect a signal, it should print unknown and refuse runtime.

## CT203 DB read-only checks

The dry-run should open the CT203 DB read-only.

Required DB markers:

    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    DB_INTEGRITY=ok
    JOBS_TOTAL=27
    JOB_RESULTS_TOTAL=10
    DUPLICATE_JOB_RESULTS none

The DB stat before and after dry-run must match.

## Refusal cases to preserve

The future dry-run implementation must still preserve clear refusal markers:

    REFUSE_APPROVAL_MISSING
    REFUSE_REPO_CHECKPOINT_MISMATCH
    REFUSE_REPO_DIRTY
    REFUSE_SCHEDULER_ACTIVE
    REFUSE_PERSISTENT_WORKERS_ACTIVE
    REFUSE_CT101_NOT_STOPPED
    REFUSE_PVESO_UNAVAILABLE
    REFUSE_OLLAMA_NOT_LOCALHOST_ONLY
    REFUSE_MODEL_MISSING
    REFUSE_MULTIPLE_ELIGIBLE_JOBS
    REFUSE_FORBIDDEN_JOB_ID
    REFUSE_SELECTED_JOB_HAS_RESULT
    REFUSE_E3V_EXECUTE_NOT_ENABLED

## Execute-approved path remains blocked

The next implementation phase must not enable runtime.

Even with the approval phrase:

    APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY

The execute-approved path should still emit:

    REFUSE_E3V_EXECUTE_NOT_ENABLED
    NO_DB_WRITE
    NO_DB_CLAIM
    NO_ADAPTER_CALL
    NO_MODEL_CALL

Actual atomic claim runtime remains a later phase.

## Recommended next phases

Recommended next phases:

1. E3V-I implement dry-run-only wrapper guard path
2. E3V-J execute dry-run-only wrapper guard path, read-only
3. E3V-K document dry-run-only wrapper result
4. E3V-L fresh eligible job insert plan, no apply
5. E3V-M explicitly approved insert of one fresh eligible job
6. E3V-N dry-run wrapper would-claim fresh job
7. E3V-O no-apply runtime apply plan
8. E3V-P explicitly approved one-job Option B atomic claim dispatch

## E3V-H result

E3V-H is no-apply.

It creates only this implementation plan and smoke.

It does not implement the wrapper.

It does not execute the wrapper.

It does not write the DB.

It does not call a model.

It keeps runtime apply blocked.
