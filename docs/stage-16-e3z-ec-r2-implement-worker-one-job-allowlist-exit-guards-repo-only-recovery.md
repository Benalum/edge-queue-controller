# Stage 16 E3Z-EC-R2 — Implement Worker One-Job Allowlist / Exit Guards — Repo Only Recovery

## Purpose

Implement the worker-side hard guards required before any limited persistent CT101 worker service proof.

This stage is repository-only. It does not access live hosts, install files on CT101, mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Recovery note

EC-R1 wrote the repo worker file and passed the worker self-test, but failed before docs/commit/tag because a static validation marker was missing from the implementation text:

```text
REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED
```

EC-R2 accepts only the expected dirty worker file, adds the exact-claim refusal marker path, reruns the worker self-test, and records the completed repo-only checkpoint.

## Repo mutation

Updated:

```text
ops/workers/ct101_minimal_ollama_worker.py
```

## Guard variables implemented

The worker now parses and validates:

```text
EDGE_ALLOWED_JOB_IDS
EDGE_EXIT_AFTER_ONE_SUCCESS
EDGE_MAX_RUNTIME_SECONDS
EDGE_REFUSE_IF_SCHEDULER_ACTIVE
EDGE_REFUSE_IF_TIMER_ACTIVE
EDGE_PROOF_MODE=limited_persistent_one_job
```

## Preserved behavior

The proven direct/transient one-shot path remains supported:

```text
--once --job-id <id>
```

The worker still refuses by default when disabled:

```text
REFUSE_WORKER_DISABLED
```

The exact model output validation remains intact and now emits:

```text
REFUSE_WORKER_EXACT_MARKER_MISMATCH
```

## New refusal markers

```text
REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID
REFUSE_WORKER_EXIT_AFTER_ONE_SUCCESS_REQUIRED
REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID
REFUSE_WORKER_MAX_RUNTIME_SECONDS_EXCEEDED
REFUSE_WORKER_SCHEDULER_ACTIVE
REFUSE_WORKER_TIMER_ACTIVE
REFUSE_WORKER_PROOF_MODE_GUARD_FAILED
REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED
REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED
REFUSE_WORKER_REQUESTED_MODEL_MISMATCH
REFUSE_WORKER_JOB_TYPE_NOT_ALLOWED
REFUSE_WORKER_EXACT_MARKER_MISMATCH
REFUSE_WORKER_MULTIPLE_JOBS_CLAIMED_IN_PROOF_MODE
REFUSE_MAIN_LOOP_REQUIRES_LIMITED_PROOF_MODE
```

## New success marker

Limited persistent proof mode success prints:

```text
E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1
```

## Self-test result

The repo self-test verifies:

```text
EDGE_ALLOWED_JOB_IDS parses one id
EDGE_ALLOWED_JOB_IDS refuses invalid values
EDGE_ALLOWED_JOB_IDS refuses multiple ids in proof mode
EDGE_EXIT_AFTER_ONE_SUCCESS is required in proof mode
EDGE_MAX_RUNTIME_SECONDS is required in proof mode
EDGE_MAX_RUNTIME_SECONDS refuses invalid values
proof mode refuses model concurrency
proof mode refuses without exact job allowlist
--once --job-id behavior still has a local allowlist guard
disabled worker still refuses with REFUSE_WORKER_DISABLED
```

Expected self-test markers:

```text
E3Z_EC_WORKER_GUARD_SELF_TEST_OK=1
E3Z_CS_WORKER_SELF_TEST_OK=1
```

## Future live-install boundary

This stage did not install the updated worker on CT101.

The next live install phase must require explicit approval and remain disabled-only:

```text
APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START
```

## Non-goals

Do not install this worker on CT101 in EC-R2.

Do not mutate CT203 DB in EC-R2.

Do not call models in EC-R2.

Do not start CT101 worker service in EC-R2.

Do not enable or unmask worker services in EC-R2.

Do not activate scheduler or timer in EC-R2.

Do not insert any new proof jobs in EC-R2.

Do not enable persistent worker behavior in EC-R2.

## Recommended next step

Proceed with ED: install updated worker files disabled only, no start.

ED is a live CT101 file update and requires explicit approval.
