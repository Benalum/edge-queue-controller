# Stage 16 E3V-B — Claim/Lease Design Comparison, No Apply

## Purpose

E3V-B compares safe claim/lease designs for turning the proven E3U one-shot scheduler-selected dispatch into a repeatable scheduler-controlled lane.

This is no-apply only.

No schema migration is performed.

No DB write is performed.

No helper, adapter, model, scheduler, or worker action is performed.

## Current proven baseline

E3U-C2 proved:

    CT203 queued job
    E3S scheduler dry-run selected exactly one eligible job
    controlled helper path ran exactly once
    PVESO one-shot adapter ran exactly once
    PVESO Ollama stayed localhost-only
    CT203 DB completed job 28
    CT203 inserted exactly one job_results row
    PVESO runner count returned to zero

Final E3U-C2 state:

    job_28_status=completed
    job_28_attempts=1
    job_28_result_rows=1
    job_results_total=10
    pveso_runner_count_after=0

Do not rerun job 28.

Do not reuse job 27.

## Current runtime posture

Scheduler activation has not been performed.

Persistent worker activation has not been performed.

Lane worker activation has not been performed.

CT101 remains stopped and onboot=0.

PVESO Ollama remains private and localhost-only.

## Current schema facts

The current live jobs table has the existing job lifecycle fields used by the helper path.

The current live schema does not yet have a dedicated durable claim/lease mechanism documented as active.

Earlier live schema observations showed jobs fields such as:

    id
    job_type
    prompt
    requested_model
    status
    attempts
    last_error
    created_at
    updated_at
    forwarded_at
    user_id

The repeatable scheduler-controlled lane needs either:

- a safe atomic use of existing fields, or
- a separately approved claim/lease migration.

## Design options

### Option A — Existing-status-only guarded one-shot lane

This option uses only existing DB fields.

Candidate selection stays read-only until the chosen job is dispatched through the existing helper path.

Guards:

    status=queued
    result_rows=0
    requested_model allowlisted
    scheduler dry-run would select exactly one job
    PVESO preflight passes
    CT101 stopped/onboot=0
    persistent scheduler disabled
    persistent workers disabled

Pros:

- no schema migration
- lowest DB-change surface
- builds directly on E3U success
- useful for another manually approved one-job scheduler-selected run

Cons:

- not safe enough for persistent scheduler activation
- no durable lease owner
- no durable lease expiry
- risk of duplicate dispatch if multiple schedulers/workers are ever enabled
- relies on external serialization and approval boundary

Verdict:

    Acceptable for another explicit one-shot approved dispatch.
    Not acceptable for persistent scheduler activation.

### Option B — Atomic status transition claim

This option uses an atomic UPDATE on existing status fields.

Example shape:

    UPDATE jobs
    SET status='running', attempts=attempts+1, updated_at=<now>
    WHERE id=<selected_job>
      AND status='queued'
      AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=<selected_job>)

Then the worker/helper completes the job or classifies failure.

Pros:

- no new columns
- uses existing status semantics
- can be atomic
- prevents two dispatchers from claiming the same queued job if all dispatchers obey the same UPDATE

Cons:

- no explicit lease expiry
- no claim owner
- harder timeout recovery
- a timed-out process may leave a job stuck in running
- requires careful recovery policy before persistent scheduler activation

Verdict:

    Good candidate for a near-term no-schema repeatable one-shot path.
    Still risky for persistent unattended scheduling unless recovery semantics are fully implemented.

### Option C — Add dedicated lease columns

This option adds durable claim/lease metadata.

Possible columns:

    lease_owner
    lease_token
    lease_expires_at
    claimed_at
    claimed_by
    dispatch_started_at
    dispatch_completed_at

Possible atomic claim shape:

    UPDATE jobs
    SET status='running',
        attempts=attempts+1,
        lease_owner=<scheduler_id>,
        lease_token=<random_token>,
        lease_expires_at=<timestamp>,
        claimed_at=<timestamp>,
        updated_at=<timestamp>
    WHERE id=<selected_job>
      AND status='queued'
      AND lease_owner IS NULL
      AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=<selected_job>)

Pros:

- strongest repeatability foundation
- supports crash recovery
- supports lease expiry
- supports auditability
- supports future persistent scheduler safely
- makes duplicate dispatch prevention explicit

Cons:

- requires schema migration
- requires migration backup and rollback plan
- requires code changes and smoke tests
- must be separately approved before apply

Verdict:

    Best long-term path before persistent scheduler activation.
    Must be a separately approved migration.

### Option D — Separate dispatch_claims table

This option leaves jobs unchanged and adds a new table.

Possible table:

    dispatch_claims(
      id,
      job_id,
      claim_token,
      claim_owner,
      status,
      claimed_at,
      expires_at,
      completed_at,
      recovery_state
    )

Pros:

- avoids altering jobs table
- can preserve complete dispatch audit history
- supports multiple claim attempts over time
- useful for observability

Cons:

- more complex joins
- must enforce uniqueness for active claims
- still requires schema migration
- requires more application code

Verdict:

    Strong audit option, but more complex than dedicated job lease columns.
    Better later if audit requirements grow.

## Recommended path

E3V-B recommends a staged path:

### Near-term path

Use Option B for the next no-apply implementation design:

    atomic status transition claim using existing fields

This can support a single approved repeatable scheduler-selected dispatch without adding schema yet.

But it must remain one-shot and explicitly approved.

It must not activate a persistent scheduler.

It must not activate persistent workers.

### Long-term path

Use Option C before persistent scheduler activation:

    dedicated lease columns on jobs

This is the safer durable foundation for unattended scheduler operation.

It requires a separately approved DB migration, including backup and rollback.

## Required gates for Option B

Before any Option B apply, a no-apply implementation plan must define:

- exact SQL atomic claim statement
- exact status values
- exact attempts behavior
- duplicate result guard before claim
- duplicate result guard after completion
- failure transition behavior
- timeout transition behavior
- recovery for stuck running jobs
- dry-run mode
- postflight classification
- no broad queue drain
- no job 28 rerun
- no job 27 reuse
- no dispatch of rejected jobs 23 or 24

## Required gates for Option C

Before any Option C migration apply, a no-apply migration plan must define:

- DB backup path
- migration SQL
- rollback SQL
- table/column verification
- idempotence checks
- no data loss guard
- post-migration integrity check
- scheduler code changes
- helper/worker compatibility
- recovery semantics
- explicit approval phrase

## Future approval boundaries

A future one-shot Option B apply should require:

    APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY

That approval should allow at most:

- one atomic claim attempt for one scheduler-selected eligible queued job
- one helper call
- one adapter call
- one localhost-only PVESO model call
- one CT203 job completion
- one CT203 job_results insert

It must deny:

- schema migration
- persistent scheduler activation
- persistent worker activation
- broad queue draining
- job 27 reuse
- job 28 rerun
- dispatch of rejected jobs 23 or 24
- CT101 start
- PVESO/Ollama public exposure
- service/CT/VM/Cloudflare/private-storage mutation

A future Option C migration apply should require a separate approval phrase.

## Scheduler activation boundary

Persistent scheduler activation remains blocked until:

    repeatable one-shot dispatch path is implemented
    atomic claim behavior is proven
    timeout recovery is proven
    duplicate result prevention is proven
    lease strategy is chosen
    public API/UI behavior is safe
    observability is stable
    rollback/recovery procedure exists

## E3V-B result

E3V-B performs no apply.

Recommended next phase:

    E3V-C read-only schema capability check

Then:

    E3V-D no-apply Option B atomic-status-claim implementation plan

Do not run another job until a new explicit approval is requested and granted.
