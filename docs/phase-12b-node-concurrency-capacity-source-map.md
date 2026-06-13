# Phase 12B Node Concurrency Capacity Source Map

Phase 12B maps the current node concurrency and worker capacity paths before changing any runtime concurrency.

## Purpose

The goal is to prepare for configurable per-node concurrency, especially for the llms / CT101 CPU worker node.

This phase is inspection/documentation only.

## Current controller capacity concepts

The legacy controller workers table already has current_jobs, max_concurrent_jobs, and queue_depth fields.
The legacy worker scoring path blocks a worker when current_jobs is greater than or equal to max_concurrent_jobs.
The legacy worker heartbeat payload accepts current_jobs, max_concurrent_jobs, and queue_depth.

Important legacy controller locations:

- edge_controller.py init_worker_registry_db
- edge_controller.py WorkerHeartbeatRequest
- edge_controller.py worker_row_to_dict
- edge_controller.py score_worker_for_job
- edge_controller.py /workers/heartbeat
- edge_controller.py /workers/registry

## Current laptop-queue capacity concepts

The active laptop-owned queue path uses app_jobs, app_workers, and app_worker_nodes.
The app_workers path currently tracks a single current_job_id.
The laptop queue claim helper marks one job running and sets app_workers.current_job_id.
The laptop queue completion helper clears current_job_id when that job completes.

Important laptop queue locations:

- edge_modules/laptop_queue.py register_worker_node
- edge_modules/laptop_queue.py register_worker
- edge_modules/laptop_queue.py claim_next_job
- edge_modules/laptop_queue.py complete_job
- edge_controller.py /internal/laptop-queue/workers/register
- edge_controller.py /internal/laptop-queue/workers/heartbeat
- edge_controller.py /internal/laptop-queue/jobs/claim

## Current CT101 worker capacity state

CT101 currently runs ai-platform-laptop-queue-worker.service.
The service runs the bounded poller loop.
The worker environment currently has LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1.
The worker environment currently has LAPTOP_QUEUE_JOB_TYPES=ollama_chat.
The worker environment currently has LAPTOP_QUEUE_EXECUTION_MODE=ollama.
The worker environment currently has LAPTOP_QUEUE_POLL_MODE=bounded.
The worker environment currently has no persistent LAPTOP_QUEUE_QUEUE_LANE.

CT101 registration capabilities currently include:

- job_types
- stage
- mode

CT101 registration capabilities do not yet include:

- max_jobs_per_run
- node_max_concurrent_jobs
- queue_lane
- supported_lanes
- lane_capacity
- allowed_models
- model_tiers

## Current lane status visibility

The live controller system status already exposes lane_summary from app_jobs.payload_json.
The lane summary currently reports queued/running/complete/failed counts by model_tier, model_lane, and queue_lane.
The lane summary does not yet report worker/node capacity by lane.

## Recommended capacity contract

A future worker registration capability payload should report:

- max_jobs_per_run
- node_max_concurrent_jobs
- queue_lane
- supported_lanes
- supported_model_tiers
- allowed_models
- lane_capacity
- runtime_backend
- ollama_num_parallel

Example for llms / CT101 while still safe:

- node_max_concurrent_jobs: 1
- max_jobs_per_run: 1
- supported_lanes: model-tiny, model-small
- lane_capacity.model-tiny.max: 1
- lane_capacity.model-small.max: 1
- lane_capacity.model-medium.max: 0
- lane_capacity.model-large.max: 0
- allowed_models: qwen3:0.6b, qwen3:1.7b, llama3.2:3b

Only after scheduler accounting understands this contract should llms be raised above one job at a time.

## Recommended next phase

Add dormant CT101 worker capacity metadata to the registration payload without changing runtime behavior.
The next phase should not restart CT101 worker automatically.
The next phase should keep LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1.
The next phase should keep OLLAMA_NUM_PARALLEL unchanged.

## Runtime changes

None in Phase 12B.

This phase is inspection/documentation only.
