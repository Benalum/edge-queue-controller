# Phase 11Y CT101 Worker-Side Lane Claim Source Map

Phase 11Y maps the CT101 worker-side claim path before making the worker send queue_lane.

## Purpose

Phase 11W added optional queue_lane support to the laptop controller claim helper and internal claim endpoint.
Phase 11X proved the live controller endpoint accepts queue_lane and remains backward compatible when queue_lane is omitted.

Phase 11Y is documentation/source-map only.

## CT101 current worker service

Observed CT101 service: ai-platform-laptop-queue-worker.service.
The service is active and runs /opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh.
The loop repeatedly runs python3 ops/smoke/laptop_queue_bounded_synthetic_poller.py.

## CT101 current claim client

Observed client file: /opt/ai-platform/backend/app/worker/laptop_queue_client.py.
Observed method: claim_one(self, job_type="ollama_chat").

Current claim payload sends:

- worker_id
- job_type

Current claim payload does not send queue_lane.

## CT101 current bounded poller

Observed poller file: /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py.
The bounded poller calls client.claim_one(job_type=job_types[0]).
The bounded poller does not pass queue_lane.

## Safety state

CT101 worker-side behavior is unchanged.
CT101 does not send queue_lane yet.
CT101 still uses LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1 through preflight.
CT101 does not raise Ollama parallelism.
CT101 does not change schema.
Router rollout remains parked.

## Recommended next implementation

Next phase should add dormant worker-side queue_lane support to the CT101 client and bounded poller.
Recommended dormant behavior:

- add optional queue_lane parameter to LaptopQueueClient.claim_one
- only include queue_lane in the POST payload when explicitly provided
- read optional LAPTOP_QUEUE_QUEUE_LANE from env in the bounded poller
- keep LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1
- do not restart CT101 worker until a separate activation phase
- do not raise OLLAMA_NUM_PARALLEL

## Runtime changes

None in Phase 11Y.

This phase is inspection/documentation only.
