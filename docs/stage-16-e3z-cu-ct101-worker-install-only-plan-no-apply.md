# Stage 16 E3Z-CU — CT101 Worker Install-Only Plan — No Apply

## Purpose

Plan a future install-only step for the CT101 minimal Ollama worker without copying files, creating live runtime directories, installing services, starting services, unmasking services, enabling scheduler/timer paths, or calling models.

This is a repository-only no-apply planning stage.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, connect to live CT203, connect to live CT101, start or stop containers, delete Docker or model data, unmask worker services, create live systemd units, enable timers, or activate scheduler paths.

## Prior checkpoint

Stage 16 E3Z-CT confirmed live readiness:

- repo: c9db127
- tag: controller-stage-16-e3z-ct-live-readiness-validator-read-only-2026-06-22
- CT203 DB integrity: ok
- jobs_total: 43
- job_results_total: 24
- jobs_status_running: 0
- jobs 37 through 44 completed attempts=1 result_rows=1
- CT101 worker service inactive and masked
- Docker, docker.socket, and containerd active
- only healthy `ollama` container running
- qwen2.5:0.5b and qwen3:0.6b present

## Repo artifacts already available

The install-only step would use these repo artifacts:

```text
ops/workers/ct101_minimal_ollama_worker.py
ops/workers/README-ct101-minimal-ollama-worker.md
ops/model-profiles/ct101-ollama-model-profiles.stage16-e3z.yaml
ops/systemd/ct101/edge-ct101-ollama-worker.service.example
```

## Future install-only objective

A future install-only apply stage should stage files on CT101 while preserving disabled/inactive posture.

Install-only means:

- copy worker Python file
- copy model profile YAML
- copy environment template or create a disabled env file
- optionally copy the service unit file
- run syntax/profile validation
- do not start worker
- do not enable worker
- do not unmask worker unless explicitly approved
- do not call models
- do not claim jobs
- do not activate scheduler/timer

## Proposed CT101 live paths

Future CT101 target paths:

```text
/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
/etc/edge-ct101-worker/model-profiles.yaml
/etc/edge-ct101-worker/ct101-worker.env
/etc/systemd/system/edge-ct101-ollama-worker.service
/var/log/edge-ct101-worker/
```

## Proposed disabled environment file

The future install-only step should create or preserve:

```text
/etc/edge-ct101-worker/ct101-worker.env
```

with disabled defaults:

```text
EDGE_WORKER_ENABLED=0
EDGE_WORKER_ID=ct101-minimal-ollama-worker
EDGE_CT203_API_BASE=http://192.168.0.250:7070
EDGE_CT203_INTERNAL_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env
EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml
EDGE_CLAIM_POLICY=one_at_a_time
EDGE_MAX_JOBS_PER_LOOP=1
EDGE_STRICT_RUNTIME_CONTAINMENT=1
EDGE_ALLOW_MODEL_CONCURRENCY=0
EDGE_ALLOWED_CONTAINER_NAMES=ollama
```

The install-only step must not print token contents.

## Proposed install-only sequence

A future explicit apply stage should perform:

1. Verify CT101 is running.
2. Verify CT101 worker service is inactive and masked before any changes.
3. Verify only the `ollama` Docker container is running.
4. Create `/opt/edge-queue-controller/ops/workers` if missing.
5. Create `/etc/edge-ct101-worker` with root-owned permissions.
6. Create `/var/log/edge-ct101-worker` with root-owned permissions.
7. Copy `ct101_minimal_ollama_worker.py`.
8. Copy `ct101-ollama-model-profiles.stage16-e3z.yaml` as `/etc/edge-ct101-worker/model-profiles.yaml`.
9. Write disabled `/etc/edge-ct101-worker/ct101-worker.env`.
10. Copy service example to `/etc/systemd/system/edge-ct101-ollama-worker.service`.
11. Run `systemd-analyze verify` if available.
12. Run worker `--self-test` against `/etc/edge-ct101-worker/model-profiles.yaml`.
13. Run `systemctl daemon-reload` if and only if a unit is copied.
14. Confirm service remains inactive.
15. Confirm service remains disabled or masked, according to the chosen approval.
16. Confirm no DB changes.
17. Confirm no model calls.
18. Confirm only `ollama` container remains running.

## Masking decision

Recommended conservative posture:

- If old `ai-platform-laptop-queue-worker.service` remains masked, keep it masked.
- Install new `edge-ct101-ollama-worker.service` as disabled and inactive.
- Do not start it.
- Do not enable it.
- Do not activate it through timers or scheduler.
- Consider masking the new service after install if the operator wants an even stronger default-off state.

## Guard conditions for install-only apply

The future apply script must refuse unless:

- repo HEAD/origin matches expected checkpoint
- CT203 DB integrity is ok
- jobs 37 through 44 remain completed
- jobs_status_running is 0
- CT101 worker service remains inactive/masked before install
- Docker/containerd are active
- only `ollama` container is running
- qwen2.5:0.5b and qwen3:0.6b remain present
- model profile artifact validates in repo before copy
- worker skeleton self-test passes before copy

## Explicit approval required for future apply

The future install-only apply phase must require an explicit phrase.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_CV_INSTALL_CT101_WORKER_FILES_DISABLED_ONLY_NO_START
```

Allowed future apply scope should be limited to:

- copy worker/profile/env/service files to CT101
- daemon-reload if service copied
- self-test only
- leave service inactive
- leave worker disabled in env
- no model calls
- no DB mutation
- no scheduler/timer activation

## Future activation boundary

A later activation phase must be separate from install-only.

Activation would require a different explicit approval phrase and must not be bundled with install.

Activation would include:

- unmask if needed
- set `EDGE_WORKER_ENABLED=1`
- start service for a bounded one-shot or single loop
- claim one approved fresh job
- complete one approved fresh job
- stop service
- restore disabled posture if required

## Rollback plan for install-only

Rollback for install-only should be simple:

1. Stop service if somehow active.
2. Disable service.
3. Mask service if requested.
4. Remove or leave installed files according to approval.
5. Remove daemon state only through `systemctl daemon-reload`.
6. Confirm no worker process remains.
7. Confirm CT203 jobs_status_running is 0.
8. Confirm only `ollama` container remains running.
9. Do not delete Docker/Ollama model data.

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert new jobs.

Do not call models.

Do not connect to live CT203 API in this repo-only plan.

Do not connect to live CT101 in this repo-only plan.

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
