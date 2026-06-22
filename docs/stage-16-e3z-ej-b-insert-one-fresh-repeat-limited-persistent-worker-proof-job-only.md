# Stage 16 E3Z-EJ-B — Insert One Fresh Repeat Limited Persistent Worker Proof Job Only

## Purpose

Insert exactly one fresh queued CT203 job for the repeat limited persistent CT101 worker one-job proof.

This stage did not call models, start workers, enable workers, unmask services, claim jobs, complete jobs, fail jobs, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Approval

```text
APPROVE_STAGE_16_E3Z_EJ_B_INSERT_ONE_FRESH_REPEAT_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY
```

## Inserted job

```text
job_id: 48
job_type: stage16_e3z_limited_persistent_worker_repeat_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
status: queued
attempts: 0
result_rows: 0
```

## Verified CT203 state after insert

Expected post-insert DB state:

```text
db_integrity: ok
jobs_total: 47
job_results_total: 27
jobs_status_running: 0
jobs_max_id: 48
job 48 queued attempts=0 result_rows=0
job 45 completed attempts=1 result_rows=1 response=E3Z-WORKER-QWEN25-ONE-SHOT-OK
job 46 completed attempts=1 result_rows=1 response=E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
job 47 completed attempts=1 result_rows=1 response=E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

## Verified CT101 profile/runtime state

Expected CT101 state after insert:

- qwen25_router_small includes stage16_e3z_limited_persistent_worker_repeat_proof
- qwen25_router_small still includes stage16_e3z_limited_persistent_worker_one_job_proof
- qwen3_router_small does not include stage16_e3z_limited_persistent_worker_repeat_proof
- old ai-platform-laptop-queue-worker.service inactive and masked
- installed edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- no active transient worker units
- no edge/worker/scheduler timers
- only ollama container running
- worker self-test passes
- disabled worker refuses with REFUSE_WORKER_DISABLED

## Next step

Proceed with EJ-C: run repeat limited persistent worker service exact job 48 only.

EJ-C is a real worker/model/claim/complete activation and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EJ_C_RUN_REPEAT_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_48_ONLY
```

## Non-goals

Do not call models in EJ-B.

Do not start CT101 worker service in EJ-B.

Do not enable or unmask CT101 worker services in EJ-B.

Do not claim job 48 in EJ-B.

Do not complete job 48 in EJ-B.

Do not activate scheduler or timer in EJ-B.

Do not enable model concurrency in EJ-B.

Do not insert more than one job in EJ-B.

Do not rerun jobs 37 through 47.
