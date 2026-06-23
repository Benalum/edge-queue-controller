# Stage 16 E3Z-EW installed-unit job55 compatible-marker retry contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EV-R2.
- Base HEAD/origin/main: `dc4899a`.
- Base tag: `controller-stage-16-e3z-ev-r2-installed-unit-marker-extraction-failure-diagnostic-no-retry-2026-06-22`.
- Repository state at stage entry: clean.

## Mutation boundary for this stage

This E3Z-EW stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, delete, or retry jobs,
- retry job 53,
- retry job 54,
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

E3Z-EW defines the no-apply acceptance contract for the next installed-unit runtime retry after:

- E3Z-ET job 53 reached response validation but failed exact match with `REFUSE_WORKER_EXACT_MARKER_MISMATCH`,
- E3Z-EV job 54 reached marker extraction but failed with `REFUSE_EXPECTED_MARKER_NOT_FOUND`.

The next retry must preserve jobs 53 and 54 as evidence and use fresh job 55 only.

## Current evidence state

Known failed installed-unit evidence:

- job 53: running, attempts 1, result rows 0,
- job 54: running, attempts 1, result rows 0,
- jobs 37 through 52: completed, one result row each,
- max job id after E3Z-EV-R2: 54.

Known CT101 posture after E3Z-EV-R2:

- job54 timer instance inactive and disabled,
- job54 service instance failed/static with result exit-code,
- active exact-job worker units: 0,
- active exact-job timers: 0,
- permanent CT101 worker inactive and disabled,
- installed timer template disabled,
- installed service template static,
- Ollama running and healthy.

## Preservation rule

Jobs 53 and 54 are evidence.

Neither job may be:

- reset,
- deleted,
- manually completed,
- retried,
- reused,
- included in any future `EDGE_ALLOWED_JOB_IDS`.

Future workers must be constrained to a fresh job id only.

## Marker extraction finding

The short E3Z-EV prompt was:

    Return exactly E3Z-EV-OK

That failed before response comparison with:

    REFUSE_EXPECTED_MARKER_NOT_FOUND

The likely reason is that the worker expects the marker to be embedded in the known extraction-compatible prompt shape.

The next retry must restore the known compatible prompt shape while keeping the marker short.

## Future retry marker contract

The next runtime retry should use fresh job 55.

Recommended future marker:

    E3Z-EW-OK

Recommended future prompt:

    Return exactly this text and nothing else: E3Z-EW-OK

Expected marker sha256 must be computed from exactly:

    E3Z-EW-OK

The acceptance check must remain strict exact-match. Do not accept partial matches, whitespace variants, explanations, JSON wrappers, markdown, or extra words.

## Future fresh job requirements

The next runtime retry must insert exactly one fresh job.

Expected next fresh job id: `55`.

The fresh retry job must use:

- requested model: `qwen2.5:0.5b`,
- job type: `stage16_e3z_limited_persistent_worker_repeat_proof`,
- status before timer: `queued`,
- attempts before timer: `0`,
- result rows before timer: `0`,
- max job id after insertion: `55`,
- marker: `E3Z-EW-OK`,
- prompt: `Return exactly this text and nothing else: E3Z-EW-OK`.

The runtime worker must use:

- `EDGE_ALLOWED_JOB_IDS=55`,
- installed timer instance `edge-ct101-exact-job-worker@55.timer`,
- installed service instance `edge-ct101-exact-job-worker@55.service`.

It must not include job 53 or job 54 in the allowed job ids.

## Pre-runtime verification required

A future runtime retry must verify before inserting job 55:

- repo HEAD, origin/main, and remote main match the E3Z-EW checkpoint,
- repo status is clean,
- CT203 DB quick check is OK,
- jobs 37 through 52 exist,
- jobs 37 through 52 are completed,
- jobs 37 through 52 each have exactly one result row,
- job 53 remains running, attempts 1, result rows 0,
- job 54 remains running, attempts 1, result rows 0,
- max job id is 54,
- CT101 is running,
- CT101 Ollama is running and healthy,
- worker sha256 is `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`,
- profile sha256 is `329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d`,
- installed service sha256 is `16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e`,
- installed timer sha256 is `7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390`,
- no exact-job worker unit is active,
- no exact-job timer is active,
- the installed timer template remains disabled,
- the permanent CT101 worker service remains inactive and disabled,
- legacy laptop worker units remain inactive and masked.

## Future runtime acceptance criteria

A future installed-unit runtime retry passes only if all of these are true:

1. Exactly one CT203 backup is created before inserting job 55.
2. Exactly one fresh job is inserted.
3. Fresh job id is 55.
4. Fresh job uses prompt `Return exactly this text and nothing else: E3Z-EW-OK`.
5. Fresh job uses requested model `qwen2.5:0.5b`.
6. Fresh job has status queued before timer start.
7. Fresh job has attempts 0 before timer start.
8. Fresh job has result rows 0 before timer start.
9. The worker is constrained to `EDGE_ALLOWED_JOB_IDS=55`.
10. Exactly one installed timer instance is started: `edge-ct101-exact-job-worker@55.timer`.
11. The matching installed service instance runs: `edge-ct101-exact-job-worker@55.service`.
12. The fresh job transitions to completed.
13. The fresh job attempts count is 1.
14. The fresh job has exactly one result row.
15. The response exactly equals `E3Z-EW-OK`.
16. The response sha256 equals the sha256 of exactly `E3Z-EW-OK`.
17. Job 53 remains unchanged.
18. Job 54 remains unchanged.
19. Jobs 37 through 52 remain completed with exactly one result row each.
20. No other jobs are claimed or completed.
21. The installed timer instance is stopped or inactive after the proof.
22. The installed timer instance remains disabled after the proof.
23. The installed service instance is inactive after the proof.
24. The permanent CT101 worker service remains inactive and disabled.
25. No exact-job worker units are active after the proof.
26. No exact-job timers are active after the proof.
27. CT101 Ollama remains running and healthy.
28. No Docker, CT, VM, SSH, host-resolution, model-pull, scheduler, or template-enablement mutation is observed.
29. Repository is checkpointed only after all checks pass.

## Future runtime failure criteria

The future retry must fail closed if any of these occur:

- job 53 changes,
- job 54 changes,
- job 53 or job 54 is reset, deleted, retried, or included in allowed job ids,
- jobs 37 through 52 drift,
- more than one fresh job is inserted,
- the fresh job id is not 55,
- the installed timer starts any service other than the matching exact job instance,
- the worker attempts any job other than job 55,
- the timer repeats,
- the timer or service remains active after the proof,
- the timer or service template becomes enabled,
- the expected marker is not found,
- the exact response does not match the marker,
- result rows are not exactly one,
- attempts are not exactly one,
- any unapproved runtime mutation is observed.

## Abort and cleanup posture

If the future retry fails after a timer/service/model attempt, job 55 must be preserved as evidence just like jobs 53 and 54.

The cleanup path may stop only the exact failed timer/service instance. It must not reset jobs, delete rows, apply schema, mutate Docker, restart CTs or VMs, pull models, or perform broad cleanup unless separately approved.

## Recommended next stage

Recommended next stage: `Stage 16 E3Z-EX`.

Purpose: perform a fresh-job installed-unit one-tick runtime retry using job 55, preserving jobs 53 and 54 as evidence, and restoring the known marker-extraction-compatible prompt shape.

E3Z-EX requires explicit runtime approval because it will insert one fresh job, start one installed timer instance, and call Ollama once.
