# Stage 16 E3Z-ER guarded installed timer/service path contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EQ.
- Base HEAD/origin/main: `b2b5e1e`.
- Base tag: `controller-stage-16-e3z-eq-repeat-one-tick-timer-runtime-proof-one-fresh-job-2026-06-22`.
- Base commit message: `docs: record stage 16 e3z eq repeat one-tick timer proof`.
- Repository state at stage entry: clean.

## Mutation boundary for this stage

This E3Z-ER stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, delete, or mutate jobs,
- apply schema,
- start, stop, restart, reload, enable, or disable worker services,
- activate scheduler services or timers,
- create installed unit files on CT101,
- reload systemd on CT101,
- start, stop, or restart CTs or VMs,
- mutate Docker containers,
- call Ollama generate, chat, embed, or model endpoints,
- download or pull models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Purpose

E3Z-ER defines the acceptance contract for a future guarded installed timer/service path.

The future installed path should convert the proven transient timer payload into reviewed CT101 unit files while still preserving default-off posture until explicitly activated for a bounded proof.

This is not persistent worker activation. This is a design and acceptance gate for installed default-off units that can later be triggered for one approved exact job at a time.

## Proven baseline

Stage 16 now has four successful CT101 runtime proofs after the foreground/manual path:

### Bounded transient service path

- E3Z-EM-R6: job 49 completed through bounded CT101 transient service execution.
- E3Z-EN: job 50 completed through repeated bounded CT101 transient service execution.

Both service-path proofs used:

- `qwen2.5:0.5b`,
- `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`,
- one exact allowed job id,
- one result row,
- exact marker validation,
- permanent CT101 worker service inactive/disabled after completion,
- CT101 queue timer rows 0 after completion.

### Transient one-tick timer path

- E3Z-EP: job 51 completed through one transient one-tick CT101 timer.
- E3Z-EQ: job 52 completed through repeated transient one-tick CT101 timer.

Both timer proofs used:

- `qwen2.5:0.5b`,
- `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`,
- one exact allowed job id,
- one timer-triggered worker service execution,
- one result row,
- exact marker validation,
- transient timer inactive/not-found after completion,
- transient service inactive/not-found after completion,
- permanent CT101 worker service inactive/disabled after completion,
- CT101 queue timer rows 0 after completion.

Together these prove that CT101 can process an exact queued job through the service path and timer path without persistent worker enablement or persistent scheduler/timer dispatch.

## Known-good worker payload

The future installed service unit must preserve the known-good worker payload from E3Z-EM-R6 through E3Z-EQ.

Required worker environment shape:

- `EDGE_WORKER_ENABLED=1`
- `EDGE_MAX_JOBS_PER_LOOP=1`
- `EDGE_CLAIM_POLICY=one_at_a_time`
- `EDGE_ALLOW_MODEL_CONCURRENCY=0`
- `EDGE_ALLOWED_JOB_IDS=<fresh_exact_job_id>`
- `EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml`
- `EDGE_PROOF_MODE` unset for this one-shot path
- `EDGE_EXIT_AFTER_ONE_SUCCESS` unset for this one-shot path
- `EDGE_MAX_RUNTIME_SECONDS` unset for this one-shot path
- `EDGE_REFUSE_IF_SCHEDULER_ACTIVE` unset for this one-shot path
- `EDGE_REFUSE_IF_TIMER_ACTIVE` unset for this one-shot path

Required worker command shape:

`ct101_minimal_ollama_worker.py --profile-file /etc/edge-ct101-worker/model-profiles.yaml --once --job-id <fresh_exact_job_id>`

The strict proof-mode timer/scheduler guards are intentionally not used in this one-shot path because an earlier strict proof attempt self-detected the transient service context and refused before claiming a job.

External service and timer posture checks remain mandatory before and after any future runtime proof.

## Future installed unit design constraints

A future installed-unit stage may propose CT101 unit files, but those units must be guarded and default-off.

The design should use separate service and timer units or templates.

Recommended service template characteristics:

- accepts exactly one job id as the instance parameter,
- maps the instance parameter to `EDGE_ALLOWED_JOB_IDS`,
- invokes the known-good `--once --job-id` worker command,
- uses the absolute model profile file path,
- allows only one job per invocation,
- does not restart automatically,
- does not run as a persistent loop,
- does not enable model concurrency,
- does not contain broad queue-drain behavior,
- does not contain a default job id,
- fails closed if no exact job id is provided,
- remains disabled after installation.

Recommended timer template characteristics:

- accepts exactly one job id as the instance parameter,
- triggers only the matching service instance for that job id,
- is not enabled by default,
- is not persistent,
- is not recurring,
- has no broad scheduler behavior,
- has no queue-scan behavior,
- has no install target that would cause accidental boot activation,
- remains disabled after installation.

The installed units must not replace or enable the existing permanent worker service.

## Future install-only stage acceptance criteria

A future install-only stage, if approved, must pass all of these checks:

1. Repository HEAD, origin/main, and remote main match the expected E3Z-ER checkpoint.
2. Repository status is clean.
3. CT101 is running.
4. CT101 Ollama is running and healthy.
5. CT101 worker script sha256 remains `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
6. CT101 model profile sha256 remains `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`.
7. `edge-ct101-ollama-worker.service` is inactive and disabled before the stage.
8. Legacy laptop queue worker units remain inactive and masked.
9. CT101 queue timer rows are 0 before the stage.
10. The future stage creates only the reviewed unit files.
11. The future stage does not start the installed service unit.
12. The future stage does not start the installed timer unit.
13. The future stage does not enable the installed service unit.
14. The future stage does not enable the installed timer unit.
15. The future stage does not insert or mutate jobs.
16. The future stage does not call Ollama.
17. The future stage verifies the installed unit contents after writing.
18. The future stage verifies the installed units are inactive and disabled after writing.
19. CT101 queue timer rows are 0 after the stage.
20. Repository is checkpointed only after all post-install default-off checks pass.

## Future installed one-tick runtime proof acceptance criteria

A later runtime stage, after install-only success and separate runtime approval, must prove the installed timer path with one fresh exact-marker job.

It must pass all of these checks:

1. The stage starts from the installed-unit default-off checkpoint.
2. CT203 DB quick check returns OK.
3. Jobs 37 through 52 are completed with exactly one result row each.
4. Job 51 and job 52 remain unchanged from the successful transient one-tick timer proofs.
5. One fresh exact-marker job is inserted in queued state.
6. The fresh job has attempts 0 and result rows 0 before the timer tick.
7. The installed timer is activated for exactly one job id.
8. The installed timer fires exactly once.
9. The installed service instance uses only the exact approved job id.
10. The fresh job transitions to completed.
11. The fresh job attempts count is 1.
12. The fresh job has exactly one result row.
13. The result response exactly equals the approved marker.
14. The result response sha256 equals the approved expected sha256.
15. No additional jobs are claimed or completed.
16. The installed timer instance is inactive after the proof.
17. The installed service instance is inactive after the proof.
18. The installed timer template remains disabled after the proof.
19. The installed service template remains disabled after the proof.
20. The permanent CT101 worker service remains inactive and disabled after the proof.
21. Legacy laptop worker units remain inactive and masked.
22. CT101 queue timer rows return to 0 after the proof.
23. CT101 Ollama remains running and healthy.
24. No Docker, CT, VM, SSH, host-resolution, model-pull, or scheduler mutation is observed.
25. Repository is checkpointed only after all checks pass.

## Failure criteria

Any future installed-unit or installed-runtime proof must fail closed if any of these occur:

- DB quick check fails.
- Jobs 37 through 52 are not all completed with exactly one result row before a runtime proof.
- Job 51 or job 52 has drifted.
- CT101 Ollama is not healthy.
- The permanent CT101 worker service is active before the proof.
- A queue-processing timer exists before the proof.
- More than one fresh job is inserted.
- The fresh job id is not uniquely identified.
- Any installed unit contains a broad queue-drain command.
- Any installed unit contains a default allowed job id.
- The worker attempts to claim any job other than the approved fresh job.
- The timer repeats or remains enabled.
- The timer proof leaves any queue-processing timer active.
- The response does not exactly match the marker.
- The result row count is not exactly one.
- Service/timer posture does not return to default-off.
- Any unapproved runtime mutation is observed.

## Abort and rollback posture

Future stages must define their abort path before execution.

For an install-only stage, the abort path may remove only the newly installed reviewed units if they were created by that same stage and if removal is separately included in the approval scope.

For a runtime proof stage, the abort path must be limited to restoring default-off timer/service posture. It must not reset jobs, delete rows, apply schema, mutate Docker, restart CTs or VMs, pull models, or perform broad cleanup unless separately approved.

If a timer fires but the job does not complete, the stage must stop and document the state rather than automatically resetting or deleting rows.

## Evidence required from a future installed-unit path

A future installed-unit path must capture:

- repo HEAD/origin/remote check,
- prior tag check,
- git status,
- CT101 health and service posture,
- CT101 worker/profile sha256,
- pre-install timer posture,
- unit file paths,
- unit file content hashes,
- unit file content excerpts or normalized summaries,
- service and timer inactive/disabled posture after installation,
- CT101 queue timer rows after installation,
- final repo checkpoint.

A future installed one-tick runtime proof must capture:

- repo HEAD/origin/remote check,
- prior tag check,
- git status,
- CT203 DB quick check,
- jobs 37 through 52 unchanged preflight,
- fresh job id and initial state,
- fresh job result-row count before timer,
- CT101 service posture before timer,
- CT101 timer posture before timer,
- CT101 Ollama health before timer,
- installed timer activation evidence,
- installed service execution evidence,
- fresh job final state,
- fresh job result-row count after timer,
- exact response and response sha256,
- jobs 37 through 52 unchanged after timer,
- CT101 service posture after timer,
- CT101 timer posture after timer,
- final repo checkpoint.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-ES`.

Purpose: perform an install-only guarded unit-file stage for the reviewed installed timer/service templates, preserving default-off posture and performing no job insert and no model call.

E3Z-ES requires explicit runtime/infrastructure approval because it writes CT101 systemd unit files and reloads systemd, even though it should not start or enable the units.
