# Phase 11V Lane-Aware Worker Claim Source Map

Phase 11V maps the current worker claim path before adding lane-aware scheduling.

## Purpose

The platform now has model-lane metadata and live lane visibility:

- Phase 11R writes model-lane metadata into queued Companion jobs.
- Phase 11S proved that live queued jobs contain the metadata.
- Phase 11T exposes lane summaries in queue/status data.
- Phase 11U proved live system status shows lane_summary.

Phase 11V is documentation/source-map only. It does not change worker claim behavior.

## Current laptop queue claim path

Main source: edge_modules/laptop_queue.py
Main helper: LaptopQueueClient.claim_next_job(worker_id, job_type=None)

Current behavior:

1. Selects the oldest queued job.
2. Optionally filters by job_type.
3. Orders by created_at, id.
4. Uses LIMIT 1.
5. Uses FOR UPDATE SKIP LOCKED.
6. Updates the selected job to running.
7. Sets assigned_worker_id.
8. Sets the worker row to busy and stores current_job_id.

Current claim query does not filter by model_tier, model_lane, queue_lane, requested_model, worker lane capacity, or worker model availability.

## Current internal claim endpoint

Main source: edge_controller.py
Endpoint: POST /internal/laptop-queue/jobs/claim
Request model: _S5E4ClaimRequest

Current request fields: worker_id and job_type.

There is no queue lane, model lane, model tier, or capacity field yet.

## Current worker registry shape

Current app_workers fields include id, name, status, capabilities_json, current_job_id, worker_node_id, last_heartbeat_at, idle_shutdown_seconds, and timestamps.

Current app_worker_nodes fields include id, name, node_type, host_machine, enabled, status, capabilities, last_seen_at, and timestamps.

Lane capacity is not yet represented in DB columns. Future phases should avoid schema migration at first by using existing JSON fields.

## Current CT101 managed worker runtime

Current CT101 service: ai-platform-laptop-queue-worker.service.
Current service command: /opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh.
The service is persistent and repeatedly calls the bounded poller.

Current CT101 worker env includes:

- LAPTOP_QUEUE_SYNTHETIC_ONLY=0
- LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1
- LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1
- LAPTOP_QUEUE_OLLAMA_BASE_URL=http://100.88.245.33:11434
- LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK=gemma4:e4b

Current safety state: one job per bounded poller run, no parallel worker claim, no lane-aware worker selection, and no Ollama parallelism change.

## Current queue lane visibility

Live queue/status visibility now shows lane summaries from app_jobs.payload_json.

Observed lane row: status complete, model_tier tiny, model_lane model-tiny, queue_lane model-tiny, requested_model qwen3:0.6b.

Older gemma4:e4b jobs have no lane metadata and appear as none.

## Recommended next implementation path

1. Add optional lane fields to the internal claim request model.
2. Keep defaults backward-compatible when no lane is requested.
3. Add claim helper support for optional queue_lane filtering.
4. Add a smoke-only synthetic lane claim test.
5. Add worker heartbeat capability metadata using existing capabilities_json.
6. Add lane-aware claim in dry-run or single-lane mode.
7. Only later raise worker or Ollama parallelism.

## Proposed safe claim API extension

Future request shape should add queue_lane as an optional field alongside worker_id and job_type.

Backward compatibility rule: If queue_lane is missing, claim behavior remains exactly the same as today.

## Runtime changes

None in Phase 11V.

This phase is source-map documentation only.
