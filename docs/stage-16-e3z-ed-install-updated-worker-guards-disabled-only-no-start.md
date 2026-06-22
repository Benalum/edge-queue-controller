# Stage 16 E3Z-ED — Install Updated Worker Guards Disabled Only — No Start

## Purpose

Install the updated CT101 worker guard implementation from repo checkpoint EC-R2 onto CT101 while preserving disabled-only posture.

This stage did not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Approval

```text
APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START
```

## Installed file

```text
path: /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
repo_sha256: 69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f
installed_sha256: 69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f
```

## Installed guard features

The installed CT101 worker now includes:

```text
EDGE_ALLOWED_JOB_IDS
EDGE_EXIT_AFTER_ONE_SUCCESS
EDGE_MAX_RUNTIME_SECONDS
EDGE_REFUSE_IF_SCHEDULER_ACTIVE
EDGE_REFUSE_IF_TIMER_ACTIVE
EDGE_PROOF_MODE=limited_persistent_one_job
REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED
E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1
```

## Validated disabled-only posture

Expected CT101 state after install:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- no active transient worker units
- only ollama container running
- worker self-test passes on CT101
- disabled worker refuses with REFUSE_WORKER_DISABLED

## CT203 DB unchanged

Expected CT203 state after install:

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

Proceed with EE: add limited persistent proof job type to the qwen25 profile, no worker start.

EE is a live CT101 profile update and requires explicit approval:

```text
APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

## Non-goals

Do not call models in ED.

Do not mutate CT203 DB in ED.

Do not insert any jobs in ED.

Do not claim job 46 again.

Do not start CT101 worker service in ED.

Do not enable or unmask CT101 worker services in ED.

Do not activate scheduler or timer in ED.

Do not enable persistent worker behavior in ED.

Do not enable model concurrency.
