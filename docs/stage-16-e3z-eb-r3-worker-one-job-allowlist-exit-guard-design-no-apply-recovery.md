# Stage 16 E3Z-EB-R3 — Worker One-Job Allowlist / Exit Guard Design — No Apply Recovery

## Purpose

Design the worker-side hard guards required before any limited persistent CT101 worker service proof.

This is a repository-only no-apply design checkpoint. It does not access live hosts, mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Recovery note

EB-R1 failed before commit/tag because its smoke looked for a wording variant that was not present exactly. EB-R2 then refused because the EB-R1 failure left two untracked generated artifacts. EB-R3 removes only those two known failed untracked artifacts and records the corrected design checkpoint. No live mutation occurred during EB-R1 or EB-R2.

## Why this guard is needed

Stage 16 E3Z already proved two safe one-shot paths:

```text
job 45 direct installed-worker one-shot:
E3Z-WORKER-QWEN25-ONE-SHOT-OK

job 46 service-managed transient systemd one-shot:
E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
```

A persistent worker service is a higher risk because it can keep claiming work. Before using the installed service as even a limited proof, the worker itself needs hard controls that prevent queue-drain behavior.

## Target safety properties

The worker must be able to run in a bounded persistent-service proof while guaranteeing:

1. It can only claim an explicitly allowlisted job id.
2. It exits after one successful completion when configured to do so.
3. It exits on max runtime timeout.
4. It refuses if scheduler/timer activation is detected when configured to refuse.
5. It refuses model concurrency.
6. It refuses if multiple allowed job ids are provided for the first proof.
7. It refuses if the exact job id is not queued and eligible.
8. It never claims jobs outside the allowlist.
9. It logs clear refusal reasons without exposing secrets.
10. It preserves the installed disabled posture after the proof.

## New worker environment variables

### EDGE_ALLOWED_JOB_IDS

Comma-separated list of allowed job ids.

For the first limited persistent proof this must contain exactly one id.

Example:

```text
EDGE_ALLOWED_JOB_IDS=47
```

Validation:

- absent or empty: allowed for current direct/transient one-shot paths only if `--job-id` is explicitly provided
- for persistent service proof: must be exactly one integer id
- non-integer values: refuse
- more than one id during first proof: refuse
- zero or negative ids: refuse

Refusal marker:

```text
REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID
```

### EDGE_EXIT_AFTER_ONE_SUCCESS

Boolean, default false.

For the first limited persistent proof this must be true.

Example:

```text
EDGE_EXIT_AFTER_ONE_SUCCESS=1
```

Behavior:

- after one successful completion, exit with code 0
- if no job completed before max runtime, exit nonzero
- if model output is non-exact, do not continue to another job

Refusal marker if disabled during persistent proof:

```text
REFUSE_WORKER_EXIT_AFTER_ONE_SUCCESS_REQUIRED
```

### EDGE_MAX_RUNTIME_SECONDS

Positive integer max runtime for a bounded worker loop.

Recommended first proof value:

```text
EDGE_MAX_RUNTIME_SECONDS=180
```

Behavior:

- stop attempting claims after runtime expires
- if a claim is in progress, do not interrupt DB completion mid-write
- after timeout, exit nonzero if no success occurred
- record clear timeout output

Refusal marker:

```text
REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID
```

Timeout marker:

```text
REFUSE_WORKER_MAX_RUNTIME_SECONDS_EXCEEDED
```

### EDGE_REFUSE_IF_SCHEDULER_ACTIVE

Boolean, default true for proof mode.

Example:

```text
EDGE_REFUSE_IF_SCHEDULER_ACTIVE=1
```

Behavior:

- worker should check configured scheduler sentinel or process/unit state if available
- if the scheduler is active, refuse before claiming work

Refusal marker:

```text
REFUSE_WORKER_SCHEDULER_ACTIVE
```

### EDGE_REFUSE_IF_TIMER_ACTIVE

Boolean, default true for proof mode.

Example:

```text
EDGE_REFUSE_IF_TIMER_ACTIVE=1
```

Behavior:

- worker should check configured timer sentinel or process/unit state if available
- if timer activation is active, refuse before claiming work

Refusal marker:

```text
REFUSE_WORKER_TIMER_ACTIVE
```

### EDGE_PROOF_MODE

Boolean or mode string.

Recommended first proof value:

```text
EDGE_PROOF_MODE=limited_persistent_one_job
```

Behavior:

- enables strict one-job proof validation
- requires `EDGE_ALLOWED_JOB_IDS`
- requires `EDGE_EXIT_AFTER_ONE_SUCCESS=1`
- requires `EDGE_MAX_RUNTIME_SECONDS`
- requires concurrency disabled
- refuses if scheduler/timer guards are disabled

Refusal marker:

```text
REFUSE_WORKER_PROOF_MODE_GUARD_FAILED
```

## CLI behavior

The current direct/transient one-shot path uses:

```text
--once --job-id <id>
```

That exact CLI behavior should remain supported.

For limited persistent proof mode, the worker can be started without `--once`, but only if strict proof-mode env variables are present:

```text
EDGE_WORKER_ENABLED=1
EDGE_PROOF_MODE=limited_persistent_one_job
EDGE_ALLOWED_JOB_IDS=<fresh_job_id>
EDGE_EXIT_AFTER_ONE_SUCCESS=1
EDGE_MAX_RUNTIME_SECONDS=180
EDGE_CLAIM_POLICY=one_at_a_time
EDGE_ALLOW_MODEL_CONCURRENCY=0
```

The worker should then loop only within the bounded runtime and claim only the allowed job.

## Claim filtering behavior

Before calling the claim endpoint, the worker should enforce allowlist behavior locally.

Preferred behavior for exact-job claim:

1. If `--job-id` is provided, treat that as the exact allowed job id.
2. If `EDGE_ALLOWED_JOB_IDS` is provided, parse it.
3. If both are provided, they must match exactly.
4. If proof mode is `limited_persistent_one_job`, exactly one allowed id is required.
5. The worker should request/claim only that exact id if the API supports exact id claim.
6. If the API only supports generic claim, the worker must refuse persistent proof mode until exact-id claim support is confirmed.

Refusal marker:

```text
REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED
```

## Completion filtering behavior

The worker must complete only the claimed allowed job.

The worker must refuse to complete if:

- returned job id differs from the allowed id
- requested_model differs from profile model
- job_type is not allowed by the selected profile
- result does not match the exact expected marker for proof jobs
- more than one job was claimed in proof mode

Refusal markers:

```text
REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED
REFUSE_WORKER_REQUESTED_MODEL_MISMATCH
REFUSE_WORKER_JOB_TYPE_NOT_ALLOWED
REFUSE_WORKER_EXACT_MARKER_MISMATCH
REFUSE_WORKER_MULTIPLE_JOBS_CLAIMED_IN_PROOF_MODE
```

## State counters

For proof mode, the worker should track:

```text
claimed_count
completed_count
failed_count
skipped_count
started_at
elapsed_seconds
last_claimed_job_id
last_completed_job_id
```

Proof mode success requires:

```text
claimed_count == 1
completed_count == 1
failed_count == 0
last_claimed_job_id == allowed_job_id
last_completed_job_id == allowed_job_id
```

Success marker:

```text
E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS
```

## Minimal implementation plan for EC

EC should update `ops/workers/ct101_minimal_ollama_worker.py` only in the repository.

Implementation additions:

1. Add parser for `EDGE_ALLOWED_JOB_IDS`.
2. Add boolean parser for `EDGE_EXIT_AFTER_ONE_SUCCESS`.
3. Add integer parser for `EDGE_MAX_RUNTIME_SECONDS`.
4. Add proof-mode validator for `EDGE_PROOF_MODE=limited_persistent_one_job`.
5. Add local exact-job allowlist checks before claim.
6. Add one-job proof counters.
7. Add max-runtime loop guard.
8. Preserve the existing `--once --job-id` behavior.
9. Preserve disabled default: `EDGE_WORKER_ENABLED=0` refuses.
10. Add self-test cases for all new refusal paths.

EC must not:

- install files on CT101
- mutate CT203 DB
- call models
- start workers
- activate scheduler/timer

## Self-test requirements for EC

The worker self-test should verify:

```text
EDGE_ALLOWED_JOB_IDS parses one id
EDGE_ALLOWED_JOB_IDS refuses non-integers
EDGE_ALLOWED_JOB_IDS refuses multiple ids in proof mode
EDGE_EXIT_AFTER_ONE_SUCCESS required in proof mode
EDGE_MAX_RUNTIME_SECONDS required in proof mode
EDGE_MAX_RUNTIME_SECONDS refuses invalid values
proof mode refuses model concurrency
proof mode refuses without exact job allowlist
--once --job-id behavior still works
disabled worker still refuses with REFUSE_WORKER_DISABLED
```

## Future phase gates

### EC — implement worker one-job allowlist/exit guard in repo only

Repository mutation only.

No live installation and no activation.

### ED — install updated worker files disabled only

Requires approval:

```text
APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START
```

### EE — add limited persistent job type to qwen25 profile, no worker start

Requires approval:

```text
APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

### EF — insert one fresh limited persistent proof job only

Requires approval:

```text
APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY
```

### EG — run limited persistent worker service exact job only

Requires approval:

```text
APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_ONLY
```

## Recommended next step

Proceed with EC: implement worker one-job allowlist/exit guard in repo only.

This is repo-only code mutation, but it affects future live activation behavior, so it should be reviewed carefully before installation.
