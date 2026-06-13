# Phase 12G Lane Claim Execution Readiness Source Map

Phase 12G inspected whether lane-specific worker claiming can be safely enabled later.

## Result

The source map confirms the pieces exist for future lane-specific claims:

- Controller job creation writes `model_tier`, `model_lane`, `queue_lane`, and `requested_model`.
- Controller claim endpoint accepts optional `queue_lane`.
- Controller claim helper filters with `payload_json->>'queue_lane'` when a lane is supplied.
- CT101 `LaptopQueueClient.claim_one()` accepts optional `queue_lane`.
- CT101 bounded poller reads `LAPTOP_QUEUE_QUEUE_LANE`.
- CT101 bounded poller sends `queue_lane` to the claim endpoint only when set.
- CT101 `call_ollama()` uses `job.requested_model` first, falling back to `LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK`.
- No active queued/running `ollama_chat` jobs existed during inspection.

## Safety state

No runtime lane claiming was enabled.

- `LAPTOP_QUEUE_QUEUE_LANE` remains unset.
- `OLLAMA_NUM_PARALLEL` remains unset.
- `LAPTOP_QUEUE_MAX_JOBS_PER_RUN` remains 1.
- `LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS` remains 1.
- CT101 worker service remains active.
- Router rollout remains parked.

## Available models

Ollama inventory confirmed these models exist:

- `qwen3:0.6b`
- `qwen3:1.7b`
- `llama3.2:3b`
- `gemma3:4b`
- `gemma4:e4b`

## Important design finding

A single CT101 worker service can only actively claim one queue lane if `LAPTOP_QUEUE_QUEUE_LANE` is set.

That means enabling `LAPTOP_QUEUE_QUEUE_LANE=model-tiny` on the current single service would make that worker ignore `model-small` jobs.

For real tiny+small concurrency, a later phase should create separate worker service instances or a multi-lane worker supervisor, for example:

- `ai-platform-laptop-queue-worker@model-tiny`
- `ai-platform-laptop-queue-worker@model-small`

Each instance should have its own worker id, worker node id, queue lane, and safe capacity limits.

## Recommendation

Do not enable lane claims yet.

Next phase should inspect and design the safest worker-instance strategy before setting any active `LAPTOP_QUEUE_QUEUE_LANE`.
