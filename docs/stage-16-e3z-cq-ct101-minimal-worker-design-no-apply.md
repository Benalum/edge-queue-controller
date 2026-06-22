# Stage 16 E3Z-CQ — CT101 Minimal Worker Design — No Apply

## Purpose

Design a default-off CT101 worker that can eventually consume CT203 jobs through the native internal worker API and run Ollama Docker model calls according to the Stage 16 E3Z model profile artifact.

This is a repository-only no-apply stage.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, create systemd units, enable timers, or activate scheduler paths.

## Prior checkpoint

Stage 16 E3Z-CP created:

```text
ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
```

Current checkpoint entering CQ:

- repo: 43cc563
- tag: controller-stage-16-e3z-cp-create-model-profile-artifact-repo-only-2026-06-22
- status: clean

## Current proven runtime posture

The current proven CT101 runtime posture is:

- CT101 worker service remains inactive and masked
- Docker and containerd are active
- only the `ollama` Docker container is running
- scheduler/timer paths remain inactive
- no broad `/opt/ai-platform` compose stack is running
- CT203 internal queue claim/complete path is proven
- client-side small-model concurrency is proven
- CT203 claim endpoint should be treated as one-at-a-time

## Worker design goals

The minimal worker should:

1. Remain disabled by default.
2. Read the model profile artifact.
3. Use CT203 internal worker API only.
4. Claim one job at a time.
5. Run only allowed job types.
6. Run only allowed model profiles.
7. Run Ollama inside the existing `ollama` Docker container.
8. Apply required profile flags, especially qwen3 `--think=false --hidethinking`.
9. Complete only jobs whose result satisfies the profile validation policy.
10. Fail jobs only when a fail path is explicitly designed and approved.
11. Preserve the ollama-only runtime containment.
12. Never expose model endpoints directly to public users.

## Proposed file layout

Recommended repo additions in a later implementation stage:

```text
ops/workers/ct101_minimal_ollama_worker.py
ops/workers/README-ct101-minimal-ollama-worker.md
ops/systemd/ct101/edge-ct101-ollama-worker.service.example
ops/smoke/check-stage-16-e3z-worker-profile-loader.py
```

This CQ stage does not create these runtime files. It only documents the design.

## Runtime configuration

Recommended CT101 runtime configuration paths:

```text
/etc/edge-ct101-worker/ct101-worker.env
/etc/edge-ct101-worker/model-profiles.yaml
/var/log/edge-ct101-worker/worker.log
```

Environment keys:

```text
EDGE_CT203_API_BASE=http://192.168.0.250:7070
EDGE_CT203_INTERNAL_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env
EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml
EDGE_WORKER_ID=ct101-minimal-ollama-worker
EDGE_CLAIM_POLICY=one_at_a_time
EDGE_MAX_JOBS_PER_LOOP=1
EDGE_WORKER_ENABLED=0
```

The worker must refuse to start if:

- `EDGE_WORKER_ENABLED` is not exactly `1`
- model profile file is missing
- token file is missing
- Docker is not active
- ollama container is not running
- any non-ollama runtime container is unexpectedly running during strict proof mode
- claim policy is not `one_at_a_time`

## Job selection policy

The worker should select eligible jobs by:

1. Fetching or being assigned queued jobs from CT203.
2. Matching job requested_model to a model profile.
3. Checking that the profile is enabled for the current worker run.
4. Checking that the job_type appears in allowed_job_types.
5. Checking that the profile completion_validation_policy is supported.
6. Claiming exactly one eligible job.
7. Refusing if more than one job is returned unexpectedly for a one-at-a-time loop.

The first implementation should not implement broad lane workers. It should be a bounded CT101 Ollama worker only.

## Execution sequence

For each loop:

1. Load configuration.
2. Load and validate model profiles.
3. Confirm runtime containment.
4. Claim exactly one job.
5. Validate claimed job invariants:
   - id is expected
   - status is running
   - attempts incremented exactly once
   - requested_model matches selected profile
   - job_type is allowed
6. Build Ollama command:
   - `docker exec ollama ollama run`
   - append profile cli_flags before model_name
   - append model_name
   - append prompt
7. Run model call with profile timeout.
8. Clean ANSI output.
9. Apply completion validation.
10. Complete only if validation succeeds.
11. Refuse/exit to safe state if validation fails until a fail-job policy exists.

## Qwen3 command contract

For `qwen3_router_small`, the worker must build commands in this order:

```text
docker exec ollama ollama run --think=false --hidethinking qwen3:0.6b <prompt>
```

Do not use:

```text
--think false
```

That syntax makes Ollama treat `false` as a model-name token.

## Concurrency contract

Initial worker version:

- claim one job at a time
- run one model call per claimed job
- no persistent model-call concurrency yet

Later worker version may add model-call concurrency after:

- profile loader is proven
- single-loop worker is proven
- scheduler/timer posture is still inactive
- rollback is proven

The already-proven model concurrency values may guide later defaults:

- qwen2.5:0.5b: max_concurrent_model_calls 2
- qwen3:0.6b: max_concurrent_model_calls 2 with thinking disabled

However, those should not be activated in the first persistent worker implementation.

## Completion validation policy

Supported first validation policy:

```text
exact_marker_only
```

For proof jobs, the expected marker is parsed from the prompt or explicit job metadata when available.

A job should be completed only if:

- model process exits 0
- cleaned response text exactly equals the expected marker
- no error field is set

If the model output is non-exact:

- do not complete
- do not claim another job
- exit safe and require a continuation or explicit fail policy

## Systemd posture

A future service example should be:

- present only as an example first
- not installed by repo-only stages
- not enabled by default
- not started by default
- require explicit approval for install/start/unmask

Suggested service name:

```text
edge-ct101-ollama-worker.service
```

Suggested default status after install-only stage:

```text
disabled
inactive
```

Masking/unmasking must remain explicit.

## Rollback

Rollback for a later apply stage must include:

1. Stop worker service.
2. Disable worker service.
3. Mask worker service if requested.
4. Confirm no worker process remains.
5. Confirm CT203 DB has no unexpected running jobs.
6. Confirm only `ollama` container remains running.
7. Leave Docker/Ollama model data intact.

## Recommended next stages

### CR — CT101 minimal worker implementation plan no-apply

Plan the code and service files, but do not create or install live systemd units.

### CS — repo-only worker profile loader skeleton

Create a profile loader/smoke only, with no runtime calls.

### CT — read-only live readiness validator

Read-only validation of CT203 DB, CT101 runtime, model profile file shape, and service masked/inactive state before any apply.

### CU — explicit apply boundary

Only after CR/CS/CT should we consider an apply phase, and only with explicit approval.

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert new jobs.

Do not call models.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader `/opt/ai-platform` compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior in this stage.

Do not create live systemd units in this stage.

Do not create runtime files under `/etc` or `/var/log` in this stage.
