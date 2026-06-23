# Stage 16 E3Z-EY installed-unit job56 repeatability contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EX-R2.
- Base HEAD/origin/main: `23ff889`.
- Base tag: `controller-stage-16-e3z-ex-r2-compatible-marker-runtime-success-cleanup-checkpoint-2026-06-22`.
- Repository state at stage entry: clean.

## Mutation boundary for this stage

This E3Z-EY stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, delete, retry, or manually complete jobs,
- retry job 53,
- retry job 54,
- retry job 55,
- apply schema,
- start, stop, restart, reload, enable, or disable services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- write CT101 unit files,
- run daemon-reload,
- start, stop, or restart CTs or VMs,
- mutate Docker containers,
- call Ollama generate, chat, embed, or model endpoints,
- download or pull models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Purpose

E3Z-EY defines the no-apply repeatability contract for one more installed-unit one-tick proof after E3Z-EX-R2 recovered a successful installed-unit runtime completion.

The next runtime proof must use fresh job 56 only.

It must preserve:

- job 53 as failed exact-match evidence,
- job 54 as failed marker-extraction evidence,
- job 55 as successful compatible-marker installed-unit evidence.

## Current evidence state

Known failed installed-unit evidence:

- job 53: running, attempts 1, result rows 0,
- job 54: running, attempts 1, result rows 0.

Known successful installed-unit evidence:

- job 55: completed, attempts 1, result rows 1,
- response text: `E3Z-EW-OK`,
- response sha256: `2a34b5fdc8772a2a06a097f3dddb5daa8c95bc829003c7079b784a980b4592f0`.

Known stable proof window:

- jobs 37 through 52: completed, one result row each.

Known CT101 posture after E3Z-EX-R2:

- job55 timer instance inactive and disabled,
- job55 service instance inactive/static with result success,
- active exact-job services: 0,
- active exact-job timers: 0,
- permanent CT101 worker inactive and disabled,
- legacy laptop worker units inactive and masked,
- installed timer template disabled,
- installed service template static,
- Ollama running and healthy.

## Preservation rule

Jobs 53, 54, and 55 are evidence.

Jobs 53 and 54 must not be:

- reset,
- deleted,
- manually completed,
- retried,
- reused,
- included in future allowed job ids.

Job 55 must not be retried or reused. It is the first recovered installed-unit compatible-marker success and must remain completed with one result row.

Future workers must be constrained to a fresh job id only.

## Repeatability marker contract

The next runtime proof should use fresh job 56.

Recommended future marker:

    E3Z-EY-OK

Recommended future prompt:

    Return exactly this text and nothing else: E3Z-EY-OK

Expected marker sha256 must be computed from exactly:

    E3Z-EY-OK

The exact response validation must remain strict. Do not accept partial matches, whitespace variants, explanations, markdown, JSON wrappers, or extra words.

## Future fresh job requirements

The next runtime proof must insert exactly one fresh job.

Expected next fresh job id: `56`.

The fresh proof job must use:

- requested model: `qwen2.5:0.5b`,
- job type: `stage16_e3z_limited_persistent_worker_repeat_proof`,
- status before timer: `queued`,
- attempts before timer: `0`,
- result rows before timer: `0`,
- max job id after insertion: `56`,
- marker: `E3Z-EY-OK`,
- prompt: `Return exactly this text and nothing else: E3Z-EY-OK`.

The runtime worker must use:

- `EDGE_ALLOWED_JOB_IDS=56`,
- installed timer instance `edge-ct101-exact-job-worker@56.timer`,
- installed service instance `edge-ct101-exact-job-worker@56.service`.

It must not include job 53, job 54, or job 55 in the allowed job ids.

## Pre-runtime verification required

A future runtime proof must verify before inserting job 56:

- repo HEAD, origin/main, and remote main match the E3Z-EY checkpoint,
- repo status is clean,
- CT203 DB quick check is OK,
- jobs 37 through 52 exist,
- jobs 37 through 52 are completed,
- jobs 37 through 52 each have exactly one result row,
- job 53 remains running, attempts 1, result rows 0,
- job 54 remains running, attempts 1, result rows 0,
- job 55 remains completed, attempts 1, result rows 1,
- job 55 response remains exactly `E3Z-EW-OK`,
- max job id is 55,
- CT101 is running,
- CT101 Ollama is running and healthy,
- worker sha256 is `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`,
- profile sha256 is `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`,
- installed service sha256 is `16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e`,
- installed timer sha256 is `7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390`,
- no exact-job service is active,
- no exact-job timer is active,
- the installed timer template remains disabled,
- the permanent CT101 worker service remains inactive and disabled,
- legacy laptop worker units remain inactive and masked.

## Future runtime acceptance criteria

A future E3Z-EZ installed-unit runtime proof passes only if all of these are true:

1. Exactly one CT203 backup is created before inserting job 56.
2. Exactly one fresh job is inserted.
3. Fresh job id is 56.
4. Fresh job uses prompt `Return exactly this text and nothing else: E3Z-EY-OK`.
5. Fresh job uses requested model `qwen2.5:0.5b`.
6. Fresh job has status queued before timer start.
7. Fresh job has attempts 0 before timer start.
8. Fresh job has result rows 0 before timer start.
9. The worker is constrained to `EDGE_ALLOWED_JOB_IDS=56`.
10. Exactly one installed timer instance is started: `edge-ct101-exact-job-worker@56.timer`.
11. The matching installed service instance runs: `edge-ct101-exact-job-worker@56.service`.
12. The fresh job transitions to completed.
13. The fresh job attempts count is 1.
14. The fresh job has exactly one result row.
15. The response exactly equals `E3Z-EY-OK`.
16. The response sha256 equals the sha256 of exactly `E3Z-EY-OK`.
17. Job 53 remains unchanged.
18. Job 54 remains unchanged.
19. Job 55 remains unchanged.
20. Jobs 37 through 52 remain completed with exactly one result row each.
21. No other jobs are claimed or completed.
22. The installed timer instance is stopped or inactive after the proof.
23. The installed timer instance remains disabled after the proof.
24. The installed service instance is inactive after the proof.
25. The permanent CT101 worker service remains inactive and disabled.
26. No exact-job services are active after the proof.
27. No exact-job timers are active after the proof.
28. CT101 Ollama remains running and healthy.
29. No Docker, CT, VM, SSH, host-resolution, model-pull, scheduler, or template-enablement mutation is observed.
30. Repository is checkpointed only after all checks pass.

## Future runtime failure criteria

The future proof must fail closed if any of these occur:

- job 53 changes,
- job 54 changes,
- job 55 changes unexpectedly,
- job 53, 54, or 55 is reset, deleted, retried, or included in allowed job ids,
- jobs 37 through 52 drift,
- more than one fresh job is inserted,
- the fresh job id is not 56,
- the installed timer starts any service other than the matching exact job instance,
- the worker attempts any job other than job 56,
- the timer repeats and leaves an active timer after cleanup,
- the timer or service template becomes enabled,
- the expected marker is not found,
- the exact response does not match the marker,
- result rows are not exactly one,
- attempts are not exactly one,
- any unapproved runtime mutation is observed.

If the future proof fails after a timer/service/model attempt, job 56 must be preserved as evidence. It must not be reset, deleted, manually completed, or retried silently.

## Roadmap after installed-unit repeatability

After the job56 repeatability proof is complete and checkpointed, the next safe direction is to move from single exact-job installed-unit proofs to queue-system breadth tests.

The queue-system breadth test plan should be staged, not jumped into directly:

### Stage 16 FA: queue breadth and model-routing matrix contract, no-apply

Define a no-apply matrix of different request types and model profiles, including:

- exact marker sanity request,
- short chat request,
- study/tutor explanation request,
- flashcard generation request,
- summarization request,
- structured JSON-style request,
- refusal/safety boundary request,
- longer companion-style request,
- lightweight router/intention request,
- degraded or invalid model request.

Model coverage should include only models already present and approved on CT101/PVESO. No model pulls should happen during the matrix stage.

### Stage 16 FB: queue breadth single-thread runtime proof

Insert a small bounded batch of jobs, but process them serially with one active worker path. Verify each job is claimed once, completed once, and has exactly one result row.

### Stage 16 FC: queue breadth multi-model serial proof

Use multiple requested models or model profiles, still serial execution. Verify routing and model selection without concurrency.

### Stage 16 FD: concurrency preflight no-apply

Define strict concurrency limits, worker count, per-model limits, queue lease constraints, timeout behavior, and failure cleanup rules. This stage must prove the system will not oversubscribe CT101/PVESO.

### Stage 16 FE: limited concurrency runtime proof

Run a small bounded concurrent batch only after the no-apply concurrency contract is complete. Start with low concurrency, likely two active jobs maximum, and only then expand.

### Stage 16 FF: broader concurrency/load proof

Increase breadth and concurrency only after FE passes. This is the earliest stage where a larger batch of different requests should be attempted.

## Concurrency safety rules

Before concurrency is tested, the system must have explicit limits for:

- maximum active jobs,
- maximum active jobs per worker,
- maximum active jobs per model,
- max queue lease duration,
- stale running job detection,
- idempotent result insertion,
- duplicate result prevention,
- job retry policy,
- job cancellation policy,
- model timeout policy,
- cleanup and evidence preservation.

Concurrency testing must not start persistent workers or scheduler dispatch until those limits are documented and explicitly approved.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-EZ`.

Purpose: perform one more fresh installed-unit one-tick runtime proof using job 56, preserving jobs 53 and 54 as failed evidence and job 55 as successful evidence.

E3Z-EZ requires explicit runtime approval because it will insert one fresh job, start one installed timer instance, and call Ollama once.
