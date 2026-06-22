# Stage 16 E3Z-EF — Insert One Fresh Limited Persistent Worker Proof Job Only

## Purpose

Insert exactly one fresh queued CT203 job for the future limited persistent CT101 worker one-job proof.

This stage did not call models, start workers, enable workers, unmask services, claim jobs, complete jobs, fail jobs, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Approval

```text
APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY
```

## Inserted job

```text
job_id: 47
job_type: stage16_e3z_limited_persistent_worker_one_job_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
status: queued
attempts: 0
result_rows: 0
```

## Verified CT203 state after insert

Expected post-insert DB state:

```text
db_integrity: ok
jobs_total: 46
job_results_total: 26
jobs_status_running: 0
jobs_max_id: 47
job 47 queued attempts=0 result_rows=0
job 45 completed attempts=1 result_rows=1 response=E3Z-WORKER-QWEN25-ONE-SHOT-OK
job 46 completed attempts=1 result_rows=1 response=E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
```

## Verified CT101 profile/runtime state

Expected CT101 state after insert:

- qwen25_router_small includes stage16_e3z_limited_persistent_worker_one_job_proof
- qwen3_router_small does not include stage16_e3z_limited_persistent_worker_one_job_proof
- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- no active transient worker units
- only ollama container running
- worker self-test passes
- disabled worker refuses with REFUSE_WORKER_DISABLED

## Next step

Proceed with EG: run limited persistent worker service exact job 47 only.

EG is a real worker/model/claim/complete activation and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_47_ONLY
```

## Non-goals

Do not call models in EF.

Do not start CT101 worker service in EF.

Do not enable or unmask CT101 worker services in EF.

Do not claim job 47 in EF.

Do not complete job 47 in EF.

Do not activate scheduler or timer in EF.

Do not enable model concurrency in EF.

Do not insert more than one job in EF.

Do not rerun jobs 37 through 46.
