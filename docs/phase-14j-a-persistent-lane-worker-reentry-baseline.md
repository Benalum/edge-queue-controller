# Phase 14J-A Persistent Lane Worker Re-entry Baseline

Phase 14J-A begins the next major part after parking router shadow evidence work at Phase 14I-AZ.

This phase is docs/smoke only.

## Scope

This phase records a read-only baseline for persistent lane worker blocker re-entry.

This phase does not implement persistent lane workers.

This phase does not change scheduler behavior.

This phase does not filter the primary worker yet.

This phase does not call live model endpoints.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not enable warmup execution.

This phase does not enable router model selection.

## Current Checkpoint

Latest completed checkpoint before this phase:

- Phase 14I-AZ router shadow evidence park-or-proceed checkpoint.
- `queued_chat_router_shadow_evidence` schema has been applied.
- Router shadow evidence writer remains absent.
- Runtime router shadow evidence persistence remains absent.
- Router model selection remains disabled.
- Router activation remains parked.

## Active Blockers Re-entered

This phase re-enters the following blockers:

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `warmup_execution_disabled`
- `router_rollout_parked`
- `ct101_runtime_protected`

## Persistent Lane Worker Goal

The persistent lane worker work should eventually make worker assignment safer and more predictable.

The project should be able to distinguish:

- general workers,
- primary/default workers,
- lane-specific workers,
- disabled workers,
- stale workers,
- unhealthy workers,
- offline workers.

The future lane worker implementation should reduce accidental routing to the wrong worker class.

## Primary Worker Filtering Goal

The primary worker filtering work should eventually prevent a general/default worker from taking work that belongs to a protected lane unless explicitly allowed.

Future filtering must preserve current live behavior until a separate implementation phase is approved.

## Re-entry Inspection Targets

The next read-only inspections should focus on:

- worker registration surfaces,
- worker status and heartbeat surfaces,
- job assignment and scheduler surfaces,
- queue dispatch surfaces,
- worker capability filters,
- lane/pool labels if present,
- fallback behavior,
- disabled/stale/unhealthy/offline handling,
- current environment gates.

## Safety Boundaries

Future persistent lane worker phases must not:

- mutate CT101 unless explicitly planned and gated,
- call live model endpoints unless explicitly planned and gated,
- mutate job 23,
- expose secrets,
- expose raw prompts,
- expose raw messages,
- expose raw request bodies,
- expose full job payloads,
- remove legacy fallback yet,
- gate backend direct `/jobs` yet,
- remove Study UI `requested_model` yet,
- enable router model selection yet,
- enable warmup execution yet.

## Router Evidence Parked State

Router evidence work is parked after Phase 14I-AZ.

Parked means:

- schema exists and is applied,
- writer helper is not created,
- runtime persistence is not active,
- browser exposure does not exist,
- router model selection remains disabled,
- router activation remains parked.

## Next Safe Step

After this baseline, the next safe phase should be a read-only implementation surface inspection for persistent lane workers and primary worker filtering.

No runtime behavior should change until the relevant surface is inspected and a narrow implementation phase is approved.
