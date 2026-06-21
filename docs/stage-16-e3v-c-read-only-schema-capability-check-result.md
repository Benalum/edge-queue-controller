# Stage 16 E3V-C — Read-Only Schema Capability Check Result

## Result

E3V-C completed successfully.

The CT203 live DB schema was inspected read-only to determine whether it can support the E3V-B recommended Option B design:

    atomic status transition claim using existing fields

No DB write was performed.

No schema migration was performed.

No runtime dispatch was performed.

Final result:

    E3V_C_SCHEMA_CAPABILITY_RESULT=OPTION_B_SCHEMA_CAPABLE_FOR_NO_SCHEMA_ONE_SHOT_DESIGN
    E3V_C_READ_ONLY_SCHEMA_CAPABILITY_OK
    E3V_C_READ_ONLY_SCHEMA_CAPABILITY_CHECK_OK

## Repo checkpoint

Before this documentation step:

    HEAD/origin/main/remote: f912e81
    Previous tag: controller-stage-16-e3v-b-claim-lease-design-comparison-no-apply-2026-06-21
    Working tree: clean

## Safety boundary

The E3V-C check was read-only only.

Denied actions remained denied:

- no DB write
- no schema migration
- no job insert
- no DB claim
- no helper call
- no adapter call
- no model call
- no scheduler activation
- no persistent worker activation
- no CT101 start
- no service/CT/VM/Cloudflare/private-storage mutation

## DB open mode and integrity

The CT203 DB was opened with immutable read-only SQLite URI mode.

Markers:

    STAGE=stage-16-e3v-c-ct203-schema-capability-read-only
    NO_DB_WRITE
    NO_SCHEMA_MIGRATION
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    DB_PATH=/var/lib/edge-queue-controller/edge_queue.sqlite3
    DB_INTEGRITY=ok
    SQLITE_VERSION=3.46.1

The DB stat remained unchanged before and after the check:

    before=43798528 1782066624 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782066624 /var/lib/edge-queue-controller/edge_queue.sqlite3

## Current jobs table columns

The live jobs table has the required fields for Option B atomic status transition design:

    JOBS_COLUMN name=id type=INTEGER pk=1
    JOBS_COLUMN name=job_type type=TEXT notnull=1
    JOBS_COLUMN name=prompt type=TEXT notnull=1
    JOBS_COLUMN name=requested_model type=TEXT
    JOBS_COLUMN name=status type=TEXT notnull=1 default='queued'
    JOBS_COLUMN name=attempts type=INTEGER notnull=1 default=0
    JOBS_COLUMN name=last_error type=TEXT
    JOBS_COLUMN name=created_at type=TEXT notnull=1
    JOBS_COLUMN name=updated_at type=TEXT notnull=1
    JOBS_COLUMN name=forwarded_at type=TEXT
    JOBS_COLUMN name=user_id type=INTEGER

Option B required columns were present:

    OPTION_B_REQUIRED_COLUMNS_PRESENT=True
    OPTION_B_REQUIRED_COLUMNS_MISSING=none
    OPTION_B_USEFUL_COLUMNS_PRESENT=created_at,forwarded_at,job_type,last_error,prompt,requested_model,user_id

## Current job_results table columns

The live job_results table has:

    JOB_RESULTS_COLUMN name=job_id type=INTEGER pk=1
    JOB_RESULTS_COLUMN name=model type=TEXT
    JOB_RESULTS_COLUMN name=response_text type=TEXT
    JOB_RESULTS_COLUMN name=response_json type=TEXT
    JOB_RESULTS_COLUMN name=error type=TEXT
    JOB_RESULTS_COLUMN name=created_at type=TEXT notnull=1
    JOB_RESULTS_COLUMN name=updated_at type=TEXT notnull=1

Markers:

    JOB_RESULTS_HAS_JOB_ID_COLUMN=true
    JOB_RESULTS_UNIQUE_JOB_ID_INDEX_PRESENT=false

Important interpretation:

    job_results.job_id is the primary key in the table schema, so duplicate result rows for the same job are structurally constrained by the table primary key even though no separate unique index was reported by PRAGMA index_list.

The E3V design should still keep explicit duplicate-result guards before and after runtime.

## Lease columns

Dedicated Option C lease columns are not present:

    OPTION_C_LEASE_COLUMNS_PRESENT=none
    OPTION_C_LEASE_COLUMNS_ABSENT=claimed_at,claimed_by,dispatch_completed_at,dispatch_started_at,lease_expires_at,lease_owner,lease_token
    OPTION_C_MIGRATION_REQUIRED_FOR_DEDICATED_LEASE=true

Interpretation:

    Option C remains the stronger long-term persistent scheduler path, but it requires a separate DB migration approval.

## Current counts and statuses

Current DB counts:

    JOBS_TOTAL=27
    JOB_RESULTS_TOTAL=10

Status counts:

    JOB_STATUS_COUNT status=completed count=4
    JOB_STATUS_COUNT status=failed count=1
    JOB_STATUS_COUNT status=forwarded count=20
    JOB_STATUS_COUNT status=queued count=2

Duplicate result scan:

    DUPLICATE_JOB_RESULTS none

## Important job classifications

Older queued rejected jobs remain queued:

    JOB_CLASSIFY id=23 present=true status=queued attempts=3 job_type='ollama_chat' requested_model='gemma4:e4b' result_rows=0
    JOB_CLASSIFY id=24 present=true status=queued attempts=0 job_type='companion.chat' requested_model='mock/no-model' result_rows=0

Completed model-dispatch proof jobs:

    JOB_CLASSIFY id=27 present=true status=completed attempts=1 job_type='stage16_e3p_operator_dispatch_synthetic_model_smoke' requested_model='qwen2.5:32b-instruct-q4_K_M' result_rows=1
    JOB_CLASSIFY id=28 present=true status=completed attempts=1 job_type='stage16_e3t_scheduler_dry_run_eligible_model_smoke' requested_model='qwen2.5:32b-instruct-q4_K_M' result_rows=1

Do not rerun job 27.

Do not rerun job 28.

## Option B atomic SQL shape

The read-only schema check generated this candidate SQL shape:

    UPDATE jobs SET status='running', attempts=attempts+1, updated_at=? WHERE id=? AND status='queued' AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=?)

Markers:

    OPTION_B_ATOMIC_SQL_SHAPE=UPDATE jobs SET status='running', attempts=attempts+1, updated_at=? WHERE id=? AND status='queued' AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=?)
    OPTION_B_SCHEMA_CAPABLE=true
    OPTION_B_RUNTIME_APPLY_PERFORMED=false

Interpretation:

    The current schema can support a no-schema Option B one-shot implementation design.

But E3V-C did not apply it.

## Persistent activation remains blocked

E3V-C confirmed:

    PERSISTENT_SCHEDULER_ACTIVATION_ALLOWED=false
    PERSISTENT_WORKER_ACTIVATION_ALLOWED=false

Persistent scheduler activation remains blocked until:

- atomic claim behavior is implemented and proven
- timeout recovery is implemented and proven
- duplicate result prevention is proven
- public API/UI behavior is safe
- observability is stable
- rollback/recovery procedure exists

## Next recommended phase

Recommended next phase:

    E3V-D no-apply Option B atomic-status-claim implementation plan

E3V-D should define exactly how to safely perform a single scheduler-selected atomic status transition claim without schema migration.

It should remain no-apply unless separately approved.

A future apply approval should be separate and explicit:

    APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY

That future approval should allow at most:

- one atomic claim attempt for one scheduler-selected eligible queued job
- one helper call
- one adapter call
- one localhost-only PVESO model call
- one CT203 job completion
- one CT203 job_results insert

It must still deny:

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

## E3V-C conclusion

E3V-C was read-only and successful.

The current schema is capable of supporting the near-term Option B no-schema one-shot atomic claim design.

Option C dedicated leases remain the best long-term path before persistent scheduler activation, but require a separate migration approval.
