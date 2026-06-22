# Stage 16 E3Z-EJ-A — Add Repeat Limited Persistent Job Type to Qwen25 Profile — No Worker Start

## Purpose

Add the repeat-specific limited persistent worker proof job type to the qwen25 model profile while preserving disabled-only runtime posture.

This stage did not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Approval

```text
APPROVE_STAGE_16_E3Z_EJ_A_ADD_REPEAT_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

## Added job type

```text
job_type: stage16_e3z_limited_persistent_worker_repeat_proof
requested_model: qwen2.5:0.5b
future_expected_response: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
profile: qwen25_router_small
repo_profile_sha256: 329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
installed_profile_sha256: 329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
```

## Preserved prior proof type

```text
previous_job_type: stage16_e3z_limited_persistent_worker_one_job_proof
previous_expected_response: E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

## Profile validation

Expected profile state:

- qwen25_router_small includes stage16_e3z_limited_persistent_worker_repeat_proof
- qwen25_router_small still includes stage16_e3z_limited_persistent_worker_one_job_proof
- qwen25_router_small still uses qwen2.5:0.5b
- qwen25_router_small still has claim_policy one_at_a_time
- qwen25_router_small remains enabled_by_default false
- qwen3_router_small does not include stage16_e3z_limited_persistent_worker_repeat_proof
- installed worker self-test passes against updated profile

## Runtime posture after profile update

Expected CT101 state after profile update:

- old ai-platform-laptop-queue-worker.service inactive and masked
- installed edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- no active transient worker units
- no edge/worker/scheduler timers
- only ollama container running
- disabled worker refuses with REFUSE_WORKER_DISABLED

## CT203 DB unchanged

Expected CT203 state after profile update:

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

## Next step

Proceed with EJ-B: insert one fresh repeat limited persistent worker proof job only.

EJ-B is a CT203 DB insert mutation and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EJ_B_INSERT_ONE_FRESH_REPEAT_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY
```

Expected next job:

```text
job_id: 48
job_type: stage16_e3z_limited_persistent_worker_repeat_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
status: queued
attempts: 0
result_rows: 0
```

## Non-goals

Do not call models in EJ-A.

Do not mutate CT203 DB in EJ-A.

Do not insert any jobs in EJ-A.

Do not claim any jobs in EJ-A.

Do not start CT101 worker service in EJ-A.

Do not enable or unmask CT101 worker services in EJ-A.

Do not activate scheduler or timer in EJ-A.

Do not enable model concurrency in EJ-A.

Do not rerun jobs 37 through 47.
