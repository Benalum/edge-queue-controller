# Phase 12H CT101 Multi-Instance Worker Strategy Source Map

Phase 12H inspected the safest strategy for enabling lane-specific CT101 worker claims later.

## Result

The inspection confirms the current CT101 worker setup has:

- One active service: `ai-platform-laptop-queue-worker.service`
- One primary env file: `/etc/ai-platform/laptop-queue-worker.env`
- One active worker id: `ct101-stage5g21-managed-browser`
- One active worker node id: `ct101-stage5g21-managed-browser-node`
- `LAPTOP_QUEUE_QUEUE_LANE` unset
- `OLLAMA_NUM_PARALLEL` unset
- `LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1`
- `LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1`
- No active queued/running `ollama_chat` jobs during inspection

## Important design finding

A single worker service can only actively claim one queue lane when `LAPTOP_QUEUE_QUEUE_LANE` is set.

Therefore, setting `LAPTOP_QUEUE_QUEUE_LANE=model-tiny` on the existing primary service would make that worker ignore `model-small` jobs.

For real tiny/small lane separation, we should use separate worker service instances or a multi-lane supervisor.

## Recommended future service strategy

Use a systemd template:

- `ai-platform-laptop-queue-worker@.service`

Future tiny lane instance:

- Service: `ai-platform-laptop-queue-worker@model-tiny.service`
- Env file: `/etc/ai-platform/laptop-queue-worker-model-tiny.env`
- Worker id: `ct101-stage5g21-managed-browser-model-tiny`
- Worker node id: `ct101-stage5g21-managed-browser-node-model-tiny`
- Queue lane: `model-tiny`
- Allowed models: `qwen3:0.6b`
- Max jobs per run: 1
- Node max concurrent jobs: 1

Future small lane instance:

- Service: `ai-platform-laptop-queue-worker@model-small.service`
- Env file: `/etc/ai-platform/laptop-queue-worker-model-small.env`
- Worker id: `ct101-stage5g21-managed-browser-model-small`
- Worker node id: `ct101-stage5g21-managed-browser-node-model-small`
- Queue lane: `model-small`
- Allowed models: `qwen3:1.7b`, `llama3.2:3b`
- Max jobs per run: 1
- Node max concurrent jobs: 1

## Safety state

This was inspection-only.

No new service was created.
No template service was installed.
No queue-lane claim was enabled.
The current primary worker service remains unchanged.
Router rollout remains parked.

## Next phase

Next phase should create a dormant/proof-only systemd template and env-file plan, without starting lane-specific instances yet.
