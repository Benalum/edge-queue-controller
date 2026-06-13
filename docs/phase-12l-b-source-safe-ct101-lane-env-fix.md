# Phase 12L-B Source-Safe CT101 Lane Env Fix

Phase 12L-B fixed the dormant CT101 lane-worker env files after the first controlled tiny-lane activation attempt failed before worker registration.

## Failure observed

The tiny lane worker failed during `ExecStartPre` preflight.

The service log showed:

- `/etc/ai-platform/laptop-queue-worker-model-tiny.env: line 5: model-tiny: command not found`

## Root cause

The dormant lane env files contained unquoted values with spaces:

- `LAPTOP_QUEUE_WORKER_NAME=CT101 model-tiny lane worker`
- `LAPTOP_QUEUE_WORKER_NODE_NAME=CT101 model-tiny lane node`

The worker preflight sources env files with bash. Unquoted spaces caused bash to interpret part of the value as a command.

## Fix applied

The dormant lane env names were changed to source-safe underscore values.

Tiny lane:

- `LAPTOP_QUEUE_WORKER_NAME=CT101_model_tiny_lane_worker`
- `LAPTOP_QUEUE_WORKER_NODE_NAME=CT101_model_tiny_lane_node`

Small lane:

- `LAPTOP_QUEUE_WORKER_NAME=CT101_model_small_lane_worker`
- `LAPTOP_QUEUE_WORKER_NODE_NAME=CT101_model_small_lane_node`

## Verification

Verification passed:

- Tiny env source test passed.
- Small env source test passed.
- Tiny override preflight passed.
- Small override preflight passed.
- Tiny lane service remained inactive.
- Small lane service remained inactive.
- Primary worker remained active.
- Controller still saw only the primary unfiltered worker.
- No active queued/running `ollama_chat` jobs existed.
- Router rollout remained parked.

## Safety state

No lane worker was left running.
No test job was inserted.
Primary worker was active after the fix.
