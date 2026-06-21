# Stage 16 E3Z-H R13 — Start Service Once, Exact Job 33, Restricted PVESO Helper

## Phase status

MUTATION_SCOPE: one service start, exact job 33, restricted PVESO helper model call, DB completion recovery, finalization, then repo docs/smoke/commit/tag/push.

Approval token:

```text
APPROVE_STAGE_16_E3Z_H_R13_START_SERVICE_ONCE_EXACT_JOB_33_RESTRICTED_PVESO_HELPER
```

R13 completed the direct service proof for exact job 33 through the restricted PVESO helper path.

## R13 attempt and recovery summary

The first R13 service attempt successfully:

- started `edge-queue-scheduler-one-shot.service` once
- claimed only job 33
- invoked the restricted PVESO helper
- called only model `qwen2.5:0.5b`
- captured model output from the helper
- finalized service/timer off
- reverted PVESO helper run mode to preflight-only

The first R13 service attempt failed only while inserting the DB result because the runner incorrectly skipped the primary-key `job_results.job_id` column.

R13B performed DB-only recovery using the already captured R13 service log output. R13B did not start the service, run the helper, or call a model.

## Service proof markers from captured R13 log

The captured service log included:

```text
R13_JOB_CLAIMED_EXACT=1
APC_E3Z_H_R13_MODEL_CALL_OK=1
APC_E3Z_H_R13_HELPER_RUN_OK=1
R13_MODEL_RESPONSE_DECODED=E3Z-H-R13-
```

R13B then inserted the missing `job_results` row for job 33 and marked job 33 completed.

## Final CT203 posture

After R13/R13B:

```text
service_active=inactive
timer_active=inactive
timer_enabled=disabled
env_delegation=0
r13_dropin_present=0
```

## Final helper posture

PVESO helper run mode is back to preflight-only:

```text
E3Z_H_R13B_HELPER_PREFLIGHT_ONLY_POSTURE=1
```

## DB postflight

Postflight DB state:

```text
db_integrity=ok
jobs_total=32
job_results_total=13
duplicate_job_results=0

job_23_status=queued
job_23_attempts=3
job_23_result_rows=0

job_24_status=queued
job_24_attempts=0
job_24_result_rows=0

job_33_status=completed
job_33_attempts=1
job_33_result_rows=1
job_33_type=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
job_33_model=qwen2.5:0.5b
```

## Not performed by R13B recovery

R13B did not:

- start the scheduler service
- start the scheduler timer
- execute scheduler/wrapper
- call the PVESO helper
- call Ollama generate/chat/embed/completion endpoints
- pull any model
- start CT101
- insert a new job
- claim any new job
- enable persistent workers
- mutate Cloudflare/DNS/tunnels/private storage

## Hard no-rerun rules

Do not retry or rerun:

- E3V-Q
- job 29
- job 30
- job 31
- job 32
- job 33

job 33 is now completed and must not be reused.

## Next recommended phase

The next safe phase is not another job-33 proof.

Recommended next phase:

```text
Stage 16 E3Z-I — Insert Fresh Timer Proof Job After Direct Service Proof
```

That phase should use a new job id and require a separate explicit approval before any DB insert or timer activation.

Persistent workers remain blocked.

R13D repo closure verified after R13B DB-only recovery.
