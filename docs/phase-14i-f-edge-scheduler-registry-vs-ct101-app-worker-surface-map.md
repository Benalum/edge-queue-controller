# Phase 14I-F - Edge Scheduler Registry vs CT101 App Worker Surface Map

Status: inspection recorded

## Purpose

Phase 14I-F records the boundary between the Edge Queue Controller scheduler/worker registry surface and the CT101 app worker surface.

This phase does not enable workers.

## Scope

Allowed:

- Documentation
- Read-only smoke script
- Read-only local code inspection
- Read-only GET requests
- Redacted queue summary inspection
- Compile validation

Blocked:

- CT101 modification
- Persistent lane worker activation
- Router rollout
- Warmup execution
- Model generate/chat calls
- Model unloading
- Authentication weakening
- Runtime service mutation
- Power automation changes
- Service starts/stops/restarts
- Mutating HTTP calls
- Raw prompt/context dumping in future smokes

## Starting Checkpoint

- HEAD: 605bfef
- Tag: controller-phase-14i-e-persistent-lane-readiness-field-attachment-2026-06-15
- Phase 14I-A smoke: passed
- Phase 14I-B smoke: passed
- Phase 14I-C smoke: passed
- Phase 14I-D smoke: passed
- Phase 14I-E smoke: passed
- Repo status: clean
- Compile: passed

## Main Finding

There are two different worker/queue surfaces.

### Edge Queue Controller surface

Used by:

- `/workers/registry`
- `/scheduler/preview`
- local `jobs` table
- local `workers` table
- local `worker_events` table

Observed state:

- Edge worker registry total: 0
- Edge worker registry available: 0
- Edge scheduler queued jobs: 1
- Edge scheduler worker count: 0
- Job observed: 23
- Requested model observed: gemma4:e4b
- Selected worker: null
- Candidate workers: none

This is the surface that currently blocks Edge scheduler forwarding.

### CT101 app worker surface

Exposed through:

- `/system/status`
- `services[] -> id=ct101-laptop-queue-worker`
- Postgres `app_jobs`
- Postgres `app_workers`
- Postgres `app_worker_nodes`

Observed state:

- CT101 laptop queue worker service state: online
- CT101 service active: true
- CT101 worker id: ct101-stage5g21-managed-browser
- CT101 worker node id: ct101-stage5g21-managed-browser-node
- CT101 model: gemma4:e4b
- CT101 app queue queued: 0
- CT101 app queue running: 0
- CT101 app queue complete: 41
- CT101 app queue failed: 1

Observed CT101 worker metadata:

- Primary CT101 queue lane: null
- Supported lanes: model-tiny, model-small
- Allowed models: qwen3:0.6b, qwen3:1.7b, llama3.2:3b
- Lane dispatch claim filter enabled: false

Observed persistent lane cutover gate:

- ready: false
- reasons:
  - primary_worker_unfiltered
  - persistent_lane_workers_not_active
- warnings:
  - no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk

## Critical Boundary

The CT101 app worker being online does not populate the Edge Queue Controller `/workers/registry`.

The Edge scheduler uses the Edge worker registry and therefore still has no selectable worker.

The CT101 app worker status is useful evidence, but it is not the same as an available Edge scheduler worker.

## Privacy Finding

The Phase 14I-F inspection showed that raw `/queue/summary` can expose full queued prompt/context bodies.

Future smokes and terminal prompts should avoid dumping raw `/queue/summary` output.

Use redacted summaries that keep only safe fields such as:

- id
- job_type
- requested_model
- status
- attempts
- created_at
- updated_at
- forwarded_at
- user_id
- prompt_length

Do not print raw prompt or private context content during normal diagnostics.

## Current Decision

Do not enable workers yet.

Do not change CT101.

Do not enable router rollout.

Do not start warmup execution.

The next safe work should be a docs-only or read-only design step for the future bridge between:

1. Edge Queue Controller scheduler/registry needs.
2. CT101/app worker readiness evidence.
3. Persistent lane worker activation safety gates.
4. Privacy-safe diagnostics.

## Definition of Done

Phase 14I-F is complete when:

- This report exists.
- The read-only smoke script exists.
- The smoke script is executable.
- The smoke script verifies the Edge worker registry is empty.
- The smoke script verifies the Edge scheduler remains blocked with no selected worker.
- The smoke script verifies CT101 app worker status is online through `/system/status`.
- The smoke script verifies persistent cutover remains blocked.
- The smoke script redacts queued prompt/context content.
- The smoke script does not call mutating HTTP methods.
- The smoke script does not start/stop/restart/enable/disable services.
- The smoke script does not call model generate/chat endpoints.
- Compile passes.
- Smoke passes.
- Commit, tag, and push complete.
