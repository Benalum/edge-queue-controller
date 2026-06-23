# Stage 16 E3Z-EP one-tick timer runtime proof, one fresh job

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EO.
- Base HEAD/origin/main: `f5a6592`.
- Base tag: `controller-stage-16-e3z-eo-one-tick-timer-proof-acceptance-contract-no-apply-2026-06-22`.
- Approval: `APPROVE_STAGE_16_E3Z_EP_ONE_TICK_TIMER_RUNTIME_PROOF_ONE_FRESH_JOB_ONLY`.

## Purpose

E3Z-EP performed the first one-tick timer runtime proof after two successful bounded CT101 transient service-path proofs.

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

- Fresh job id: `51`.
- Marker: `E3Z-EP-TIMER-ONE-TICK-QWEN25-OK`.
- Requested model: `qwen2.5:0.5b`.
- Job type: `stage16_e3z_limited_persistent_worker_repeat_proof`.
- Profile file: `/etc/edge-ct101-worker/model-profiles.yaml`.
- Prompt sha256: `fdff0ee90b74c3b67b69f14609377718586af03f238ca6b27abf64dab6cb721b`.
- Expected response sha256: `d8359c75ee6170aa2711cb755fd062735bf344a6ad5abae2fe092f85ecbf3de1`.

## Pre-run backup

- Backup path: `/var/lib/edge-queue-controller/stage16-ep-backups/edge_queue.sqlite3.stage16-e3z-ep-pre-fresh-job-insert.20260623T003014Z.bak`.
- Backup sha256: `0c82d6edf620a9652e8525ab2f3973ac560e572d2f353a38fd3ecaa1ffb6a317`.

## Timer runtime path

The proof used a transient one-tick timer on CT101:

- Timer unit base: `stage16-e3z-ep-job51`.
- Timer unit: `stage16-e3z-ep-job51.timer`.
- Service unit: `stage16-e3z-ep-job51.service`.
- Worker command shape: `ct101_minimal_ollama_worker.py --profile-file /etc/edge-ct101-worker/model-profiles.yaml --once --job-id 51`.
- Exact-job guards included `EDGE_WORKER_ENABLED=1`, `EDGE_ALLOWED_JOB_IDS=51`, `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`, `EDGE_MAX_JOBS_PER_LOOP=1`, `EDGE_CLAIM_POLICY=one_at_a_time`, and `EDGE_ALLOW_MODEL_CONCURRENCY=0`.
- The invocation was bounded to job 51 only.

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
ep_job_id=51
ep_job_status=completed
ep_job_attempts=1
ep_job_result_rows=1
ep_result_response_sha256=d8359c75ee6170aa2711cb755fd062735bf344a6ad5abae2fe092f85ecbf3de1
acceptance_pass=true
```

## Acceptance result

E3Z-EP passed.

Job 51 completed with exactly one result row. The response matched the approved exact marker and response sha256. Jobs 37 through 50 remained completed with exactly one result row each. The permanent CT101 worker service returned to inactive/disabled posture. No queue-processing timer remained active after the proof.

## Timer proof result

E3Z-EP proves the first one-tick timer-triggered CT101 worker completion:

- one fresh exact-marker job,
- one transient timer,
- one timer-triggered worker service execution,
- one exact CT101 Ollama result,
- no persistent worker enablement,
- no persistent scheduler/timer dispatch,
- default-off posture after completion.

## Next recommended stage

Recommended next stage: `Stage 16 E3Z-EQ`.

Purpose: repeat the one-tick timer proof with one more fresh exact-marker job to prove timer repeatability before considering any persistent timer or scheduler path.

E3Z-EQ should still avoid persistent worker enablement and persistent scheduler/timer dispatch.
