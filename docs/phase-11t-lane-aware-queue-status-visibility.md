# Phase 11T Lane-Aware Queue Status Visibility

Phase 11T exposes queue lane visibility for the model-lane contract added in Phase 11R and proven live in Phase 11S.

## What changed

The controller now builds a lane-aware summary from `app_jobs.payload_json` and exposes it in queue status data.

New summary fields include:

- `by_status_tier_lane`
- `active_by_queue_lane`
- `model_tier`
- `model_lane`
- `queue_lane`
- `requested_model`
- `count`

## Safety boundary

This phase is visibility only.

It does not:

- migrate schema
- change worker claim behavior
- change scheduling
- change worker concurrency
- change Ollama parallelism
- enable router rollout

## Purpose

Before enabling multiple model lanes or parallel workers, the system needs observability for queued, running, complete, and failed jobs by lane.
