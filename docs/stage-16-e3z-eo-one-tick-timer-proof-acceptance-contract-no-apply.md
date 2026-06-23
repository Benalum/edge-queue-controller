# Stage 16 E3Z-EO one-tick timer proof acceptance contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EN.
- Base HEAD/origin/main: `8c2e135`.
- Base tag: `controller-stage-16-e3z-en-repeat-bounded-service-path-proof-one-fresh-job-2026-06-22`.
- Base commit message: `docs: record stage 16 e3z en repeat bounded service proof`.
- Repository state at stage entry: clean.

## Mutation boundary for this stage

This E3Z-EO stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, or mutate jobs,
- apply schema,
- start, stop, restart, reload, enable, or disable worker services,
- activate scheduler services or timers,
- start, stop, or restart CTs or VMs,
- mutate Docker containers,
- call Ollama generate, chat, embed, or model endpoints,
- download or pull models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Purpose

E3Z-EO defines the acceptance contract for the first one-tick timer proof.

The timer proof is not yet approved in this stage. This document only defines what a future runtime stage must prove before any timer path can be considered safe.

## Proven service-path baseline

Stage 16 E3Z-EM-R6 proved the first bounded CT101 transient service-path completion:

- Job 49 completed.
- Job 49 attempts: 1.
- Job 49 result rows: 1.
- Job 49 requested model: `qwen2.5:0.5b`.
- Job 49 exact response: `E3Z-EM-SERVICE-PATH-QWEN25-ONE-JOB-OK`.
- Job 49 response sha256: `48517a4fb6a6c54725b18bd8a5a2d77fab7ba57ef6672e0e3c9e5b15e9b1f505`.
- CT101 permanent worker service returned to inactive/disabled.
- CT101 queue timer rows after the proof: 0.

Stage 16 E3Z-EN proved repeatability with a second fresh job:

- Job 50 completed.
- Job 50 attempts: 1.
- Job 50 result rows: 1.
- Job 50 requested model: `qwen2.5:0.5b`.
- Job 50 exact response: `E3Z-EN-SERVICE-PATH-QWEN25-REPEAT-OK`.
- Job 50 response sha256: `09efe1ccfb76c77a33b5ad03d31e74351fc795173999a736d3ec3732fcba5489`.
- Jobs 37 through 49 remained completed with exactly one result row each.
- CT101 permanent worker service returned to inactive/disabled.
- CT101 queue timer rows after the proof: 0.

Together, E3Z-EM-R6 and E3Z-EN prove two consecutive bounded CT101 transient service-path completions without persistent worker enablement or scheduler/timer dispatch.

## Known-good bounded worker shape

Future timer proof stages must preserve the known-good worker environment shape from E3Z-EM-R6 and E3Z-EN:

- `EDGE_WORKER_ENABLED=1`
- `EDGE_MAX_JOBS_PER_LOOP=1`
- `EDGE_CLAIM_POLICY=one_at_a_time`
- `EDGE_ALLOW_MODEL_CONCURRENCY=0`
- `EDGE_ALLOWED_JOB_IDS=<fresh_exact_job_id>`
- `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`
- `EDGE_PROOF_MODE` unset for the one-shot path
- `EDGE_EXIT_AFTER_ONE_SUCCESS` unset for the one-shot path
- `EDGE_REFUSE_IF_SCHEDULER_ACTIVE` unset for the one-shot path
- `EDGE_REFUSE_IF_TIMER_ACTIVE` unset for the one-shot path
- worker command shape: `ct101_minimal_ollama_worker.py --profile-file /etc/edge-ct101-worker/model-profiles.yaml --once --job-id <fresh_exact_job_id>`

The unset strict proof-mode timer/scheduler guards are intentional for the current one-shot service path because the earlier transient service proof showed that strict proof mode can self-detect the transient service context and refuse before claiming the job.

External posture checks must still verify scheduler/timer default-off before and after the proof.

## Future one-tick timer proof target

A future runtime stage should prove one timer-triggered worker execution only.

The target is not persistent scheduling. The target is a single one-tick proof that:

1. starts from default-off timer posture,
2. creates one fresh exact-marker queued job,
3. schedules exactly one timer-triggered invocation,
4. claims only the approved fresh job,
5. completes the job through CT101 Ollama,
6. returns all timer/service posture to default-off,
7. verifies the DB and service/timer posture,
8. checkpoints the result.

## Pre-apply requirements for a future runtime timer stage

A future apply stage must verify all of the following before any timer mutation:

1. Repository HEAD, origin/main, and remote main match the expected E3Z-EO checkpoint.
2. Repository status is clean.
3. CT203 DB path is `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
4. CT203 DB quick check returns OK.
5. Jobs 37 through 50 are completed with exactly one result row each.
6. Job 49 and job 50 remain unchanged from their successful service-path proofs.
7. CT101 is running.
8. CT101 Ollama container is running and healthy.
9. CT101 worker script sha256 is `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
10. CT101 model profile sha256 is `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`.
11. `edge-ct101-ollama-worker.service` is inactive and disabled.
12. Legacy laptop queue worker units remain inactive and masked.
13. CT101 queue timer rows are 0 before the proof.
14. CT203 scheduler/timer candidates remain inactive or not installed.
15. PVESO operator route is dynamically discovered from Tailscale state.
16. The user has explicitly approved the future timer runtime mutation.

## Fresh job requirements for a future timer stage

The future timer proof must use one fresh exact-marker job.

The fresh job must define:

- exact inserted job id,
- requested model `qwen2.5:0.5b`,
- job type `stage16_e3z_limited_persistent_worker_repeat_proof`,
- prompt text that asks for exactly the marker and nothing else,
- unique marker not reused from jobs 49 or 50,
- expected response sha256,
- result row count of 0 before timer execution,
- maximum job id equals the fresh job id before timer execution.

The worker invocation must use `EDGE_ALLOWED_JOB_IDS=<fresh_exact_job_id>`.

## One-tick timer constraints

A future timer proof must not enable a persistent timer.

The timer proof should use a bounded one-shot timer mechanism that cannot repeat after the single tick. The exact mechanism may be a transient systemd timer or equivalent one-shot systemd-run pattern, but the apply stage must prove:

- the timer existed only for the one approved tick,
- the timer did not become enabled as a persistent unit file,
- no queue-processing timer remains active after the run,
- no timer remains enabled after the run,
- the permanent worker service remains inactive and disabled after the run.

The timer-triggered command must still use the known-good exact-job worker shape:

- exact job id only,
- exact model profile file,
- no queue drain,
- no scheduler-wide activation,
- no persistent worker enablement.

## Acceptance criteria for a future timer proof

A future one-tick timer proof passes only if all of these are true:

1. The fresh job is inserted in queued state.
2. The fresh job has attempts 0 and result rows 0 before the timer tick.
3. The one-shot timer fires exactly once.
4. The worker claim is limited to the fresh exact job id.
5. The fresh job transitions to completed.
6. The fresh job attempts count is 1.
7. The fresh job has exactly one result row.
8. The result response exactly equals the approved marker.
9. The result response sha256 equals the approved expected sha256.
10. Jobs 37 through 50 remain completed with exactly one result row each.
11. No additional jobs are claimed or completed by the timer proof.
12. CT101 Ollama remains running and healthy after the proof.
13. `edge-ct101-ollama-worker.service` remains inactive and disabled after the proof.
14. Legacy laptop worker units remain inactive and masked.
15. CT101 queue timer rows are 0 after the proof.
16. CT203 scheduler/timer posture remains inactive or not installed.
17. No Docker, CT, VM, SSH, host-resolution, model-pull, or scheduler mutation is observed.
18. Repository is checkpointed after the successful result.

## Failure criteria

The future timer proof must fail closed and stop if any of these occur:

- DB quick check fails.
- Jobs 37 through 50 are not all completed with exactly one result row before the proof.
- Job 49 or job 50 has drifted.
- CT101 Ollama is not healthy.
- The permanent worker service is active before the proof.
- A queue-processing timer exists or is active before the proof.
- More than one fresh job is inserted.
- The fresh job id is not uniquely identified.
- The worker attempts to claim any job other than the approved fresh job.
- The timer repeats or remains enabled.
- The timer proof leaves any queue-processing timer active.
- The response does not exactly match the marker.
- The result row count is not exactly one.
- Service/timer posture does not return to default-off.
- Any unapproved runtime mutation is observed.

## Abort and rollback posture

The future apply stage must define its abort path before execution.

The abort path must be limited to restoring default-off timer/service posture. It must not reset jobs, delete rows, apply schema, mutate Docker, restart CTs or VMs, pull models, or perform broad cleanup unless separately approved.

If the timer fires but the job does not complete, the stage must stop and document the state rather than automatically resetting or deleting rows.

## Evidence required from a future timer proof

A future timer proof must capture:

- repo HEAD/origin/remote check,
- prior tag check,
- git status,
- CT203 DB quick check,
- jobs 37 through 50 unchanged preflight,
- fresh job id and initial state,
- fresh job result-row count before timer,
- CT101 service posture before timer,
- CT101 timer posture before timer,
- CT101 Ollama health before timer,
- one-tick timer creation or scheduling evidence,
- one-tick timer execution result,
- fresh job final state,
- fresh job result-row count after timer,
- exact response and response sha256,
- jobs 37 through 50 unchanged after timer,
- CT101 service posture after timer,
- CT101 timer posture after timer,
- CT203 scheduler/timer posture after timer,
- final repo checkpoint.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-EP`.

Purpose: perform the first one-tick timer runtime proof only after explicit runtime approval.

E3Z-EP should:

- use this E3Z-EO contract as its acceptance gate,
- insert one fresh exact-marker job,
- use the known-good `EDGE_MODEL_PROFILE_FILE` worker path,
- schedule exactly one timer-triggered invocation,
- verify exact response and result-row behavior,
- verify service/timer posture returns to default-off,
- checkpoint the result.

E3Z-EP must not enable persistent workers or scheduler/timer dispatch.
