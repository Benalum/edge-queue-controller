# Stage 16 E3Z-EJ-C-R5 — Prompt Repair Job 48 Repeat Marker Only — No Worker Start

## Purpose

Repair only the prompt for job 48 after the first repeat limited persistent retry failed with an exact-marker mismatch.

This stage performed one narrow CT203 DB mutation only:

```text
target job: 48 only
updated_fields: prompt,updated_at
status: preserved as queued
attempts: preserved at 1
result_rows: preserved at 0
job_results: no rows created
model calls: none
worker starts: none
```

## Approval

```text
APPROVE_STAGE_16_E3Z_EJ_C_R5_PROMPT_REPAIR_JOB_48_REPEAT_MARKER_ONLY_NO_WORKER_START
```

## Prompt repair

The repaired prompt now instructs the model to return exactly one line, with no quotes, no Markdown, no code fence, no labels, no explanation, no punctuation, and no leading or trailing whitespace.

Required marker remains:

```text
E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
```

Prompt exact repair verification:

```text
job_48_prompt_repaired_exact=1
```

## Pre-repair state

```text
job_48_before=status:queued;attempts:1;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1;prompt_sha256:dcf36d018c12c67c4d1e46819a27cee1595230b388eb57edef6e0e600052ca5f
```

## Post-repair state

```text
job_48_after=status:queued;attempts:1;requested_model:qwen2.5:0.5b;job_type:stage16_e3z_limited_persistent_worker_repeat_proof;result_rows:0;marker_present:1;prompt_sha256:06a508e24928649dd0e8d4f5431b2f4d75dcf09f631586078a2bdf28d4b9d043
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

Expected DB posture after R5:

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

Expected CT101 posture after R5:

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

R5 did not rerun job 48.

R5 did not call a model.

R5 did not start any worker.

R5 did not claim, complete, or fail job 48.

R5 did not insert a replacement job.

R5 did not mutate jobs 37 through 47.

R5 did not activate scheduler or timer.

## Next step

Proceed with EJ-C-R6: retry repeat limited persistent worker service exact job 48 only after prompt repair.

EJ-C-R6 is a real worker/model/claim/complete activation and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EJ_C_R6_RETRY_REPEAT_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_48_ONLY
```
