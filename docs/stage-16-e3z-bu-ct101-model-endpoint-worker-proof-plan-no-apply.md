# Stage 16 E3Z-BU — CT101 Model Endpoint Worker Proof Plan No-Apply

## Purpose

Plan the first real model-facing CT101 worker proof using the newly proven CT203-native SQLite worker endpoints.

This stage is no-apply.

It does not insert jobs, claim jobs, complete jobs, start CT101 worker service, start Docker, start Ollama, call a model endpoint, activate scheduler, activate timer, or change runtime configuration.

## Current proven baseline

E3Z-BQ through E3Z-BS proved:

- CT203 native SQLite worker API is enabled with token auth.
- Token-auth summary returns HTTP 200.
- Direct CT203 endpoint claim/complete completed job 35.
- CT101 bounded one-shot endpoint client completed job 36.
- job_results_total reached 16.
- jobs_status_running is 0.
- CT101 ai-platform-laptop-queue-worker.service remains inactive and masked.
- CT101 docker.service remains inactive.
- CT101 ollama.service remains inactive.
- No Docker, Ollama, model call, scheduler, timer, or persistent worker was used.

## Next proof goal

Prove a single CT101-origin one-shot model execution path:

1. CT101 claims exactly one fresh queued job from CT203 using `/internal/edge-worker/jobs/claim`.
2. CT101 calls a local model endpoint in the approved runtime path.
3. CT101 completes the same job through `/internal/edge-worker/jobs/{job_id}/complete`.
4. CT203 DB records one result row with the model response.
5. No persistent worker service is started.

## Required fresh jobs

Do not reuse jobs 35 or 36.

Create fresh proof jobs in a separate approved DB-write stage.

Recommended fresh proof payloads:

- job A prompt: "Stage 16 E3Z model endpoint proof A. Reply exactly: E3Z-MODEL-A-OK"
- requested_model: qwen2.5:0.5b
- job_type: stage16_e3z_ct101_model_endpoint_worker_proof
- status: queued
- attempts: 0

Optional second job:

- job B prompt: "Stage 16 E3Z model endpoint proof B. Reply exactly: E3Z-MODEL-B-OK"
- requested_model: qwen2.5:0.5b
- job_type: stage16_e3z_ct101_model_endpoint_worker_proof
- status: queued
- attempts: 0

## Docker/Ollama boundary

CT101 currently has Docker inactive and Ollama systemd inactive.

Earlier inventory found Docker service/container activation is risky because existing containers may have restart policies.

Therefore the next runtime proof must not blindly start Docker.

Before any model call:

1. Inspect exact Ollama Docker/compose source path.
2. Decide whether the approved model runtime is:
   - a specifically named existing Ollama container,
   - a compose service under /opt/llm-stack,
   - or a new isolated one-shot container.
3. Prevent unrelated containers from starting.
4. Start only the minimum approved Ollama runtime.
5. Verify local model endpoint health without running broad model prompts.
6. Only then run a single exact proof prompt.

## CT101 worker service boundary

Do not unmask, enable, or start ai-platform-laptop-queue-worker.service for the first model proof.

Use a bounded one-shot script inside CT101, similar to BS, but with a model-call step between claim and complete.

The one-shot script must:

- load token without printing it
- call CT203 at http://192.168.0.250:7070
- claim only the exact fresh job ID
- refuse retired proof job IDs
- call only the approved local model endpoint
- complete only the claimed job
- fail closed if claim or model response is unexpected
- remove temporary script files after execution

## Safety invariants for the model proof

Before proof:

- CT203 DB integrity ok
- jobs_status_running 0
- fresh proof job queued attempts 0 result_rows 0
- CT101 worker service inactive/masked
- scheduler/timer inactive
- Docker/Ollama activation scope explicitly approved

During proof:

- only one job may become running
- only the claimed job may complete
- no persistent service may be started

After proof:

- fresh proof job completed attempts 1 result_rows 1
- response_text matches exact expected marker
- no running jobs remain
- CT101 worker service remains inactive/masked
- unrelated Docker containers remain untouched
- scheduler/timer remain inactive

## API enablement posture

The CT203-native worker API is currently enabled.

Recommendation:

- Keep it enabled only while actively continuing the next proof.
- If pausing for a long interval, roll it back disabled with a controller-only restart.
- Do not leave queued proof jobs pending if pausing.

## Approval boundaries ahead

Separate approvals are required for:

1. fresh proof job insertion
2. any Docker/Ollama runtime start
3. any model endpoint call
4. CT101 one-shot claim/model/complete proof
5. rollback disabling the CT203-native worker API if pausing
