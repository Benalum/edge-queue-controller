# Phase 12D Registered Worker Capacity Status

Phase 12D exposes public-safe registered CT101 worker capacity metadata in `/system/status`.

## Result

The controller now includes `registered_capacity` on the `ct101-laptop-queue-worker` service object.

## Source change

- `edge_controller.py`
- Marker: `STAGE_5P12D_REGISTERED_WORKER_CAPACITY_STATUS`

## Live status proof

`/system/status` now exposes:

- `registered_capacity.worker_id`
- `registered_capacity.worker_node_id`
- `registered_capacity.worker`
- `registered_capacity.node`
- `registered_capacity.capabilities`

The safe capability subset includes:

- `job_types`
- `stage`
- `mode`
- `max_jobs_per_run`
- `node_max_concurrent_jobs`
- `queue_lane`
- `supported_lanes`
- `supported_model_tiers`
- `allowed_models`
- `lane_capacity`
- `runtime_backend`
- `ollama_num_parallel`

## Verified live values

For worker `ct101-stage5g21-managed-browser`:

- `max_jobs_per_run`: 1
- `node_max_concurrent_jobs`: 1
- `allowed_models`: `gemma4:e4b`
- `lane_capacity`: empty object
- `runtime_backend`: `ollama`
- `queue_lane`: null
- `supported_lanes`: empty list
- `supported_model_tiers`: empty list

## Safety state

No queue-lane routing was enabled.
No CT101 concurrency was raised.
`LAPTOP_QUEUE_MAX_JOBS_PER_RUN` remains pinned to 1.
Future capacity env keys remain unset.
CT101 worker service remains active.
Router rollout remains parked.
