# Stage 16 E3Z-EH — Read-Only Postflight Idle Guard After Limited Persistent Proof

## Purpose

Confirm that the limited persistent CT101 worker proof left the platform in a safe idle state.

This stage is read-only for live infrastructure and DB state. It did not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Proven state

Stage 16 E3Z-EG completed the first bounded limited-persistent worker proof:

```text
job 47 completed attempts=1 result_rows=1 response=E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1
```

## Read-only guard result

EH verified:

```text
db_integrity: ok
jobs_total: 46
job_results_total: 27
jobs_status_running: 0
jobs_max_id: 47
job 45 completed attempts=1 result_rows=1 response=E3Z-WORKER-QWEN25-ONE-SHOT-OK
job 46 completed attempts=1 result_rows=1 response=E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
job 47 completed attempts=1 result_rows=1 response=E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

## CT101 idle state

EH verified:

- old ai-platform-laptop-queue-worker.service inactive and masked
- installed edge-ct101-ollama-worker.service inactive and disabled
- no active transient worker units
- no edge/queue/worker/scheduler timers active
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- only ollama container running
- qwen25 profile includes stage16_e3z_limited_persistent_worker_one_job_proof
- qwen3 profile excludes stage16_e3z_limited_persistent_worker_one_job_proof
- worker self-test passes
- disabled worker refuses with REFUSE_WORKER_DISABLED

## Quiet-window result

EH sampled CT203 DB and CT101 runtime state twice across a quiet window and confirmed the signatures stayed stable:

```text
E3Z_EH_READ_ONLY_POSTFLIGHT_IDLE_GUARD_OK=1
```

## Next step

Proceed with EI: design the next controlled expansion beyond one-job limited persistent proof.

Recommended options:

1. Run one more limited persistent proof job with the same controls to prove repeatability.
2. Add a second model/profile proof under the same one-job guard.
3. Design the first longer-lived but still bounded worker window with a small exact allowlist.
4. Start moving toward user-facing companion/study job types only after repeated low-level worker proof stability.

## Non-goals

Do not enable the installed persistent service yet.

Do not activate scheduler/timer yet.

Do not enable model concurrency yet.

Do not process open-ended queues yet.

Do not run jobs 37 through 47 again.
