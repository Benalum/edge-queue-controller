# Stage 16 FB-R4B CT101 general_queue worker deployment contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FB-R4.
- Base HEAD/origin/main: `f45a80b`.
- Base tag: `controller-stage-16-fb-r4-general-queue-worker-mode-repo-implementation-no-runtime-2026-06-22`.

## Recovery note

The first FB-R4B attempt wrote the deployment-contract doc and smoke, then failed during focused smoke because the smoke expected overly specific wording. FB-R4B-R2 keeps the same repo-only no-apply scope, rewrites the doc/smoke pair with stable wording, and checkpoints the contract.

## Mutation boundary

This FB-R4B stage is repo docs/smoke only.

It does not:

- deploy the worker,
- write CT101 files,
- write systemd unit files,
- run daemon-reload,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- write the CT203 database,
- insert, reset, delete, retry, or manually complete jobs,
- retry jobs 53 through 58,
- process jobs 59 through 64,
- apply schema,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- restart CTs or VMs.

## Source state

Repo worker:

- Path: `ops/workers/ct101_minimal_ollama_worker.py`.
- Old live CT101 worker sha from previous evidence: `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
- New repo worker sha: `25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca`.

FB-R4 added:

- `EDGE_WORKER_MODE=exact_marker`,
- `EDGE_WORKER_MODE=general_queue`,
- default exact-marker behavior,
- general queue response validation.

## Deployment goal

A future apply stage should install the updated repo worker on CT101 without activating queue breadth runtime.

Deployment should be separated from runtime proof.

Recommended split:

1. FB-R4C: deploy updated worker file to CT101 only, verify hash, no timer/service start.
2. FB-R4D: optional cleanup-only reset-failed for job58 service only, no DB changes.
3. FB-R4E: define or install separate general queue service/timer template, no job processing unless separately approved.
4. FB-R5: fresh corrected serial queue breadth runtime using jobs 65 through 72.

## FB-R4C deploy-only contract

A future FB-R4C apply stage may:

- copy `ops/workers/ct101_minimal_ollama_worker.py` from repo to CT101 path `/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py`,
- preserve a timestamped backup of the old CT101 worker file,
- verify old CT101 worker sha before replacement equals `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`,
- verify new CT101 worker sha after replacement equals `25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca`,
- run Python compile check against the installed CT101 worker file,
- leave installed systemd timer/service templates unchanged,
- leave permanent worker disabled,
- leave scheduler disabled,
- leave exact-job timers inactive,
- perform no DB writes,
- perform no model calls.

FB-R4C must not:

- start any timer,
- start any service,
- enable any timer,
- enable any service,
- run daemon-reload unless a systemd unit file is changed,
- reset failed units,
- process jobs,
- call Ollama,
- mutate Docker.

## Runtime mode selection contract

The current installed timer/service template remains the exact-job launcher.

Since FB-R4 only changed the worker source, future runtime needs an explicit way to pass `EDGE_WORKER_MODE=general_queue` for general queue jobs.

Allowed future design options:

### Option A: separate general_queue installed service/timer template

Create a new template pair:

- `edge-ct101-general-queue-job-worker@.service`,
- `edge-ct101-general-queue-job-worker@.timer`.

The general queue service sets:

    EDGE_WORKER_MODE=general_queue

The exact-marker existing service remains unchanged.

Advantages:

- clear separation between proof mode and general queue mode,
- no accidental weakening of exact-marker proofs,
- easy evidence tracking by unit name.

Recommended option: Option A.

### Option B: update exact-job template to include an EnvironmentFile

This is not recommended for the first corrected breadth proof because it risks cross-contamination between exact-marker and general queue runs.

### Option C: encode worker mode in job metadata

This is not recommended for the first corrected breadth proof because it requires more DB/job schema coupling than needed.

## Recommended unit strategy

Use Option A later.

Future FB-R4E should define or install a separate general queue template pair, no runtime.

The existing exact-marker template remains for exact-marker proof jobs.

Future fresh breadth jobs 65 through 72 should use:

- job 65 through exact-marker template,
- jobs 66 through 72 through general_queue template.

## Job evidence preservation

Current evidence remains locked:

- jobs 37 through 52: completed, one result row each,
- job 53: running, attempts 1, result rows 0,
- job 54: running, attempts 1, result rows 0,
- job 55: completed, attempts 1, result rows 1, response `E3Z-EW-OK`,
- job 56: completed, attempts 1, result rows 1, response `E3Z-EY-OK`,
- job 57: completed, attempts 1, result rows 1, response `STAGE16-FB-J57-OK`,
- job 58: running, attempts 1, result rows 0,
- jobs 59 through 64: queued, attempts 0, result rows 0.

Do not reset, delete, manually complete, or silently retry them.

## Job58 reset-failed policy

Job58 service failed state is preserved evidence.

A future cleanup-only reset-failed stage may be allowed only after explicit approval and only for:

    edge-ct101-exact-job-worker@58.service

That stage must not:

- change CT203 DB/job state,
- retry job58,
- process jobs 59 through 64,
- start any timer or service,
- call Ollama.

Recommended timing: after deployment contract is documented and before any fresh runtime proof that requires a clean systemd failed-unit view.

## Fresh corrected breadth proof

Future fresh corrected breadth runtime should not reuse jobs 57 through 64 by default.

Recommended new batch:

| Planned job | Category | Worker mode | Unit family |
|---|---|---|---|
| 65 | exact marker sanity | `exact_marker` | existing exact-job |
| 66 | companion chat | `general_queue` | new general queue |
| 67 | study/tutor | `general_queue` | new general queue |
| 68 | flashcards | `general_queue` | new general queue |
| 69 | summary | `general_queue` | new general queue |
| 70 | JSON-style | `general_queue` | new general queue |
| 71 | router label | `general_queue` | new general queue |
| 72 | safe refusal boundary | `general_queue` | new general queue |

No concurrency yet.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R4C`.

Purpose: deploy updated worker file to CT101 only and verify old/new hashes, with no timer/service start, no DB write, no model call, no systemd unit mutation, and no runtime activation.

FB-R4C requires explicit approval because it writes the CT101 worker file.
