# Phase 12O-B Read-Only Persistent Cutover Readiness Gate

Phase 12O-B adds a public-safe read-only `persistent_lane_cutover_readiness` status field to the CT101 laptop queue worker status payload.

## Purpose

The gate prevents accidental permanent lane cutover before the system is safe.

It reports whether CT101 is ready to replace the unfiltered primary worker with persistent lane-filtered workers.

## Status field

The new field is:

- `persistent_lane_cutover_readiness`

It is added beside:

- `registered_capacity`
- `lane_dispatch_readiness`

## Source

The helper source is:

- `stage_5p12o_read_only_persistent_lane_cutover_gate`

## Safety

The helper is read-only.

It does not:

- start services
- stop services
- enable services
- disable services
- restart workers
- claim jobs
- mutate queue rows
- change route behavior
- enable persistent lane cutover

## Expected current result

The gate should currently report:

- `dry_run_only=true`
- `ready=false`

Expected reasons include:

- `primary_worker_unfiltered`
- `historical_no_lane_jobs_detected`
- `no_no_lane_fallback_worker`
- `persistent_lane_workers_not_active`

## Why ready is false

The model-tiny and model-small controlled lane tests passed, but permanent cutover is still unsafe because:

- the primary worker is still unfiltered
- historical no-lane jobs exist
- there is no no-lane fallback worker
- persistent lane workers are not active

A future no-lane job could be stranded if the primary worker is stopped and only lane-filtered workers are running.

## Required before persistent cutover

Persistent cutover should remain blocked until at least one of these is true:

1. all production job creation paths are guaranteed to create supported queue lanes, or
2. a safe no-lane fallback worker exists.

## Runtime safety state

After this phase:

- primary worker should remain active
- tiny lane service should remain inactive
- small lane service should remain inactive
- no active queued/running jobs should exist
- router rollout should remain parked
