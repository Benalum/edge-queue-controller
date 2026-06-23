# Stage 16 E3Z-EN repeat bounded service-path proof, one fresh job

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EM-R6.
- Base HEAD/origin/main: `11bb13e`.
- Base tag: `controller-stage-16-e3z-em-r6-bounded-service-path-runtime-proof-job49-env-profile-2026-06-22`.
- Approval: `APPROVE_STAGE_16_E3Z_EN_REPEAT_BOUNDED_SERVICE_PATH_PROOF_ONE_FRESH_JOB_ONLY`.

## Purpose

E3Z-EN repeated the bounded CT101 transient service-path proof with one new fresh exact-marker job after E3Z-EM-R6 succeeded.

This stage proves the service-path shape is repeatable before any timer one-tick proof or persistent-worker activation is considered.

## Mutation scope used

This stage used:

- one CT203 SQLite backup before the DB write,
- one fresh exact-marker CT203 queued test job insert,
- one bounded CT101 transient systemd service invocation,
- explicit `--once` exact-job environment guards,
- explicit `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`,
- one worker claim for the approved job id only,
- one CT101 Ollama call using `qwen2.5:0.5b`,
- post-run DB/service/timer verification,
- repo doc/smoke/commit/tag/push checkpoint.

This stage did not:

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

- Fresh job id: `50`.
- Marker: `E3Z-EN-SERVICE-PATH-QWEN25-REPEAT-OK`.
- Requested model: `qwen2.5:0.5b`.
- Job type: `stage16_e3z_limited_persistent_worker_repeat_proof`.
- Profile file: `/etc/edge-ct101-worker/model-profiles.yaml`.
- Prompt sha256: `045ef7807edd48809ee5bdc939997f912144b4f129c3ae9f6639c2bca9c06f6e`.
- Expected response sha256: `09efe1ccfb76c77a33b5ad03d31e74351fc795173999a736d3ec3732fcba5489`.

## Pre-run backup

- Backup path: `/var/lib/edge-queue-controller/stage16-en-backups/edge_queue.sqlite3.stage16-e3z-en-pre-fresh-job-insert.20260623T002503Z.bak`.
- Backup sha256: `b6dd093981a9a967713726fe5ba4bd82ff853575e81f0d854ec9bc757d4b0c16`.

## Runtime path

The proof used a transient systemd unit on CT101:

- Transient unit: `stage16-e3z-en-job50.service`.
- Installed worker service remained inactive/disabled.
- Worker command shape: `ct101_minimal_ollama_worker.py --profile-file /etc/edge-ct101-worker/model-profiles.yaml --once --job-id 50`.
- Exact-job guards included `EDGE_WORKER_ENABLED=1`, `EDGE_ALLOWED_JOB_IDS=50`, `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`, `EDGE_MAX_JOBS_PER_LOOP=1`, `EDGE_CLAIM_POLICY=one_at_a_time`, and `EDGE_ALLOW_MODEL_CONCURRENCY=0`.
- The invocation was bounded to job 50 only.

## Service invocation result

```text
bounded_transient_service_rc=0
edge_service_after_active=inactive
edge_service_after_enabled=disabled
ct101_queue_timer_rows_after=0
```

## DB result

```text
en_job_id=50
en_job_status=completed
en_job_attempts=1
en_job_result_rows=1
en_result_response_sha256=09efe1ccfb76c77a33b5ad03d31e74351fc795173999a736d3ec3732fcba5489
acceptance_pass=true
```

## Acceptance result

E3Z-EN passed.

Job 50 completed with exactly one result row. The response matched the approved exact marker and response sha256. Jobs 37 through 49 remained completed with exactly one result row each. The permanent CT101 worker service returned to inactive/disabled posture. No queue-processing timer was enabled.

## Repeatability result

E3Z-EM-R6 and E3Z-EN together prove two consecutive bounded CT101 transient service-path completions:

- job 49 completed through the bounded service path,
- job 50 completed through the bounded service path,
- both used `qwen2.5:0.5b`,
- both used `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`,
- both returned exact expected markers,
- neither enabled persistent workers,
- neither enabled scheduler/timer dispatch.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-EO`.

Purpose: create a no-apply acceptance contract for the first one-tick timer proof, using one fresh exact-marker job and preserving default-off timer posture after the proof.

E3Z-EO should be repo-only unless separately approved for runtime timer mutation.
