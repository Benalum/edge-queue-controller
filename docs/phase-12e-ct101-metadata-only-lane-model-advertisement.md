# Phase 12E CT101 Metadata-Only Lane/Model Advertisement

Phase 12E advertises CT101's supported model lanes and allowed models in registered worker metadata.

## Result

`/system/status` now reports metadata-only CT101 lane/model capacity through:

- `services[].registered_capacity.capabilities.supported_lanes`
- `services[].registered_capacity.capabilities.supported_model_tiers`
- `services[].registered_capacity.capabilities.allowed_models`
- `services[].registered_capacity.capabilities.lane_capacity`
- `services[].registered_capacity.capabilities.node_max_concurrent_jobs`

## Live metadata

For worker `ct101-stage5g21-managed-browser`:

- `supported_lanes`: `model-tiny`, `model-small`
- `supported_model_tiers`: `tiny`, `small`
- `allowed_models`: `qwen3:0.6b`, `qwen3:1.7b`, `llama3.2:3b`
- `lane_capacity.model-tiny.max`: 1
- `lane_capacity.model-small.max`: 1
- `node_max_concurrent_jobs`: 1
- `max_jobs_per_run`: 1

## Safety state

This was metadata-only.

No queue-lane claiming was enabled.
`LAPTOP_QUEUE_QUEUE_LANE` remains unset.
`OLLAMA_NUM_PARALLEL` remains unset.
`LAPTOP_QUEUE_MAX_JOBS_PER_RUN` remains 1.
CT101 worker service remains active.
Router rollout remains parked.

## CT101 env keys added

The following keys were added to `/etc/ai-platform/laptop-queue-worker.env`:

- `LAPTOP_QUEUE_SUPPORTED_LANES=model-tiny,model-small`
- `LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS=tiny,small`
- `LAPTOP_QUEUE_ALLOWED_MODELS=qwen3:0.6b,qwen3:1.7b,llama3.2:3b`
- `LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1`

## Backup

A CT101 backup was created before editing the env file under:

- `/opt/ai-platform/.stage-backups/phase12e-metadata-env-20260613-195148/`

## Next phase

Next phase should wire controller-side diagnostics/planning around the advertised lanes before any runtime lane claim is enabled.
