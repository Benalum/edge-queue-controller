# Stage 16 E3Z-EJ-C-R3 — Stuck-Running Job 48 Repair Decision — No Apply

## Purpose

Classify the failed EJ-C repeat proof state and define the next repair boundary without mutating live state.

EJ-C failed safely at the worker guard with:

```text
REFUSE_WORKER_EXACT_MARKER_MISMATCH
```

EJ-C-R2 showed the important state:

```text
job_48=status:running;attempts:1;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1
```

## Scope

This phase was read-only for live state:

- no CT203 DB mutation
- no model call
- no job insert
- no job claim
- no job complete
- no job fail
- no worker start
- no worker enable
- no worker unmask
- no scheduler/timer activation
- no Docker/model data mutation

## Classification

Observed DB state:

```text
db_integrity=ok
jobs_total=47
job_results_total=27
jobs_status_running=1
jobs_status_queued=2
jobs_status_failed=3
jobs_status_completed=21
jobs_max_id=48
job_48_status=running
job_48_attempts=1
job_48_requested_model=qwen2.5:0.5b
job_48_job_type=stage16_e3z_limited_persistent_worker_repeat_proof
job_48_result_rows=0
job_48_marker_present=1
```

Observed CT101 idle state:

```text
old_worker_active=inactive
old_worker_enabled=masked
new_worker_active=inactive
new_worker_enabled=disabled
running_names=ollama
active_transients=<none>
edge_timers=<none>
unit_active=inactive
unit_state=not-found,inactive,dead
disabled_refusal_rc=1
```

This classifies job 48 as a stale running claim left by a bounded worker process that exited after marker mismatch. No worker, transient, scheduler, or timer remained active.

## Repair choice

The safe repair is to reset only job 48 from stale running back to queued for one controlled retry, because:

- job 48 has result_rows=0
- job 48 already has attempts=1 from the failed claim
- the marker is present in its prompt
- the worker process is gone
- no active transient remains
- no scheduler/timer is active
- jobs 45, 46, and 47 remain completed and must not be touched

## Required repair mutation

EJ-C-R4 should perform one narrow DB repair only:

```text
target job: 48 only
required current status: running
required current attempts: 1
required current result_rows: 0
required requested_model: qwen2.5:0.5b
required job_type: stage16_e3z_limited_persistent_worker_repeat_proof
required marker: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
repair action: set status=queued, clear running/claim/lock fields when present, keep attempts=1, do not create job_results
post repair expected: job 48 queued attempts=1 result_rows=0
```

The retry must then run a corrected exact output strategy. Do not blindly rerun the same command until the marker-mismatch cause is addressed.

## Likely cause

The qwen2.5 output did not exactly equal the new repeat marker, even though previous qwen25 markers succeeded. The retry should use a stricter prompt/worker invocation strategy or inspect the worker model-call response path if available.

## Next approval boundary

Proceed with EJ-C-R4 only after explicit approval:

```text
APPROVE_STAGE_16_E3Z_EJ_C_R4_RESET_STALE_RUNNING_JOB_48_TO_QUEUED_ONLY
```

## Non-goals

Do not rerun job 48 in R4.

Do not call models in R4.

Do not complete or fail job 48 in R4.

Do not insert a replacement job in R4.

Do not mutate jobs 37 through 47.

Do not start workers in R4.

Do not activate scheduler or timer in R4.
