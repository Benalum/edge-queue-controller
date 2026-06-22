# Stage 16 E3Z-CE R2 — CT101 Model Endpoint Proof Summary and Next Concurrency Plan

## Purpose

Record the first CT203-to-CT101 Ollama container model endpoint proof results and define the next safe concurrency path.

This stage is repo-only documentation and smoke.

It does not mutate CT203 DB state, claim jobs, complete jobs, fail jobs, call model generation, start or stop containers, delete Docker or model data, unmask worker services, or activate scheduler or timer paths.

## Latest repo checkpoint entering CE R2

- Previous repo checkpoint: 601ae2f
- Previous tag: controller-stage-16-e3z-bz-ct101-ollama-container-only-model-runtime-and-concurrency-plan-no-apply-2026-06-22

## Runtime state after CD

Stage E3Z-CD classified the current live state:

- CT203 DB integrity: ok
- jobs_total: 37
- job_results_total: 18
- jobs_status_running: 0
- CT101 worker service: inactive and masked
- CT101 Docker and containerd: active
- CT101 running Docker containers: ollama only
- Ollama container: healthy
- Available models:
  - qwen2.5:0.5b
  - gemma3:4b
  - llama3.2:3b
  - qwen3:1.7b
  - qwen3:0.6b
  - gemma4:e4b

## Proof results

### Job 37

- status: completed
- attempts: 1
- requested_model: qwen2.5:0.5b
- response_text: E3Z-MODEL-A-OK
- result_rows: 1
- error: None
- classification: transport success and exact response success

### Job 38

- status: completed
- attempts: 1
- requested_model: qwen2.5:0.5b
- response_text: ENDPOINT-PROOF-E3Z-MODEL-B OK
- expected response: E3Z-MODEL-B-OK
- result_rows: 1
- error: None
- classification: transport success and response adherence failure

## Overall proof classification

The CT203-to-CT101 model transport path is proven:

1. CT203-native worker API can claim exact jobs.
2. CT101 can call the local Ollama Docker container.
3. CT101 can complete jobs back to CT203 SQLite authority.
4. Runtime remained contained with only the ollama container running.
5. The persistent CT101 worker service remained inactive and masked.

Exact model response adherence is not fully proven for qwen2.5:0.5b:

- job 37 matched exactly
- job 38 completed but did not match exactly

Therefore the current classification is:

transport_success_response_adherence_failure

## Important operational lesson

The endpoint proof should not depend on natural-language exactness alone.

For future worker proofs, the worker should separate:

- transport success
- model call success
- response adherence
- grading result

A model response that is not exact should not be silently treated as a transport failure.

## Recommended next jobs

Create fresh jobs instead of reusing jobs 37 and 38.

Recommended fresh deterministic proof jobs:

- one qwen2.5:0.5b exact-marker job with lower temperature or stricter generation options
- one qwen3:0.6b exact-marker comparison job
- optional one gemma3:4b exact-marker comparison job

Recommended fresh concurrency proof jobs:

- two qwen2.5:0.5b jobs run in parallel only after deterministic behavior is understood
- two qwen3:0.6b jobs run in parallel for small-model concurrency
- one gemma4:e4b single-lane job only; do not parallelize gemma4:e4b until memory behavior is measured

## Concurrency direction

Use model tier and concurrency class rather than one global worker pipe.

Initial routing classes:

- router_small:
  - qwen2.5:0.5b
  - qwen3:0.6b
  - qwen3:1.7b
  - target parallelism: 2 to 4 after proof
- study_light:
  - gemma3:4b
  - llama3.2:3b
  - target parallelism: 1 to 2 after proof
- companion_default:
  - gemma4:e4b
  - target parallelism: 1 initially
- deep_large:
  - future larger model
  - target parallelism: 1 only

## Near-term safe sequence

1. CE R2: repo-only summary checkpoint.
2. CF: insert fresh deterministic proof jobs, DB write only.
3. CG: run deterministic one-shot proof for one fresh job using qwen2.5:0.5b with stricter generation handling.
4. CH: run deterministic comparison proof with qwen3:0.6b.
5. CI: no-apply plan for concurrency probe.
6. CJ: run bounded two-job small-model concurrency probe.
7. CK: decide whether to keep Docker and Ollama active, stop it, or mask Docker again before pausing.

## Explicit non-goals

Do not rerun job 37.

Do not rerun job 38.

Do not delete models.

Do not prune Docker.

Do not start broader /opt/ai-platform compose stacks.

Do not start CT101 persistent worker service.

Do not activate scheduler or timer.

Do not expose model endpoints directly to public users.
