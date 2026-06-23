# Stage 16 FB-R4 general_queue worker mode repo implementation no-runtime

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FB-R4A.
- Base HEAD/origin/main: `86c8590`.
- Base tag: `controller-stage-16-fb-r4a-general-queue-worker-source-contract-preflight-no-apply-2026-06-22`.

## Recovery note

The first FB-R4 implementation attempt patched and compiled the worker but failed in the dynamic test harness because the dataclass module was loaded with `importlib` without registering the module in `sys.modules` before `exec_module`.

The second FB-R4 recovery used the corrected import but passed a string where `validate_completion` expected a profile object.

FB-R4-R3 kept the already patched worker source, reran the dynamic smoke with both the corrected import procedure and a dummy profile object carrying `completion_validation_policy=exact_marker_only`, and checkpointed the repo-only implementation.

## Mutation boundary

This FB-R4 stage changed repo source and tests only.

It did not:

- write the CT203 database,
- insert, reset, delete, retry, or manually complete jobs,
- retry jobs 53 through 58,
- process jobs 59 through 64,
- apply schema,
- write CT101 unit files,
- run daemon-reload,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- restart CTs or VMs.

## Worker implementation

Worker path:

- `ops/workers/ct101_minimal_ollama_worker.py`

Worker sha:

- before: `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`
- after: `25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca`

FB-R4 added an explicit worker mode check inside `validate_completion`.

Supported modes:

    EDGE_WORKER_MODE=exact_marker
    EDGE_WORKER_MODE=general_queue

Default behavior remains exact-marker compatible.

## Exact-marker behavior preserved

When `EDGE_WORKER_MODE` is unset or set to `exact_marker`, the worker still requires marker extraction.

The dynamic smoke confirmed:

    default_missing_marker_refusal=REFUSE_EXPECTED_MARKER_NOT_FOUND
    explicit_exact_marker_missing_marker_refusal=REFUSE_EXPECTED_MARKER_NOT_FOUND

This preserves the proof-worker behavior used by jobs 55, 56, and 57.

## General queue behavior added

When `EDGE_WORKER_MODE=general_queue`, `validate_completion` no longer requires marker extraction.

The dynamic smoke confirmed:

    general_queue_missing_marker_allowed=true

The implementation still fails closed for unsafe general queue output states:

    REFUSE_GENERAL_QUEUE_EMPTY_RESPONSE
    REFUSE_GENERAL_QUEUE_RESPONSE_TOO_LARGE
    REFUSE_GENERAL_QUEUE_INVALID_MAX_RESPONSE_CHARS
    REFUSE_UNKNOWN_WORKER_MODE

## What this does not prove yet

FB-R4 does not prove live CT101 runtime behavior.

It does not:

- deploy the changed worker to CT101,
- modify the installed systemd service,
- add `EDGE_WORKER_MODE=general_queue` to a runtime unit,
- process jobs,
- call Ollama,
- clean up job58 failed systemd state.

Those require later explicit runtime or deployment stages.

## Evidence preservation

Current evidence remains locked:

- job 57: completed exact marker evidence,
- job 58: running failed evidence,
- jobs 59 through 64: queued evidence.

Do not reset, delete, manually complete, or silently retry them.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R4B`.

Purpose: define a no-apply deployment contract for installing the updated worker onto CT101 and selecting `EDGE_WORKER_MODE=general_queue` only for future fresh breadth jobs, likely jobs 65 through 72.

FB-R4B should also decide whether to perform a cleanup-only `reset-failed` for `edge-ct101-exact-job-worker@58.service`, keeping it separate from queue breadth runtime proof.
