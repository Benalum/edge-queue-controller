# Stage 16 E3Z-CR — CT101 Worker Implementation Plan — No Apply

## Purpose

Plan the repository implementation for a default-off CT101 Ollama worker without creating runtime services or changing live infrastructure.

This is a repository-only no-apply stage.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, create live systemd units, enable timers, or activate scheduler paths.

## Prior checkpoints

- E3Z-CM proved small-model client-side concurrency.
- E3Z-CN defined the worker claim and model profile contract.
- E3Z-CP created the model profile artifact:
  - `ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml`
- E3Z-CQ designed a default-off CT101 minimal worker.

Current checkpoint entering CR:

- repo: a9836ea
- tag: controller-stage-16-e3z-cq-ct101-minimal-worker-design-no-apply-2026-06-22
- status: clean

## Proposed repo files for implementation

A later repo-only implementation stage should add:

```text
ops/workers/ct101_minimal_ollama_worker.py
ops/workers/README-ct101-minimal-ollama-worker.md
ops/systemd/ct101/edge-ct101-ollama-worker.service.example
ops/smoke/check-stage-16-e3z-cs-ct101-worker-skeleton-repo-only.sh
```

The implementation should remain repository-only until a separate explicit apply boundary.

## Worker module responsibilities

The worker module should be divided into small functions:

```text
load_env()
load_token()
load_model_profiles()
validate_model_profiles()
runtime_preflight()
get_eligible_profile_for_job()
claim_one_job()
build_ollama_command()
run_ollama_call()
clean_model_output()
validate_completion()
complete_job()
main_once()
main_loop()
```

## Strict initial runtime mode

The first worker implementation must support a strict mode:

```text
EDGE_WORKER_ENABLED=0 by default
EDGE_STRICT_RUNTIME_CONTAINMENT=1
EDGE_CLAIM_POLICY=one_at_a_time
EDGE_MAX_JOBS_PER_LOOP=1
EDGE_ALLOW_MODEL_CONCURRENCY=0
EDGE_ALLOWED_CONTAINER_NAMES=ollama
```

The worker must refuse to run unless explicitly enabled.

## Configuration source order

The worker should resolve configuration in this order:

1. environment variables
2. environment file values
3. static safe defaults

It must not print secrets.

Recommended environment keys:

```text
EDGE_WORKER_ENABLED
EDGE_WORKER_ID
EDGE_CT203_API_BASE
EDGE_CT203_INTERNAL_QUEUE_TOKEN_FILE
EDGE_MODEL_PROFILE_FILE
EDGE_CLAIM_POLICY
EDGE_MAX_JOBS_PER_LOOP
EDGE_STRICT_RUNTIME_CONTAINMENT
EDGE_ALLOW_MODEL_CONCURRENCY
EDGE_ALLOWED_CONTAINER_NAMES
```

## Model profile loading

The worker should load:

```text
ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
```

during repo smoke, and later:

```text
/etc/edge-ct101-worker/model-profiles.yaml
```

during live runtime.

Validation must enforce:

- schema_version is 1
- artifact is disabled by default
- profile IDs are unique
- all profiles are disabled by default until explicit activation
- all profiles use claim_policy one_at_a_time
- qwen3_router_small has `--think=false` and `--hidethinking`
- unproven profiles have max_concurrent_model_calls 1
- enabled profiles cannot use `no_default_until_proven`

## CT203 worker API calls

The first implementation should use the existing native worker API:

```text
POST /internal/edge-worker/jobs/claim
POST /internal/edge-worker/jobs/{job_id}/complete
```

Claim request:

```json
{
  "worker_id": "ct101-minimal-ollama-worker",
  "claim_job_ids": [123],
  "max_jobs": 1
}
```

The worker must reject responses that contain:

- zero claimed jobs when a specific job was expected
- more than one claimed job in one_at_a_time mode
- a claimed job ID different from the requested ID
- a claimed job whose requested_model does not match the selected profile
- a claimed job whose job_type is not in allowed_job_types
- a claimed job whose attempts value is not expected

## Ollama command construction

For qwen2.5:

```text
docker exec ollama ollama run qwen2.5:0.5b <prompt>
```

For qwen3:

```text
docker exec ollama ollama run --think=false --hidethinking qwen3:0.6b <prompt>
```

The worker must never build this incorrect qwen3 form:

```text
docker exec ollama ollama run --think false --hidethinking qwen3:0.6b <prompt>
```

because Ollama treats `false` as a model-name token.

## Output validation

The initial implementation supports only:

```text
exact_marker_only
```

For exact-marker proof jobs:

- extract expected marker from job metadata when available
- otherwise parse from prompt using a strict marker regex
- clean ANSI/control output
- strip surrounding whitespace
- compare exact string
- complete only on exact match

If output is non-exact:

- do not complete
- do not fail unless fail policy is explicitly approved
- exit with a refusal marker
- leave the claimed job for continuation handling

## Failure and continuation behavior

If the worker exits after claim but before completion:

1. Do not re-claim the same job.
2. Run a read-only validator.
3. Complete exact known output only if already safely captured.
4. Otherwise use a separately approved fail path.

The implementation must make continuation markers clear.

Recommended refusal markers:

```text
REFUSE_WORKER_DISABLED
REFUSE_PROFILE_INVALID
REFUSE_RUNTIME_CONTAINMENT
REFUSE_CLAIM_INVARIANT
REFUSE_MODEL_OUTPUT_NOT_EXACT
REFUSE_COMPLETE_HTTP_NOT_200
```

## Service example design

The example service file should not be installed by repo-only stages.

Suggested example path:

```text
ops/systemd/ct101/edge-ct101-ollama-worker.service.example
```

Suggested service properties:

```text
Type=simple
User=root
EnvironmentFile=/etc/edge-ct101-worker/ct101-worker.env
ExecStart=/usr/bin/python3 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py --loop
Restart=no
```

Default posture:

- example only
- not installed
- not enabled
- not started
- no apply side effects

## Smoke test design

Repo-only smoke should verify:

1. Python syntax compiles.
2. model profile YAML parses.
3. qwen3 command builder puts flags before model name.
4. qwen3 command builder does not produce `--think false`.
5. exact marker cleaner removes ANSI noise.
6. disabled-by-default config refuses runtime.
7. one_at_a_time claim invariant is enforced in parser tests.
8. service file is example only.
9. no live CT203, CT101, Docker, Ollama, systemd, scheduler, or timer calls are made.

## Recommended next stages

### CS — repo-only worker skeleton and smoke

Create the Python worker skeleton, README, service example, and repo-only smoke tests.

No runtime install.

No model calls.

No DB calls.

### CT — read-only live readiness validator

Verify live CT203/CT101 state before any apply boundary:

- CT203 DB integrity
- jobs 37 through 44 completed
- no running jobs
- CT101 worker inactive/masked
- only `ollama` container running
- profile artifact present in repo
- no scheduler/timer activation

### CU — explicit install-only plan no-apply

Plan copying files to CT101 and CT203 paths without starting services.

### CV — explicit apply boundary

Only after CS/CT/CU should an apply stage be considered.

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert new jobs.

Do not call models.

Do not connect to live CT203 API.

Do not connect to live CT101.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader `/opt/ai-platform` compose stacks.

Do not expose model endpoints directly to public users.

Do not create live systemd units in this stage.

Do not create runtime files under `/etc` or `/var/log` in this stage.

Do not change CT203 claim endpoint behavior in this stage.
