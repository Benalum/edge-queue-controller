# Phase 12F Read-Only Lane Dispatch Readiness

Phase 12F exposes a read-only lane dispatch readiness plan in `/system/status`.

## Result

The `ct101-laptop-queue-worker` service object now includes:

- `lane_dispatch_readiness`

This object compares registered worker lane/model metadata with observed job lane metadata.

## Safety state

This phase is status-only.

- `dry_run_only`: true
- `runtime_enabled`: false
- `dispatch_enabled`: false
- `claim_filter_enabled`: false
- `active_queue_lane`: null

No queue-lane claim was enabled.
No worker runtime capacity was raised.
No Ollama parallelism was enabled.
CT101 worker remains active.
Router rollout remains parked.

## Live readiness values

The worker advertises:

- `supported_lanes`: `model-tiny`, `model-small`
- `supported_model_tiers`: `tiny`, `small`
- `allowed_models`: `qwen3:0.6b`, `qwen3:1.7b`, `llama3.2:3b`
- `lane_capacity.model-tiny.max`: 1
- `lane_capacity.model-small.max`: 1
- `max_jobs_per_run`: 1
- `node_max_concurrent_jobs`: 1
- `ollama_num_parallel`: null

The planner reports both advertised lanes as dispatch-ready in dry-run status, but claim-active is false because CT101 still has no active `queue_lane`.

## Known warning

The planner may warn that historical `gemma4:e4b` jobs are not advertised by the tiny/small worker metadata. This is expected because those are old completed jobs from before lane-specific metadata. It is not an active dispatch blocker unless queued/running jobs appear with unsupported models.

## Next phase

Next phase should source-map and design the actual lane claim activation path before enabling any worker-side `LAPTOP_QUEUE_QUEUE_LANE`.
