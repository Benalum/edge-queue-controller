# Stage 16 E3Z-EJ-C-R8 — Reset Job 48 and Repair Prompt to Worker Marker Regex Only

## Purpose

Repair job 48 after R6/R7 proved the worker expected the marker to be extractable from this regex:

```text
nothing else:\s*([A-Za-z0-9_.:-]+)\s*$
```

This stage performed one narrow CT203 DB repair only:

```text
target job: 48 only
updated_fields: status,prompt,updated_at,last_error
status: running -> queued
attempts: preserved at 2
result_rows: preserved at 0
job_results: no rows created
model calls: none
worker starts: none
```

## Approval

```text
APPROVE_STAGE_16_E3Z_EJ_C_R8_RESET_JOB48_AND_REPAIR_PROMPT_TO_WORKER_MARKER_REGEX_ONLY
```

## Prompt repair

The repaired prompt ends with:

```text
Return exactly this text and nothing else: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
```

This matches the installed worker extractor and returns:

```text
E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
```

## Pre-repair state

```text
job_48_before=status:running;attempts:2;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1;prompt_sha256:06a508e24928649dd0e8d4f5431b2f4d75dcf09f631586078a2bdf28d4b9d043;worker_regex_match:0
```

## Post-repair state

```text
job_48_after=status:queued;attempts:2;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1;prompt_sha256:7b2fba8c760ec59a8063ccc3c730077cf2908257ed6f2b3a136b0e317909df6d;worker_regex_match:1
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

Expected DB posture after R8:

```text
db_integrity: ok
jobs_total: 47
job_results_total: 27
jobs_status_running: 0
jobs_max_id: 48
job 48 queued attempts=2 result_rows=0 worker_regex_match=1
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

Expected CT101 posture after R8:

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

R8 did not rerun job 48.

R8 did not call a model.

R8 did not start any worker.

R8 did not claim, complete, or fail job 48.

R8 did not insert a replacement job.

R8 did not mutate jobs 37 through 47.

R8 did not activate scheduler or timer.

## Next step

Proceed with EJ-C-R9: retry repeat limited persistent worker service exact job 48 only after regex-compatible prompt repair.

EJ-C-R9 is a real worker/model/claim/complete activation and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EJ_C_R9_RETRY_REPEAT_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_48_AFTER_REGEX_PROMPT_REPAIR
```
