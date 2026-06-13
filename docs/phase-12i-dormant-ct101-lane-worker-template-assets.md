# Phase 12I Dormant CT101 Lane Worker Template Assets

Phase 12I installed dormant CT101 lane-worker template assets.

## Result

Installed on CT101:

- `/etc/systemd/system/ai-platform-laptop-queue-worker@.service`
- `/opt/ai-platform/ops/runtime/laptop-queue-worker-instance-loop.sh`
- `/etc/ai-platform/laptop-queue-worker-model-tiny.env`
- `/etc/ai-platform/laptop-queue-worker-model-small.env`

## Tiny lane dormant env

- Worker id: `ct101-stage5g21-managed-browser-model-tiny`
- Worker node id: `ct101-stage5g21-managed-browser-node-model-tiny`
- Queue lane: `model-tiny`
- Allowed models: `qwen3:0.6b`
- Fallback model: `qwen3:0.6b`
- Max jobs per run: 1
- Node max concurrent jobs: 1

## Small lane dormant env

- Worker id: `ct101-stage5g21-managed-browser-model-small`
- Worker node id: `ct101-stage5g21-managed-browser-node-model-small`
- Queue lane: `model-small`
- Allowed models: `qwen3:1.7b`, `llama3.2:3b`
- Fallback model: `qwen3:1.7b`
- Max jobs per run: 1
- Node max concurrent jobs: 1

## Safety state

This phase installed dormant assets only.

- Tiny lane service remains inactive.
- Small lane service remains inactive.
- No lane service was enabled.
- No lane service was started.
- Primary worker service remains active.
- Primary worker env remains unfiltered.
- Controller still sees only the primary worker.
- No active queued/running `ollama_chat` jobs existed during verification.
- Router rollout remains parked.

## Backup

The install script created a CT101 backup under:

- `/opt/ai-platform/.stage-backups/phase12i-dormant-template-*`

## Next phase

Next phase should perform a one-lane controlled activation test, preferably `model-tiny` first, with no active user jobs and with rollback commands ready.
