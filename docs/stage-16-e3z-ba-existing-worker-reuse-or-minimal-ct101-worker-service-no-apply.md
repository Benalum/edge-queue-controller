# Stage 16 E3Z-BA — Existing worker reuse vs minimal CT101 worker service (no apply)

## Purpose

This phase decides the queue-worker integration direction after AZ repo archaeology showed substantial existing queue, worker, lane, scheduler, and model-forwarding code already exists.

## What AZ showed

`edge_controller.py` already contains these relevant integration surfaces:

- job creation and listing routes
- queue summary
- worker registry initialization
- worker heartbeat
- worker registry view
- scheduler preview
- target worker start planning symbols
- lane worker metadata and eligibility filtering
- internal queue token/client helpers
- laptop queue claim and complete routes
- worker register and heartbeat routes
- queue recovery route
- Ollama direct forwarding helpers
- public job result storage and retrieval

## Decision

The preferred design is existing-worker reuse first.

CT101 should run a small worker process that talks to CT203 using existing queue-worker contracts. The worker should not own the queue, should not write directly to the CT203 DB, and should not bypass CT203 job lifecycle rules.

## Proposed CT101 worker shape

A minimal CT101 worker service should:

1. register or heartbeat to CT203 as a model worker
2. advertise lane and capability metadata
3. request/claim only eligible jobs from CT203
4. execute the local model adapter inside CT101
5. complete or fail the job through CT203 APIs
6. emit enough status for CT203 to mark worker available or unavailable

## Existing code to reuse first

Review and reuse these repo areas before writing new code:

- `_s5e4_queue_client`
- `s5e4_laptop_queue_claim_job`
- `s5e4_laptop_queue_complete_job`
- `s5e15_laptop_queue_worker_register`
- `s5e15_laptop_queue_worker_heartbeat`
- `_phase14j_worker_eligible_for_job`
- `_phase14j_filter_workers_for_lane`
- `_forward_ollama_chat_job_direct`
- `tick_ollama_direct`
- `_public_store_job_result`

## Blockers before runtime execution

- Docker runtime is masked and inactive.
- Ten existing Docker containers have restart policy `unless-stopped` and could auto-start if Docker is started without mitigation.
- The local Ollama Docker container identity and compose source must be identified before any model execution proof.
- Jobs 35 and 36 remain reserved queued proof jobs and must not be mutated until a separately approved worker proof.

## Next no-apply phase

Create BB as a source map and interface design for the CT101 worker service using existing CT203 queue contracts. BB should identify exact endpoints, request/response payloads, environment variables, auth token handling, lane metadata, and whether the old laptop queue worker can be adapted for CT101.

## Guardrails

- Do not call `/api/generate`.
- Do not call any Ollama model endpoint.
- Do not start Docker, containerd, Docker socket, Docker containers, or docker compose.
- Do not mutate DB rows, jobs, job results, scheduler state, or timer state.
- Do not reuse job 34.
