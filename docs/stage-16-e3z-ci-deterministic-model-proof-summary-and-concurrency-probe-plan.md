# Stage 16 E3Z-CI — Deterministic Model Proof Summary and Concurrency Probe Plan

## Purpose

Record the deterministic CT203-to-CT101 Ollama container model proof results and define the next bounded concurrency probe.

This stage is repo-only documentation and smoke.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start or stop containers, delete Docker or model data, unmask worker services, or activate scheduler or timer paths.

## Current repo checkpoint entering CI

- Previous repo checkpoint: e117a39
- Previous tag: controller-stage-16-e3z-ce-r2-ct101-model-endpoint-proof-summary-and-next-concurrency-plan-2026-06-22

## Current live proof state

CT203 DB after CH R4:

- DB integrity: ok
- jobs_total: 39
- job_results_total: 20
- jobs_status_running: 0

Known completed proof jobs:

- job 37:
  - model: qwen2.5:0.5b
  - response: E3Z-MODEL-A-OK
  - result: exact success
- job 38:
  - model: qwen2.5:0.5b
  - response: ENDPOINT-PROOF-E3Z-MODEL-B OK
  - result: transport success but response adherence failure
- job 39:
  - model: qwen2.5:0.5b
  - response: E3Z-DET-QWEN25-OK
  - result: deterministic exact success
- job 40:
  - model: qwen3:0.6b
  - response: E3Z-DET-QWEN3-OK
  - result: deterministic exact success with thinking disabled

CT101 runtime after CH R4:

- CT101 worker service: inactive and masked
- Docker and containerd: active
- Running Docker containers: ollama only
- No scheduler or persistent worker activation

## Key technical lessons

### Transport proof

The CT203 native worker API path is proven:

1. CT101 can claim a CT203 SQLite job.
2. CT101 can run an Ollama model inside the local Docker container.
3. CT101 can complete the job back to CT203.
4. CT203 DB state remains internally consistent.
5. Runtime containment can be preserved with only the ollama Docker container running.

### Deterministic qwen2.5 proof

The qwen2.5:0.5b model can return an exact marker when prompted with stricter endpoint wording.

Job 39 proved:

- exact response: E3Z-DET-QWEN25-OK
- completion path: success
- model call elapsed time: about 0.586 seconds

### Deterministic qwen3 proof

The qwen3:0.6b model has a thinking capability and does not behave as a simple exact-marker endpoint by default.

Observed behavior:

- default qwen3 attempt emitted thinking text and a non-exact response
- corrected syntax --think=false --hidethinking made exact marker output work
- incorrect syntax --think false caused Ollama to treat false as the model-name token

Job 40 proved:

- exact response: E3Z-DET-QWEN3-OK
- completion path: success
- model call elapsed time: about 0.53 seconds
- required flags: --think=false --hidethinking

## Concurrency probe design

The next step should be a bounded small-model concurrency probe.

The first concurrency probe should not use gemma4:e4b.

Use small models only:

- qwen2.5:0.5b
- qwen3:0.6b with --think=false --hidethinking

Recommended first concurrent batch:

- two fresh qwen2.5:0.5b jobs
- two fresh qwen3:0.6b jobs

Run policy:

- insert fresh jobs first in a DB-only phase
- run a bounded two-job concurrency proof first
- complete only exact-marker successes
- refuse before claim when using pre-claim generation guard
- do not activate the persistent worker service
- do not activate scheduler or timer paths
- do not start broad /opt/ai-platform compose stacks
- keep runtime contained to the ollama Docker container only

## Proposed next phases

### CJ — insert fresh concurrency proof jobs only

Allowed:

- insert fresh CT203 SQLite jobs for bounded concurrency proof
- no model calls
- no claim or complete
- no Docker changes

Recommended jobs:

- job 41: qwen2.5:0.5b, marker E3Z-CON-QWEN25-A-OK
- job 42: qwen2.5:0.5b, marker E3Z-CON-QWEN25-B-OK
- job 43: qwen3:0.6b, marker E3Z-CON-QWEN3-A-OK
- job 44: qwen3:0.6b, marker E3Z-CON-QWEN3-B-OK

### CK — bounded qwen2.5 two-job concurrency proof

Allowed only with explicit approval:

- run two qwen2.5:0.5b model calls concurrently
- claim and complete exact jobs only after exact outputs
- verify both jobs completed attempts=1 result_rows=1
- verify runtime remains ollama-only

### CL — bounded qwen3 two-job concurrency proof

Allowed only with explicit approval:

- run two qwen3:0.6b model calls concurrently
- use --think=false --hidethinking
- claim and complete exact jobs only after exact outputs
- verify both jobs completed attempts=1 result_rows=1
- verify runtime remains ollama-only

### CM — repo-only concurrency results summary

Record concurrency outcomes and decide next routing and concurrency defaults.

## Initial routing recommendation

Use a model profile table or configuration object with explicit model execution options:

- qwen2.5:0.5b:
  - role: router_small
  - thinking flags: none
  - initial parallelism: 2
- qwen3:0.6b:
  - role: router_small
  - required flags: --think=false --hidethinking
  - initial parallelism: 2
- qwen3:1.7b:
  - role: router_small or study_light candidate
  - required thinking behavior: needs proof
  - initial parallelism: 1 until measured
- gemma3:4b:
  - role: study_light candidate
  - initial parallelism: 1
- gemma4:e4b:
  - role: companion_default candidate
  - initial parallelism: 1 only

## Explicit non-goals

Do not rerun jobs 37, 38, 39, or 40.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.
