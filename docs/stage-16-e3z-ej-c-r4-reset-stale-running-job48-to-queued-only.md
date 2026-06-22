# Stage 16 E3Z-EJ-C-R4 — Reset Stale Running Job 48 to Queued Only

## Purpose

Repair the stale running claim left after EJ-C failed with an exact-marker mismatch.

This stage performed one narrow CT203 DB repair only:

```text
target job: 48 only
repair action: status running -> queued
attempts: preserved at 1
result_rows: preserved at 0
job_results: no rows created
cleared_fields: updated_at
```

## Approval

```text
APPROVE_STAGE_16_E3Z_EJ_C_R4_RESET_STALE_RUNNING_JOB_48_TO_QUEUED_ONLY
```

## Pre-repair state

```text
job_48_before=status:running;attempts:1;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1
```

## Post-repair state

```text
job_48_after=status:queued;attempts:1;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1
```

## CT203 post-repair summary

```text
db_integrity_after=ok
jobs_total_after=47
job_results_total_after=27
jobs_status_running_after=0
jobs_status_queued_after=3
jobs_status_failed_after=3
jobs_status_completed_after=21
jobs_max_id_after=48
```

Expected DB posture after R4:

```text
db_integrity: ok
jobs_total: 47
job_results_total: 27
jobs_status_running: 0
jobs_max_id: 48
job 48 queued attempts=1 result_rows=0
jobs 45, 46, 47 remain completed attempts=1 result_rows=1
```

## CT101 post-repair idle guard

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
```

Expected CT101 posture after R4:

- old ai-platform-laptop-queue-worker.service inactive and masked
- installed edge-ct101-ollama-worker.service inactive and disabled
- no active transient worker units
- no edge/worker/scheduler timers
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- only ollama container running
- disabled worker refuses with REFUSE_WORKER_DISABLED

## Non-goals

R4 did not rerun job 48.

R4 did not call a model.

R4 did not start any worker.

R4 did not complete or fail job 48.

R4 did not insert a replacement job.

R4 did not mutate jobs 37 through 47.

R4 did not activate scheduler or timer.

## Next step

Proceed with EJ-C-R5: corrected retry plan for exact job 48 only.

The retry should address the exact-marker mismatch before executing another model call.

Potential safe correction options:

1. Keep job 48 but update only the prompt to an even stricter exact-output instruction before retry.
2. Use the worker's existing exact marker validation and run the same single-job transient after prompt repair.
3. If prompt-only repair is not enough, create a new replacement proof job instead of repeatedly incrementing attempts on job 48.

The next live retry or prompt repair requires a separate explicit approval.
