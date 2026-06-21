# Stage 16 E3V-E — Option B Wrapper Code Design, No Apply

## Purpose

E3V-E defines the code design for the future Option B one-shot atomic-status-claim wrapper.

This is still no-apply.

This phase does not create the runtime wrapper yet.

No DB write is performed.

No schema migration is performed.

No job is claimed.

No helper, adapter, model, scheduler, or worker action is performed.

## Baseline

Latest completed checkpoint before E3V-E:

    HEAD/origin/main: 94f56b2
    tag: controller-stage-16-e3v-d-option-b-atomic-status-claim-implementation-plan-no-apply-2026-06-21

E3V-D defined the implementation boundary for:

    ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh

E3V-E defines what that future wrapper should contain before it is created in E3V-F.

## Required future wrapper path

The future wrapper path should be:

    ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh

The future smoke path should be:

    ops/smoke/check-stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh

The future wrapper must default to refusal unless explicitly approved.

## Wrapper mode design

The wrapper should support these modes:

    --dry-run
    --execute-approved

The default behavior with no mode must be refusal.

Dry-run mode must:

- perform only read-only checks
- avoid DB writes
- avoid helper calls
- avoid adapter calls
- avoid model calls
- avoid scheduler activation
- avoid worker activation

Execute-approved mode must require:

    APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY

If that approval phrase is absent or mismatched, the wrapper must refuse before any DB write.

## Required environment inputs

The future wrapper should accept or derive:

    EXPECTED_HEAD
    EXPECTED_SELECTED_JOB_ID
    EXPECTED_MODEL
    RUN_ROOT
    PVEW_SSH
    CTID
    CT203_DB_PATH
    PVESO_TS_SSH
    MAX_RUNTIME_SECONDS
    APPROVAL

Recommended defaults:

    CTID=203
    CT203_DB_PATH=/var/lib/edge-queue-controller/edge_queue.sqlite3
    EXPECTED_MODEL=qwen2.5:32b-instruct-q4_K_M
    RUN_ROOT=/tmp
    MAX_RUNTIME_SECONDS=7200

The wrapper must not require pveso DNS resolution because pveso hostname resolution has already failed before.

It should derive PVESO from Tailscale status or accept root@Tailscale-target explicitly.

## Required high-level flow

The future wrapper should run this sequence:

1. create durable run_dir
2. write recovery_hint.txt
3. verify repo checkpoint and clean tree
4. verify approval boundary
5. verify scheduler and persistent workers disabled
6. verify CT101 stopped/onboot=0
7. verify PVESO Ollama private localhost-only state
8. run read-only scheduler selection gate
9. require exactly one eligible selected queued model job
10. reject forbidden job ids
11. run DB atomic claim transaction
12. require changes() == 1
13. read selected job after claim
14. run one-shot PVESO adapter for claimed job prompt/model
15. complete exactly claimed job
16. insert exactly one job_results row
17. run CT203 read-only postflight
18. run PVESO/CT101 postflight
19. write final_status.txt
20. exit with explicit PASS marker

## Forbidden job ids

The future wrapper must refuse these job ids:

    23
    24
    27
    28

Reasons:

    job 23 remains queued but requested_model=gemma4:e4b is not allowlisted
    job 24 remains queued but requested_model=mock/no-model is not allowlisted
    job 27 already completed and must not be reused
    job 28 already completed and must not be rerun

## Candidate selection design

Normal execution should not take an arbitrary job id from the user.

The selected job id should come from scheduler selection logic.

For a controlled test, EXPECTED_SELECTED_JOB_ID may be used only as an assertion:

    scheduler_selected_job_id must equal EXPECTED_SELECTED_JOB_ID

If no expected job id is provided, the wrapper may proceed only if the scheduler gate returns exactly one eligible job and all other guards pass.

## Scheduler selection gate

The wrapper should reuse or call the E3S-style scheduler dry-run artifact.

Required output markers:

    NO_DB_WRITE
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    RUNTIME_CALLS=disabled
    SCHEDULER_ACTIVATION=not_performed
    PERSISTENT_WORKER_ACTIVATION=not_performed
    DB_INTEGRITY=ok
    ELIGIBLE_WOULD_CLAIM_COUNT=1
    WOULD_CLAIM job_id=<selected_id>

The wrapper must refuse if:

- no eligible job is selected
- more than one eligible job is selected
- selected job id is forbidden
- selected requested_model is not allowlisted
- selected job already has a result row
- selected status is not queued

## Model allowlist

Initial allowlist should contain only:

    qwen2.5:32b-instruct-q4_K_M

Adding other models requires separate readiness gates.

## Atomic claim implementation design

The atomic claim should run inside CT203 against the live DB.

Transaction shape:

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

Required result:

    changes() == 1

If changes() is not 1, the wrapper must not call the adapter or model.

## Claim postflight design

Immediately after claim, read back the selected job.

Required state:

    status=running
    attempts increased by exactly one
    requested_model matches expected model
    result_rows=0

If any condition fails, the wrapper must stop before model dispatch.

## Adapter call design

The future wrapper should call the already-proven one-shot adapter path, not a persistent worker.

Adapter requirements:

    no scheduler activation
    no persistent worker activation
    no model pull
    no public Ollama exposure
    CT101 stopped/onboot=0
    PVESO Ollama localhost-only
    requested_model already present
    response_text non-empty

The adapter must receive the claimed job prompt and expected model.

## Completion implementation design

Because the job is already claimed as running, the completion path must be claim-aware.

It must not require the job to still be queued.

Candidate success transaction:

    BEGIN IMMEDIATE;
    SELECT COUNT(*) FROM job_results WHERE job_id=:job_id;
    UPDATE jobs
    SET status='completed',
        last_error=NULL,
        updated_at=:now
    WHERE id=:job_id
      AND status='running'
      AND requested_model=:expected_model
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=:job_id
      );
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
    );
    COMMIT;

Postconditions:

    job status=completed
    job attempts=<claimed_attempts>
    job_results rows for job=1
    result model matches expected model
    result error is NULL or empty
    response_text is non-empty

## Failure handling design

If the adapter returns a real error and no result row exists, the wrapper may classify:

    running -> failed

Candidate failure transaction:

    BEGIN IMMEDIATE;
    UPDATE jobs
    SET status='failed',
        last_error=:error_summary,
        updated_at=:now
    WHERE id=:job_id
      AND status='running'
      AND NOT EXISTS (
        SELECT 1 FROM job_results WHERE job_id=:job_id
      );
    COMMIT;

The wrapper must not mark failed after a timeout unless read-only recovery confirms no completion occurred.

## Timeout behavior

If the wrapper times out, the next step must be read-only recovery only.

The wrapper recovery hint must say:

    DO_NOT_RERUN
    RUN_READ_ONLY_RECOVERY_FIRST

Recovery classifications:

    completed_with_one_result_do_not_rerun
    running_zero_results_runner_active_do_not_rerun
    running_zero_results_no_runner_manual_recovery_required
    queued_zero_results_no_claim_new_approval_required
    failed_zero_results_do_not_rerun_without_review
    duplicate_result_failure_do_not_rerun
    ambiguous_preserve_artifacts_do_not_rerun

## PVESO preflight design

Before dispatch, PVESO checks must verify:

    PVESO target found through Tailscale
    SSH works
    ollama.service active
    127.0.0.1:11434 listener present
    non-localhost 11434 listener count is 0
    runner process count is 0
    target model present
    no model pull performed

Postflight must verify:

    ollama.service active
    non-localhost 11434 listener count is 0
    runner or adapter process count is 0

## CT101 design

Before and after dispatch:

    CT101_STATUS=stopped
    CT101_ONBOOT=0

The wrapper must never start CT101.

## Required artifacts

Future run_dir should include:

    recovery_hint.txt
    repo_preflight.txt
    approval_preflight.txt
    scheduler_worker_disabled_preflight.txt
    ct203_db_stat_before.txt
    scheduler_selection_before.txt
    selected_job_before_claim.txt
    pveso_preflight.txt
    ct101_preflight.txt
    atomic_claim.sql.txt
    atomic_claim_result.txt
    selected_job_after_claim.txt
    adapter.stdout.raw.txt
    adapter.stderr.raw.txt
    adapter.rc.txt
    completion.sql.txt
    completion_result.txt
    selected_job_after_completion.txt
    ct203_db_stat_after.txt
    pveso_postflight.txt
    ct101_postflight.txt
    final_status.txt

## Required PASS marker

The future successful wrapper should print:

    E3V_OPTION_B_ATOMIC_CLAIM_ONE_SHOT_DISPATCH_OK

It should also print:

    selected_job_id=<id>
    claim_changes=1
    completion_changes=1
    job_results_for_job_after=1
    pveso_runner_count_after=0
    ct101_status_after=stopped
    ct101_onboot_after=0

## Required refusal markers

The future wrapper should emit clear refusal markers, including:

    REFUSE_APPROVAL_MISSING
    REFUSE_REPO_CHECKPOINT_MISMATCH
    REFUSE_REPO_DIRTY
    REFUSE_SCHEDULER_ACTIVE
    REFUSE_PERSISTENT_WORKERS_ACTIVE
    REFUSE_CT101_NOT_STOPPED
    REFUSE_PVESO_UNAVAILABLE
    REFUSE_OLLAMA_NOT_LOCALHOST_ONLY
    REFUSE_MODEL_MISSING
    REFUSE_NO_ELIGIBLE_JOB
    REFUSE_MULTIPLE_ELIGIBLE_JOBS
    REFUSE_FORBIDDEN_JOB_ID
    REFUSE_SELECTED_JOB_NOT_QUEUED
    REFUSE_SELECTED_JOB_HAS_RESULT
    REFUSE_ATOMIC_CLAIM_NOT_ONE
    REFUSE_COMPLETION_NOT_ONE

## Static smoke requirements for E3V-F

E3V-F should create the wrapper as a static no-runtime artifact and a smoke that checks:

- approval phrase string
- required refusal markers
- forbidden job ids
- atomic claim SQL shape
- completion SQL shape
- timeout recovery classifications
- PVESO localhost-only guard
- CT101 stopped/onboot guard
- no persistent scheduler activation
- no persistent worker activation
- final PASS marker
- no hardcoded pveso DNS dependency

E3V-F still should not run a model or write the DB.

## E3V-E result

E3V-E performs no apply.

It does not create the runtime wrapper.

It does not write the DB.

It does not claim a job.

It does not run an adapter.

It does not call a model.

It does not activate scheduler or workers.

It defines the code design contract for E3V-F.
