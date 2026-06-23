# Stage 16 FB-R4A general_queue worker source contract preflight no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FB-R3.
- Base HEAD/origin/main: `d02eac3`.
- Base tag: `controller-stage-16-fb-r3-corrected-queue-breadth-worker-strategy-no-apply-2026-06-22`.

## Recovery note

The first FB-R4A attempt completed worker inventory but failed during focused smoke because the generated smoke expected a phrase without the same inline formatting used in the document. FB-R4A-R2 keeps the same repo-only scope, rewrites the doc/smoke pair, and checkpoints the same source contract.

## Mutation boundary

This FB-R4A stage is repo docs/smoke only.

It does not:

- change worker code,
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

## Source inventory

- Worker path: `ops/workers/ct101_minimal_ollama_worker.py`.
- Worker sha256 at preflight: `69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f`.
- Worker line count: `707`.
- Python compile result: `0`.

Detected functions:

    parse_bool,parse_allowed_job_ids,parse_optional_positive_int,load_env,load_token,_import_yaml,load_model_profiles,validate_model_profile_document,validate_allowed_job_id,validate_limited_proof_mode,_active_systemd_lines,_active_timer_lines,guard_scheduler_timer_inactive,runtime_preflight,get_eligible_profile_for_job,build_ollama_command,clean_model_output,extract_expected_marker,validate_completion,_post_json,_extract_claimed_job,claim_one_job,run_ollama_call,complete_job,run_one_claim_complete,main_once,main_loop,_expect_refusal,_self_test,main

Detected classes:

    WorkerRefusal,WorkerConfig,ModelProfile

Detected source signals:

    has_EDGE_ALLOWED_JOB_IDS=true
    has_EDGE_WORKER_MODE=false
    has_general_queue_reference=false
    has_REFUSE_EXPECTED_MARKER_NOT_FOUND=true
    has_job_results_reference=false
    has_sqlite_reference=false

## Current conclusion

The current worker source compiles and contains exact-marker refusal behavior.

The source inventory also shows:

- `EDGE_ALLOWED_JOB_IDS` support is present,
- `REFUSE_EXPECTED_MARKER_NOT_FOUND` behavior is present,
- `EDGE_WORKER_MODE` is not yet present,
- `general_queue` is not yet present,
- direct `job_results` and `sqlite3` handling are not present in this worker source.

FB-R3 already established the current runtime behavior:

- job 57 completed through exact marker,
- job 58 failed with `REFUSE_EXPECTED_MARKER_NOT_FOUND`,
- job 58 remains preserved failed evidence,
- jobs 59 through 64 remain queued evidence.

FB-R4A confirms that the next code stage should patch the worker source rather than retry FB runtime.

## Required FB-R4 implementation contract

FB-R4 should be repo-only code implementation.

It should add an explicit worker mode contract:

    EDGE_WORKER_MODE=exact_marker
    EDGE_WORKER_MODE=general_queue

The existing behavior must remain the default until the installed service explicitly opts into another mode.

Required default:

- default mode remains exact-marker compatible,
- existing exact-marker tests and proof behavior remain valid,
- missing-marker prompt continues to fail closed in exact-marker mode.

Required general queue behavior:

- general_queue mode must not require marker extraction,
- general_queue mode must still require exactly one allowed job id,
- general_queue mode must claim only that allowed job id,
- general_queue mode must produce exactly one result row through the existing API/result path,
- general_queue mode must not process broad queues,
- general_queue mode must enforce bounded response text,
- general_queue mode must preserve failure evidence on model/API errors,
- general_queue mode must not silently complete failed jobs.

## Required FB-R4 tests

FB-R4 should add tests or smokes that prove:

1. Worker source compiles.
2. Exact-marker default remains present.
3. Exact-marker mode refuses missing marker.
4. Exact-marker mode can still validate exact marker response.
5. General queue mode does not require marker extraction.
6. General queue mode still requires a single `EDGE_ALLOWED_JOB_IDS`.
7. General queue mode has duplicate-result prevention or explicit refusal.
8. General queue mode has bounded response handling.
9. General queue mode does not change CT203 or CT101 at implementation time.
10. No runtime worker, timer, service, scheduler, Docker, or Ollama call happens in FB-R4.

## Future runtime after implementation

After FB-R4 implementation and repo tests pass, do not use jobs 57 through 64 for the corrected breadth proof unless explicitly approved.

Recommended corrected runtime path remains:

- fresh jobs 65 through 72,
- exact marker sanity via `exact_marker`,
- companion/study/flashcard/summary/JSON/router/refusal jobs via `general_queue`,
- serial processing only,
- no concurrency,
- one installed timer/service invocation at a time,
- no persistent scheduler/worker enablement.

## Job evidence preservation

Current evidence remains locked:

- job 57: completed exact marker evidence,
- job 58: running failed evidence,
- jobs 59 through 64: queued evidence.

Do not reset, delete, manually complete, or silently retry them.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R4`.

Purpose: implement `EDGE_WORKER_MODE=general_queue` in repo only, preserving exact-marker mode and adding source-level tests/smokes. No runtime activation.
