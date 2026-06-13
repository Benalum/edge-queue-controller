# Phase 11Q Companion Multi-Model Concurrency Source Map

Phase 11Q inspected the current Companion, queue, worker, and Ollama paths before adding the decision-maker and multi-model concurrency system.

## Goal

Add a safe architecture where different users can use different model lanes at the same time.

Target behavior:

- tiny model can run 3-4 jobs at a time
- small model can run 2 jobs at a time
- medium model can run 1-2 jobs at a time
- large model can run 1 job at a time

## Current source map

Important controller locations:

- edge_controller.py
  - jobs table near CREATE TABLE IF NOT EXISTS jobs
  - job creation through create_job, _public_create_ollama_job, and /api/chat/queued
  - worker registry through init_worker_registry_db, /workers/heartbeat, and /workers/registry
  - worker selection through estimate_job_requirements, score_worker_for_job, and select_best_worker_for_job
  - direct Ollama forwarding through _forward_ollama_chat_job_direct and /tick/ollama-direct
  - Study decision hints through _study_parse_deterministic_intent
  - Companion endpoints through /api/companion/chat and /api/chat/queued

Important frontend locations:

- frontend/wrapper-ui/app.js
  - queued Companion submit flow uses /api/chat/queued
  - Study command routing
  - Study answer routing
  - queued status polling

Important CT101 / worker runtime locations:

- /opt/ai-platform/docker-compose.yml
  - ai-platform-api
  - ai-platform-worker
  - OLLAMA_BASE_URL=http://ollama:11434
  - WORKER_NODE_NAME=llms-worker-1

- /opt/ai-platform/.env
  - DEFAULT_MODEL=gemma4:e4b
  - COMPANION_DEFAULT_MODEL=gemma4:e4b
  - OLLAMA_NUM_CTX=2048
  - OLLAMA_NUM_PREDICT=900
  - WORKER_POLL_SECONDS=5
  - WORKER_HEALTH_REPORT_SECONDS=15

- /opt/llm-stack/docker-compose.yml
  - OLLAMA_HOST=0.0.0.0:11434
  - OLLAMA_NUM_PARALLEL=1
  - OLLAMA_MAX_TRANSFER_STREAMS=1
  - OLLAMA_KEEP_ALIVE=30m

## Current capabilities

The controller already has a worker concurrency foundation:

- workers report current_jobs
- workers report max_concurrent_jobs
- workers report queue_depth
- registry computes available, busy, stale, unhealthy, disabled, and offline

The Study deterministic parser already returns routing hints:

- model_tier
- queue_lane

## Current gaps

The system does not yet have a true lane-aware model scheduler.

Missing pieces:

- jobs table does not store model_tier
- jobs table does not store queue_lane
- jobs table does not store model_lane
- scheduler does not calculate per-lane capacity
- worker does not advertise lane capacity
- worker does not reserve capacity per model tier
- Ollama is currently configured for one parallel request globally
- all default Companion traffic points to gemma4:e4b

## Recommended target architecture

### Decision maker

Each user input should be classified before model execution.

Example decision shape:

- intent: study_answer_attempt
- confidence: high
- requires_model: false
- model_tier: tiny
- queue_lane: study-tiny
- requested_model: qwen3:0.6b
- fallback_model_tier: small
- fallback_requested_model: qwen3:1.7b

### Model lane registry

Suggested first config:

- tiny
  - default_model: qwen3:0.6b
  - max_parallel: 4
  - queue_lane: model-tiny

- small
  - default_model: qwen3:1.7b
  - max_parallel: 2
  - queue_lane: model-small

- medium
  - default_model: gemma3:4b
  - max_parallel: 1
  - queue_lane: model-medium

- large
  - default_model: gemma4:e4b
  - max_parallel: 1
  - queue_lane: model-large

### Scheduler behavior

The scheduler should only dispatch a job when its lane has capacity.

Example behavior:

- 4 tiny jobs can run together
- 2 small jobs can run together
- 1 large job can run
- a large job must not block tiny Study answer checks

### Worker behavior

The worker should report lane capacity in heartbeats.

Example lane capacity shape:

- worker_id: llms-worker-1
- current_jobs: 3
- max_concurrent_jobs: 6
- tiny running/max: 2/4
- small running/max: 1/2
- medium running/max: 0/1
- large running/max: 0/1

## Implementation recommendation

Proceed in small safe phases:

1. add model lane config/contract without changing runtime behavior
2. add job metadata columns for model_tier, queue_lane, and routing_decision_json
3. add decision-maker output to queued chat creation
4. add lane-aware scheduler dry-run
5. add worker heartbeat lane capacity
6. enable worker lane dispatch gradually
7. tune Ollama parallelism after lane accounting exists

## Runtime changes

None in Phase 11Q.

This phase is inspection/documentation only.
