# Stage 16 E3Z-EM-R6 bounded service-path runtime proof, job49 env profile path

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EL.
- Base HEAD/origin/main: `fe5b4d6`.
- Base tag: `controller-stage-16-e3z-el-bounded-service-proof-acceptance-contract-no-apply-2026-06-22`.
- Approval: `APPROVE_STAGE_16_E3Z_EM_BOUNDED_SERVICE_PATH_RUNTIME_PROOF_ONE_FRESH_JOB_ONLY`.

## Why R6 was needed

The first E3Z-EM attempt inserted job 49 and refused with `REFUSE_WORKER_DISABLED`.

E3Z-EM-R3 retried with `EDGE_WORKER_ENABLED=1` and strict proof mode, but refused with `REFUSE_WORKER_SCHEDULER_ACTIVE`.

E3Z-EM-R4 retried using `--once` exact-job mode without `EDGE_PROOF_MODE`, but refused with `REFUSE_PROFILE_FILE_MISSING`.

E3Z-EM-R5 added a CLI absolute profile path but still refused with `REFUSE_PROFILE_FILE_MISSING`, showing the live `--once` path reads the model profile from worker environment/config.

R6 set `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`.

All prior refusals were safe. Job 49 stayed queued with zero result rows until R6.

## Mutation scope used by R6

R6 reused existing job 49. It did not insert a new job.

R6 used:

- one CT203 SQLite backup before retry,
- one bounded CT101 transient systemd service invocation,
- explicit `--once` exact-job environment guards,
- explicit `EDGE_MODEL_PROFILE_FILE`,
- one worker claim for job 49 only,
- one CT101 Ollama call using `qwen2.5:0.5b`,
- post-run DB/service/timer verification,
- repo doc/smoke/commit/tag/push checkpoint.

R6 did not:

- enable persistent workers,
- enable scheduler or timer dispatch,
- drain the queue,
- reset or delete jobs,
- apply schema,
- mutate Docker configuration,
- restart CTs or VMs,
- pull or download models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Fresh job contract

- Fresh job id: `49`.
- Marker: `E3Z-EM-SERVICE-PATH-QWEN25-ONE-JOB-OK`.
- Requested model: `qwen2.5:0.5b`.
- Job type: `stage16_e3z_limited_persistent_worker_repeat_proof`.
- Profile file: `/etc/edge-ct101-worker/model-profiles.yaml`.
- Expected response sha256: `48517a4fb6a6c54725b18bd8a5a2d77fab7ba57ef6672e0e3c9e5b15e9b1f505`.

## Pre-R6 backup

- Backup path: `/var/lib/edge-queue-controller/stage16-em-backups/edge_queue.sqlite3.stage16-e3z-em-r6-pre-job49-env-profile.20260623T002201Z.bak`.
- Backup sha256: `30a5adae73cf6ebcce0fe60765299d1baeea0ff220737c8256ec0f379d157697`.

## Runtime path

The proof used a transient systemd unit on CT101:

- Transient unit: `stage16-e3z-em-r6-job49.service`.
- Installed worker service remained inactive/disabled.
- Worker command shape: `ct101_minimal_ollama_worker.py --profile-file /etc/edge-ct101-worker/model-profiles.yaml --once --job-id 49`.
- Explicit exact-job guards included `EDGE_WORKER_ENABLED=1`, `EDGE_ALLOWED_JOB_IDS=49`, `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`, `EDGE_MAX_JOBS_PER_LOOP=1`, `EDGE_CLAIM_POLICY=one_at_a_time`, and `EDGE_ALLOW_MODEL_CONCURRENCY=0`.
- The invocation was bounded to job 49 only.

## Service invocation result

```text
bounded_transient_service_rc=0
edge_service_after_active=inactive
edge_service_after_enabled=disabled
ct101_queue_timer_rows_after=0
```

## DB result

```text
em_job_id=49
em_job_status=completed
em_job_attempts=1
em_job_result_rows=1
em_result_response_sha256=48517a4fb6a6c54725b18bd8a5a2d77fab7ba57ef6672e0e3c9e5b15e9b1f505
acceptance_pass=true
```

## Acceptance result

E3Z-EM-R6 passed.

Job 49 completed with exactly one result row. The response matched the approved exact marker and response sha256. Jobs 37 through 48 remained completed with exactly one result row each. The permanent CT101 worker service returned to inactive/disabled posture. No queue-processing timer was enabled.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-EN`.

Purpose: repeat the bounded service-path proof with one more fresh exact-marker job to prove repeatability before considering any timer one-tick proof or persistent worker path.

E3Z-EN should still avoid persistent worker enablement and scheduler/timer dispatch.
