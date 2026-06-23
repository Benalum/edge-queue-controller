# Stage 16 E3Z-EQ repeat one-tick timer runtime proof, one fresh job

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EP.
- Base HEAD/origin/main: `ea1bca4`.
- Base tag: `controller-stage-16-e3z-ep-one-tick-timer-runtime-proof-one-fresh-job-2026-06-22`.
- Approval: `APPROVE_STAGE_16_E3Z_EQ_REPEAT_ONE_TICK_TIMER_RUNTIME_PROOF_ONE_FRESH_JOB_ONLY`.

## Purpose

E3Z-EQ repeated the one-tick timer runtime proof with one more fresh exact-marker job after E3Z-EP succeeded.

This proves one-tick timer repeatability before considering any persistent timer, scheduler, or persistent worker path.

## Mutation scope used

This stage used:

- one CT203 SQLite backup before the DB write,
- one fresh exact-marker CT203 queued test job insert,
- one transient one-tick CT101 systemd timer,
- one timer-triggered worker invocation,
- explicit `--once` exact-job environment guards,
- explicit `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`,
- one worker claim for the approved job id only,
- one CT101 Ollama call using `qwen2.5:0.5b`,
- post-run DB/service/timer verification,
- repo doc/smoke/commit/tag/push checkpoint.

This stage did not:

- enable persistent workers,
- enable persistent scheduler or timer dispatch,
- drain the queue,
- reset or delete jobs,
- apply schema,
- mutate Docker configuration,
- restart CTs or VMs,
- pull or download models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Fresh job contract

- Fresh job id: `52`.
- Marker: `E3Z-EQ-TIMER-ONE-TICK-QWEN25-REPEAT-OK`.
- Requested model: `qwen2.5:0.5b`.
- Job type: `stage16_e3z_limited_persistent_worker_repeat_proof`.
- Profile file: `/etc/edge-ct101-worker/model-profiles.yaml`.
- Prompt sha256: `5c12d87802e54950593a8c3e7c81939f825e9425960ece145873056a5da9a993`.
- Expected response sha256: `a65b93e2f142048a4cac4ac4fe7fa77ab015ac9e083cf4b0d4983d2d6794a71b`.

## Pre-run backup

- Backup path: `/var/lib/edge-queue-controller/stage16-eq-backups/edge_queue.sqlite3.stage16-e3z-eq-pre-fresh-job-insert.20260623T003412Z.bak`.
- Backup sha256: `fc7efffb4bdea688d322a4d118ee41c6a206ef5694a1242568fe9d2320a4d352`.

## Timer runtime path

The proof used a transient one-tick timer on CT101:

- Timer unit base: `stage16-e3z-eq-job52`.
- Timer unit: `stage16-e3z-eq-job52.timer`.
- Service unit: `stage16-e3z-eq-job52.service`.
- Worker command shape: `ct101_minimal_ollama_worker.py --profile-file /etc/edge-ct101-worker/model-profiles.yaml --once --job-id 52`.
- Exact-job guards included `EDGE_WORKER_ENABLED=1`, `EDGE_ALLOWED_JOB_IDS=52`, `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`, `EDGE_MAX_JOBS_PER_LOOP=1`, `EDGE_CLAIM_POLICY=one_at_a_time`, and `EDGE_ALLOW_MODEL_CONCURRENCY=0`.
- The invocation was bounded to job 52 only.

## Timer/service invocation result

```text
timer_schedule_rc=0
timer_seen_active=1
service_seen_active_or_activating=1
timer_active_after=inactive
timer_enabled_after=not-found
transient_service_active_after=inactive
transient_service_result_after=success
transient_service_exec_status_after=0
edge_service_after_active=inactive
edge_service_after_enabled=disabled
ct101_queue_timer_rows_after=0
```

## DB result

```text
eq_job_id=52
eq_job_status=completed
eq_job_attempts=1
eq_job_result_rows=1
eq_result_response_sha256=a65b93e2f142048a4cac4ac4fe7fa77ab015ac9e083cf4b0d4983d2d6794a71b
acceptance_pass=true
```

## Acceptance result

E3Z-EQ passed.

Job 52 completed with exactly one result row. The response matched the approved exact marker and response sha256. Jobs 37 through 51 remained completed with exactly one result row each. The permanent CT101 worker service returned to inactive/disabled posture. No queue-processing timer remained active after the proof.

## Timer repeatability result

E3Z-EP and E3Z-EQ together prove two consecutive one-tick timer-triggered CT101 worker completions:

- job 51 completed through the one-tick timer path,
- job 52 completed through the one-tick timer path,
- both used `qwen2.5:0.5b`,
- both used `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`,
- both returned exact expected markers,
- neither enabled persistent workers,
- neither enabled persistent scheduler/timer dispatch,
- both returned timer/service posture to default-off.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-ER`.

Purpose: create a no-apply acceptance contract for the first guarded installed timer/service path, converting the proven transient timer payload into a reviewed installed-unit design while still preserving default-off behavior until explicitly activated.

E3Z-ER should be repo-only unless separately approved for runtime service/timer file mutation.
