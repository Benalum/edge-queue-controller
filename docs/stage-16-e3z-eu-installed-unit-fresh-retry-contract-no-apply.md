# Stage 16 E3Z-EU installed-unit fresh retry contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-ET-R2.
- Base HEAD/origin/main: `e2719b2`.
- Base tag: `controller-stage-16-e3z-et-r2-installed-unit-proof-failure-cleanup-diagnostic-no-retry-2026-06-22`.
- Base commit message: `docs: record stage 16 e3z et installed-unit failure cleanup`.
- Repository state at stage entry: clean.

## Mutation boundary for this stage

This E3Z-EU stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, delete, or mutate jobs,
- retry job 53,
- apply schema,
- start, stop, restart, reload, enable, or disable services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- write CT101 unit files,
- reload systemd,
- start, stop, or restart CTs or VMs,
- mutate Docker containers,
- call Ollama generate, chat, embed, or model endpoints,
- download or pull models,
- mutate SSH config,
- mutate `/etc/hosts`.

## Purpose

E3Z-EU defines the no-apply acceptance contract for a safer installed-unit retry strategy after the E3Z-ET installed-unit runtime proof reached the model validation path but failed exact-marker validation.

The next runtime retry must use a fresh job. It must not reset, delete, or retry job 53.

## Current evidence state

E3Z-ET attempted the first installed-unit one-tick runtime proof with job 53.

The installed path fired correctly:

- installed timer instance: `edge-ct101-exact-job-worker@53.timer`,
- installed service instance: `edge-ct101-exact-job-worker@53.service`,
- timer instance started,
- matching service instance started,
- worker reached model-response validation,
- worker refused with `REFUSE_WORKER_EXACT_MARKER_MISMATCH`.

The proof did not pass because the response did not exactly match the expected marker.

E3Z-ET-R2 then cleaned up only the failed exact instance:

- stopped `edge-ct101-exact-job-worker@53.timer`,
- stopped `edge-ct101-exact-job-worker@53.service`,
- did not reset or delete job 53,
- did not retry job 53,
- did not write the DB,
- did not call Ollama,
- returned active exact-job units to 0,
- returned active exact-job timers to 0,
- preserved default-off posture.

## Preserved job 53 evidence

Job 53 must remain preserved as failure evidence.

Known job 53 state after ET-R2:

- job id: `53`,
- status: `running`,
- attempts: `1`,
- requested model: `qwen2.5:0.5b`,
- job type: `stage16_e3z_limited_persistent_worker_repeat_proof`,
- result rows: `0`,
- expected marker: `E3Z-ET-INSTALLED-TIMER-QWEN25-ONE-TICK-OK`,
- expected response sha256: `b57a6763296de36ae40200fc78c6cf02242a61702a992599d74e6a9db4b4b99f`,
- max job id after ET failure cleanup: `53`.

Job 53 must not be:

- reset,
- deleted,
- manually completed,
- retried,
- reused,
- included in any future `EDGE_ALLOWED_JOB_IDS`.

Future workers must be constrained to a fresh job id only.

## Stable good-job baseline

Jobs 37 through 52 remain the known-good proof window.

The next runtime retry must verify before doing anything else:

- CT203 DB quick check is OK,
- jobs 37 through 52 exist,
- jobs 37 through 52 are completed,
- jobs 37 through 52 each have exactly one result row,
- job 53 remains preserved with status `running`, attempts `1`, and result rows `0`,
- max job id is `53` before inserting the fresh retry job.

## Installed unit baseline

The installed unit files are accepted as present and default-off from E3Z-ES-R2:

- service template: `edge-ct101-exact-job-worker@.service`,
- service path: `/etc/systemd/system/edge-ct101-exact-job-worker@.service`,
- service sha256: `16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e`,
- timer template: `edge-ct101-exact-job-worker@.timer`,
- timer path: `/etc/systemd/system/edge-ct101-exact-job-worker@.timer`,
- timer sha256: `7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390`.

Future runtime retry must verify:

- CT101 is running,
- CT101 Ollama is running and healthy,
- worker sha256 is `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`,
- profile sha256 is `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`,
- installed service sha256 is unchanged,
- installed timer sha256 is unchanged,
- `systemd-analyze verify` passes,
- no exact-job worker units are active,
- no exact-job timers are active,
- the permanent CT101 worker service is inactive and disabled,
- legacy laptop worker units remain inactive and masked,
- the installed timer template remains disabled,
- the installed service template remains static or disabled.

## Fresh retry job requirements

The next runtime retry must insert exactly one fresh job.

Expected next fresh job id: `54`.

The fresh retry job must use:

- requested model: `qwen2.5:0.5b`,
- job type: `stage16_e3z_limited_persistent_worker_repeat_proof`,
- status before timer: `queued`,
- attempts before timer: `0`,
- result rows before timer: `0`,
- max job id after insertion: `54`,
- unique marker not reused from jobs 49 through 53.

The runtime worker must use:

- `EDGE_ALLOWED_JOB_IDS=54`,
- the installed timer instance `edge-ct101-exact-job-worker@54.timer`,
- the installed service instance `edge-ct101-exact-job-worker@54.service`.

It must not include job 53 in the allowed job ids.

## Marker and prompt hardening

The future runtime retry should use a shorter, marker-only prompt strategy to reduce exact-marker mismatch risk.

Recommended marker:

`E3Z-EV-OK`

Recommended prompt:

`Return exactly E3Z-EV-OK`

The expected response sha256 must be computed from exactly the marker text and verified after the run.

The acceptance check remains strict exact match. Do not accept partial matches, whitespace variants, explanations, JSON wrappers, markdown, or extra words.

## Future runtime retry acceptance criteria

A future installed-unit retry stage passes only if all of these are true:

1. Repository HEAD, origin/main, and remote main match the expected E3Z-EU checkpoint.
2. Repository status is clean.
3. CT203 DB quick check is OK.
4. Jobs 37 through 52 remain completed with exactly one result row each.
5. Job 53 remains preserved as running, attempts 1, result rows 0.
6. Max job id is 53 before inserting the fresh job.
7. Exactly one fresh job is inserted.
8. Fresh job id is 54.
9. Fresh job has status queued before timer start.
10. Fresh job has attempts 0 before timer start.
11. Fresh job has result rows 0 before timer start.
12. CT101 installed service and timer template hashes match the E3Z-ES-R2 hashes.
13. CT101 permanent worker service is inactive and disabled before timer start.
14. No exact-job worker unit is active before timer start.
15. No exact-job timer is active before timer start.
16. The installed timer template is disabled before timer start.
17. Exactly one installed timer instance is started: `edge-ct101-exact-job-worker@54.timer`.
18. The matching installed service instance runs: `edge-ct101-exact-job-worker@54.service`.
19. The worker is constrained to `EDGE_ALLOWED_JOB_IDS=54`.
20. The fresh job transitions to completed.
21. The fresh job attempts count is 1.
22. The fresh job has exactly one result row.
23. The response exactly equals the approved marker.
24. The response sha256 equals the expected marker sha256.
25. Job 53 remains unchanged after the retry.
26. Jobs 37 through 52 remain completed with exactly one result row each after the retry.
27. No other jobs are claimed or completed.
28. The installed timer instance is inactive after the proof.
29. The installed timer instance remains disabled after the proof.
30. The installed service instance is inactive after the proof.
31. The permanent CT101 worker service remains inactive and disabled.
32. No exact-job worker units are active after the proof.
33. No exact-job timers are active after the proof.
34. CT101 Ollama remains running and healthy.
35. No Docker, CT, VM, SSH, host-resolution, model-pull, scheduler, or template-enablement mutation is observed.
36. Repository is checkpointed only after all checks pass.

## Future runtime retry failure criteria

The future retry must fail closed if any of these occur:

- job 53 changes,
- job 53 is reset, deleted, retried, or included in allowed job ids,
- jobs 37 through 52 drift,
- more than one fresh job is inserted,
- the fresh job id is not 54,
- the installed timer starts any service other than the matching exact job instance,
- the worker attempts any job other than the fresh job,
- the timer repeats,
- the timer or service remains active after the proof,
- the timer or service template becomes enabled,
- the exact response does not match the marker,
- result rows are not exactly one,
- attempts are not exactly one,
- any unapproved runtime mutation is observed.

## Abort and cleanup posture

If the future retry fails after a timer/service/model attempt, the fresh job must be preserved as evidence just like job 53.

The cleanup path may stop only the exact failed timer/service instance. It must not reset jobs, delete rows, apply schema, mutate Docker, restart CTs or VMs, pull models, or perform broad cleanup unless separately approved.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-EV`.

Purpose: perform a fresh-job installed-unit one-tick runtime retry using the installed exact-job timer/service templates, preserving job 53 as evidence and using a shorter marker-only prompt.

E3Z-EV requires explicit runtime approval because it will insert one fresh job, start one installed timer instance, and call Ollama once.
