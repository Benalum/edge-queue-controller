# Phase 14J-BJ - Rollback Safety Docs and Smoke Artifact

## Purpose

Phase 14J-BJ records the corrected Phase 14J-BI bootstrap result and adds a batched rollback/safety smoke artifact before any future runtime-adjacent lane worker work.

This phase is source-only and docs/smoke-only.

## Phase 14J-BI corrected bootstrap result

Phase 14J-BI completed as a read-only bootstrap/system check.

Confirmed:

- repository HEAD matched origin/main at `c048004`
- repository was clean
- expected Phase 14J-BH tag existed and pointed at HEAD
- `edge_controller.py` compiled
- `edge-queue-controller` was enabled and active
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` was absent/disabled in service and shell
- controller-only local health returned HTTP 200
- SQLite `PRAGMA quick_check` returned `ok`
- worker registry metadata remained default-off
- no schema wrapper was rerun
- no service restart or reload was performed
- no CT101, Ollama, or live model endpoint call was performed
- no production job was mutated
- scheduler lane dispatch, primary-worker filtering, router model selection, warmup execution, and persistent lane workers remained inactive

## Corrected canonical worker lane metadata column contract

The canonical Phase 14J worker registry lane metadata columns are:

- `worker_role`
- `worker_lane`
- `accepts_lane_jobs`
- `capabilities`
- `disabled`
- `current_running_jobs`
- `state`
- `computed_health`

Important correction:

- `disabled_reason` is not part of the canonical Phase 14J worker registry lane metadata schema.
- Any bootstrap or smoke that treats `disabled_reason` as required is incorrect for this checkpoint.

## Current safe state

Lane worker activation remains blocked.

The safe current state is:

- persistent lane workers are not active
- primary/default worker path remains unfiltered
- scheduler lane dispatch is not active
- CT101 runtime remains protected
- router rollout remains parked
- warmup execution remains disabled
- rollback smoke remains a blocker before activation
- explicit approval is required before any runtime activation

## Rollback safety requirements before any future activation

Before any future phase may activate persistent lane workers or scheduler lane dispatch, these rollback requirements must exist and pass:

1. A read-only baseline check confirms repo, service, health, SQLite, worker metadata, and lane env flags.
2. A rollback plan identifies every runtime change made by the activation phase.
3. The rollback path can return to the exact pre-activation defaults:
   - persistent lane worker env flag absent/disabled
   - scheduler lane dispatch disabled
   - primary/default worker path unfiltered
   - no-lane jobs still use the primary/default path
   - lane-tagged jobs without an eligible lane worker do not silently fall back to primary
4. Post-rollback smokes must prove:
   - controller health still works
   - SQLite quick_check remains ok
   - worker metadata remains present
   - `accepts_lane_jobs` count returns to zero unless an explicitly approved test worker is being inspected
   - no non-empty `worker_lane` values remain unless explicitly approved
   - no non-primary `worker_role` values remain unless explicitly approved
5. Service restart/reload remains approval-gated.
6. CT101, Ollama, live model endpoints, and production job mutations remain blocked unless a later phase explicitly approves them.

## Hard boundaries reaffirmed

This phase does not:

- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- restart or reload services
- call CT101
- call Ollama
- call live model endpoints
- mutate job 23 or any production job
- activate scheduler lane dispatch
- activate primary-worker filtering
- activate router model selection
- activate warmup execution
- activate persistent lane workers

## Next safe task

After this phase passes, the next safe task is a follow-up guarded phase that improves rollback verification coverage or prepares a runtime activation preflight checklist without enabling anything.
