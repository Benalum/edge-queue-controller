# Phase 12J Controlled One-Lane Activation Safety Plan

Phase 12J documents the safe activation plan for the first lane-specific worker test.

## Current state

The system is ready for a controlled `model-tiny` activation test, but no lane worker has been started yet.

Current verified state:

- Primary worker service is active.
- Primary worker remains unfiltered.
- Tiny lane service is inactive.
- Small lane service is inactive.
- Dormant tiny/small env files exist.
- Dormant systemd template exists.
- No active queued/running `ollama_chat` jobs existed during inspection.
- Router rollout remains parked.

## Key safety concern

The primary worker is still unfiltered.

If a `model-tiny` test job is created while the primary worker is active, the primary worker could claim it before the tiny lane worker does.

Therefore, a controlled test must temporarily stop the primary worker before starting the tiny lane worker.

## Future controlled tiny-lane test plan

1. Confirm no active queued/running `ollama_chat` jobs.
2. Stop the primary unfiltered worker:
   - `systemctl stop ai-platform-laptop-queue-worker.service`
3. Start only the tiny lane worker:
   - `systemctl start ai-platform-laptop-queue-worker@model-tiny.service`
4. Verify tiny worker registers as:
   - worker id: `ct101-stage5g21-managed-browser-model-tiny`
   - worker node id: `ct101-stage5g21-managed-browser-node-model-tiny`
   - queue lane: `model-tiny`
   - allowed model: `qwen3:0.6b`
5. Create one `qwen3:0.6b` test job with `queue_lane=model-tiny`.
6. Verify only the tiny lane worker claims and completes it.
7. Stop the tiny lane worker.
8. Restart the primary unfiltered worker.
9. Verify primary active, tiny inactive, small inactive, and queue empty.

## Rollback commands

Rollback at any point:

- `systemctl stop ai-platform-laptop-queue-worker@model-tiny.service`
- `systemctl stop ai-platform-laptop-queue-worker@model-small.service`
- `systemctl start ai-platform-laptop-queue-worker.service`

## Safety state

This phase is documentation and verification only.

No worker service was started.
No worker service was stopped.
No queue-lane claim was enabled.
No synthetic or real queued job was created.
