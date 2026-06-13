# Phase 11W Optional Queue Lane Claim Support

Phase 11W adds optional queue_lane claim support to the laptop-owned queue helper and internal claim endpoint.

## Purpose

Phase 11R added model-lane metadata to queued Companion jobs.

Phase 11T and Phase 11U made lane status visible.

Phase 11V mapped the current worker claim path.

Phase 11W is the first small source patch toward lane-aware scheduling.

## Safety boundary

This phase does not change CT101 worker behavior.

This phase does not restart the controller.

This phase does not change worker concurrency.

This phase does not change LAPTOP_QUEUE_MAX_JOBS_PER_RUN.

This phase does not change OLLAMA_NUM_PARALLEL.

This phase does not change schema.

This phase does not enable router rollout.

## Source changes

Changed source files:

- edge_modules/laptop_queue.py
- edge_controller.py

The helper now accepts:

- worker_id
- job_type
- queue_lane

The internal claim request now accepts:

- worker_id
- job_type
- queue_lane

## Backward compatibility

queue_lane is optional.

If queue_lane is omitted, claim behavior remains the same as before Phase 11W.

That means the current CT101 managed worker can continue claiming jobs exactly as it does today.

## New optional behavior

If queue_lane is provided, the claim query filters queued jobs by:

- payload_json->>'queue_lane'

Example future request shape:

- worker_id: ct101-stage5g21-managed-browser
- job_type: ollama_chat
- queue_lane: model-tiny

## Verification

The Phase 11W smoke verifies:

1. Python syntax still compiles.
2. Phase 11W source markers exist.
3. Runtime/concurrency flags were not changed.
4. A synthetic model-small job can be claimed using queue_lane=model-small.
5. A remaining synthetic model-tiny job can still be claimed when queue_lane is omitted.
6. Synthetic test rows are cleaned up.

## Runtime activation

The controller must be restarted in a later activation phase before the internal HTTP claim endpoint serves this new field.

Phase 11W only proves the source patch and direct helper behavior.

## Next phase

Phase 11X should perform guarded live activation with a controller restart, then test the live internal claim endpoint using synthetic jobs.

