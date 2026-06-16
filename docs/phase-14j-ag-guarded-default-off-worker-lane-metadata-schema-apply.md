# Phase 14J-AG Guarded Default-Off Worker Registry Lane Metadata Schema Apply

Phase 14J-AG performed the explicitly approved guarded SQLite schema mutation for default-off worker registry lane metadata.

## Starting checkpoint

- Required HEAD / origin/main: 1215a56
- Required tag: controller-phase-14j-af-guarded-schema-apply-decision-checkpoint-2026-06-15
- Required confirmation phrase: APPLY_DEFAULT_OFF_WORKER_LANE_METADATA

## Safety boundaries

This phase was DB/schema-only.

It did not:

- enable persistent lane workers
- restart or reload services
- call CT101
- call live model endpoints
- mutate job 23
- activate router rollout
- add scheduler lane dispatch behavior

## Required pre-apply checks

- edge_queue.sqlite3 exists
- workers table exists
- SQLite quick_check passes
- EDGE_PERSISTENT_LANE_WORKERS_ENABLED is absent/disabled
- target lane metadata columns are absent before apply
- timestamped DB backup is created before mutation

## Target columns

- worker_role
- worker_lane
- accepts_lane_jobs
- capabilities
- disabled
- current_running_jobs
- state
- computed_health

## Post-apply verification

Post-apply verification must prove:

- SQLite quick_check passes
- all target columns exist
- existing workers remain default-off for lane jobs
- focused smokes pass

## Rollback note

A timestamped backup was created before mutation outside the repository under:

~/apc-db-backups/edge-queue-controller/

Do not proceed to writer, scheduler, router, CT101, or live-model phases unless this phase is committed, tagged, pushed, and Source is updated.

<!-- phase14jag-observed-apply-facts:start -->
## Observed apply facts from Phase 14J-AG resume

- Main pre-mutation backup: /home/alex/apc-db-backups/edge-queue-controller/phase-14j-ag-guarded-default-off-worker-lane-metadata-schema-apply-20260616T023420Z-edge_queue.sqlite3
- Main backup size bytes: 42217472
- Main backup sha256: 91dddd338383844285f7dd336da924c210bb0289b94acf174af5d1c39cc422e7
- Wrapper-created backup: /home/alex/apc-db-backups/edge-queue-controller/wrapper-backups/edge_queue.sqlite3.phase14j-lane-metadata.20260616T023422Z.bak
- Wrapper backup size bytes: 42217472
- Wrapper backup sha256: 91dddd338383844285f7dd336da924c210bb0289b94acf174af5d1c39cc422e7
- Target columns verified after apply: worker_role, worker_lane, accepts_lane_jobs, capabilities, disabled, current_running_jobs, state, computed_health
- Worker count at verification: 0
- Lane-enabled worker count at verification: 0
- Persistent lane worker flag remained absent/disabled.
- The wrapper was not rerun during resume.
- No service restart/reload, CT101 call, live model endpoint call, router activation, scheduler activation, or job 23 mutation was performed.
<!-- phase14jag-observed-apply-facts:end -->
