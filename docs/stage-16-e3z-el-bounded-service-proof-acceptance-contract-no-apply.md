# Stage 16 E3Z-EL bounded service proof acceptance contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EK.
- Base HEAD/origin/main: `ec8eab8`.
- Base tag: `controller-stage-16-e3z-ek-guarded-service-timer-persistent-worker-strategy-no-apply-2026-06-22`.
- Base commit message: `docs: plan stage 16 e3z ek guarded worker activation strategy`.
- Repository state at stage entry: clean.

## Mutation boundary for this stage

This E3Z-EL stage is repo-only planning.

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

E3Z-EK recorded the guarded service/timer/persistent-worker strategy after the successful bounded foreground one-shot worker proof.

E3Z-EL defines the acceptance contract for the next runtime proof: a first bounded service-path proof that uses the CT101 worker service surface without enabling persistent background processing.

This contract is intentionally no-apply. Runtime execution belongs to a later separately approved stage.

## Known good prior proof

Stage 16 E3Z-EJ-C-R12-I2 proved:

- CT203 remains controller/API/queue/DB authority.
- CT101 on PVESO remains the model runtime/worker target.
- CT101 Ollama can be used through the bounded worker path.
- Job 48 completed with exactly one result row.
- Job 48 final state was completed.
- Job 48 attempts were 4.
- Job 48 requested model was `qwen2.5:0.5b`.
- Job 48 exact response was `E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK`.
- Job 48 response sha256 was `a567b6299a152552cee2aae209616c8d708bd47cd1aa02b8bd93194503818382`.
- Jobs 37 through 48 were confirmed completed with exactly one result row each.

Stage 16 E3Z-EK then confirmed:

- CT203 DB quick check was OK.
- Jobs 37 through 48 were still completed with exactly one result row each.
- Job 48 was still completed with one result row.
- CT203 scheduler/timer unit candidates were not installed or not active.
- PVESO was reachable through the dynamically discovered Tailscale IP using OpenSSH as root.
- CT101 was running.
- `edge-ct101-ollama-worker.service` was loaded but inactive and disabled.
- Legacy laptop queue worker services were inactive and masked.
- CT101 Ollama Docker container was running and healthy.
- CT101 worker script sha256 was `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
- CT101 model profile sha256 was `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`.

## Future service-path proof target

The next runtime proof should demonstrate that the CT101 worker can run through a bounded service-path invocation and still preserve the exact-job safety behavior proven in foreground mode.

The proof must not become an open-ended daemon test. It must process one approved fresh job and then return to the inactive/default-off posture.

## Pre-apply requirements for a future runtime stage

A future apply stage must verify all of the following before any runtime activation:

1. Repository HEAD, origin/main, and remote main match the expected E3Z-EL checkpoint.
2. The repository is clean.
3. CT203 DB path is `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
4. CT203 DB quick check returns OK.
5. Jobs 37 through 48 remain completed with exactly one result row each.
6. CT101 is running.
7. CT101 Ollama container is running and healthy.
8. CT101 worker script hash matches the E3Z-EK baseline or the stage explicitly documents a reviewed change.
9. CT101 model profile hash matches the E3Z-EK baseline or the stage explicitly documents a reviewed change.
10. `edge-ct101-ollama-worker.service` is inactive and disabled before the proof.
11. Legacy laptop queue worker units remain inactive and masked.
12. No queue-processing timer is active.
13. No scheduler-wide path is active.
14. PVESO operator route is dynamically discovered from Tailscale state rather than relying on broken local MagicDNS.
15. The user has explicitly approved runtime mutation for that future apply stage.

## Fresh job requirements for a future runtime stage

A future apply stage must use a fresh exact-marker test job.

The job contract must define:

- exact job id after insertion,
- requested model,
- job type,
- prompt text,
- exact marker expected from the model,
- expected response string or expected response hash,
- maximum jobs allowed for the worker invocation,
- maximum runtime window,
- exact refusal behavior if the expected job id or marker does not match.

The first service-path proof should continue using the smallest known-good model class, currently `qwen2.5:0.5b`, unless a separate no-apply model change checkpoint is created first.

The fresh marker must be unique to the future apply stage. It must not reuse the Job 48 marker.

## Bounded invocation requirements

The worker service path must be invoked in a bounded one-shot mode.

The invocation must guarantee:

- one approved job only,
- no general queue drain,
- no stale job replay,
- no background persistence after the proof,
- no timer enablement,
- no scheduler-wide enablement,
- no model download or pull,
- no mutation of Docker container configuration,
- no mutation of CT or VM lifecycle state,
- no mutation of SSH config or host resolution files.

The worker must refuse or fail closed if:

- the expected job id is absent,
- the expected marker is absent,
- the requested model differs from the approved model,
- the job is not in the expected queued/claimable state,
- the worker would need to claim more than one job,
- the result row already exists before the test,
- CT101 Ollama is not healthy,
- the service is already active before the bounded run,
- timer/scheduler posture is not default-off.

## Acceptance criteria

A future bounded service-path proof passes only if all of these are true:

1. The fresh test job transitions to completed.
2. The fresh test job has exactly one result row.
3. The result content equals the approved exact response or hashes to the approved sha256.
4. No other queued jobs are claimed by the proof.
5. No jobs 37 through 48 are mutated.
6. No extra result rows are added to jobs 37 through 48.
7. The worker invocation exits cleanly or reaches the documented bounded success state.
8. `edge-ct101-ollama-worker.service` is inactive after the proof.
9. `edge-ct101-ollama-worker.service` remains disabled after the proof.
10. Legacy laptop worker units remain masked.
11. No queue-processing timer is enabled.
12. CT203 scheduler/timer posture remains default-off.
13. CT101 Ollama remains running and healthy after the proof.
14. The proof log contains the exact job id, model, marker, result-row count, and final service posture.
15. The repository is checkpointed after the result.

## Failure criteria

The future proof fails and must stop if any of these occur:

- DB quick check fails.
- Jobs 37 through 48 are not all completed with exactly one result row before the test.
- The fresh job cannot be uniquely identified.
- The worker claims more than the approved fresh job.
- The model response does not exactly match the approved marker contract.
- The result row count is zero or greater than one.
- The service remains active after the bounded proof.
- The service becomes enabled without explicit approval.
- Any queue-processing timer becomes enabled.
- Any scheduler-wide path becomes active.
- CT101 Ollama health degrades after the proof.
- Any unapproved Docker, CT, VM, SSH, or host-resolution mutation is observed.

## Abort and rollback posture

A future apply stage must define the abort path before execution.

The abort path must be limited to returning the bounded proof surface to the default-off posture. It must not attempt broad cleanup, DB surgery, Docker rebuild, CT restart, VM restart, model download, or scheduler changes unless separately approved.

If the job is partially claimed or partially completed, the stage must stop and document the state rather than automatically resetting or deleting rows.

## Evidence required from a future runtime proof

The future runtime output must capture:

- repo HEAD/origin/remote check,
- prior tag check,
- git status,
- CT203 DB quick check,
- jobs 37 through 48 unchanged check,
- fresh job id and initial state,
- fresh job result-row count before invocation,
- CT101 service posture before invocation,
- CT101 Ollama health before invocation,
- bounded service invocation result,
- fresh job final state,
- fresh job result-row count after invocation,
- exact response or response hash,
- jobs 37 through 48 unchanged after invocation,
- CT101 service posture after invocation,
- CT101 timer posture after invocation,
- CT203 scheduler/timer posture after invocation,
- final repo checkpoint.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-EM`.

Purpose: perform a bounded runtime service-path proof only after explicit runtime approval.

E3Z-EM should:

- use this E3Z-EL contract as its acceptance gate,
- create or select one fresh exact-marker job,
- invoke only the bounded service path,
- verify exact response and result-row behavior,
- verify service/timer posture returns to default-off,
- checkpoint the result.

E3Z-EM must not enable persistent workers or scheduler/timer dispatch.
