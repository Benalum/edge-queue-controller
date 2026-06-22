# Stage 16 E3Z-EE — Add Limited Persistent Job Type to Qwen25 Profile — No Worker Start

## Purpose

Add the limited persistent worker proof job type to the qwen25 model profile while preserving disabled-only runtime posture.

This stage did not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Approval

```text
APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

## Added job type

```text
job_type: stage16_e3z_limited_persistent_worker_one_job_proof
requested_model: qwen2.5:0.5b
future_expected_response: E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
profile: qwen25_router_small
repo_profile_sha256: c22694c22485a34cd431de0d9d6b72074cf44b089ba1f7d300efa7e44698ca4a
installed_profile_sha256: c22694c22485a34cd431de0d9d6b72074cf44b089ba1f7d300efa7e44698ca4a
```

## Profile validation

Expected profile state:

- qwen25_router_small includes stage16_e3z_limited_persistent_worker_one_job_proof
- qwen25_router_small still uses qwen2.5:0.5b
- qwen25_router_small still has claim_policy one_at_a_time
- qwen25_router_small remains enabled_by_default false
- qwen3_router_small does not include stage16_e3z_limited_persistent_worker_one_job_proof
- installed worker self-test passes against updated profile

## Runtime posture after profile update

Expected CT101 state after profile update:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- no active transient worker units
- only ollama container running
- disabled worker refuses with REFUSE_WORKER_DISABLED

## CT203 DB unchanged

Expected CT203 state after profile update:

```text
db_integrity: ok
jobs_total: 45
job_results_total: 26
jobs_status_running: 0
jobs_max_id: 46
job 45 completed attempts=1 result_rows=1 response=E3Z-WORKER-QWEN25-ONE-SHOT-OK
job 46 completed attempts=1 result_rows=1 response=E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
```

## Next step

Proceed with EF: insert one fresh limited persistent worker proof job only.

EF is a CT203 DB insert mutation and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY
```

## Non-goals

Do not call models in EE.

Do not mutate CT203 DB in EE.

Do not insert any jobs in EE.

Do not claim any jobs in EE.

Do not start CT101 worker service in EE.

Do not enable or unmask CT101 worker services in EE.

Do not activate scheduler or timer in EE.

Do not enable persistent worker behavior in EE.

Do not enable model concurrency.
