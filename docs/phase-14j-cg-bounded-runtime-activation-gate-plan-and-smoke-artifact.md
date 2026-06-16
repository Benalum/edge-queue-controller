# Phase 14J-CG - Bounded Runtime Activation Gate Plan and Smoke Artifact

PHASE_14J_CG_BOUNDED_RUNTIME_ACTIVATION_GATE_PLAN_AND_SMOKE_ARTIFACT

## Mutation scope

MUTATION_SCOPE=docs_smoke_only_activation_gate_plan

This phase creates a bounded activation gate plan and a focused smoke artifact. It does not activate runtime behavior.

Runtime status for this phase:

- RUNTIME_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKERS_ENABLED=not_enabled
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- CT101_MODEL_JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- DB_MUTATION=not_performed
- PRODUCTION_JOB_MUTATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved

## Why this phase exists

Phase 14J-CF left the project at a clean source-refresh handoff checkpoint. The corrected new-chat bootstrap proved the repository and DB were healthy, but also found that the current Source bootstrap wording was stale: the actual DB metadata table is `workers`, not `worker_registry`.

SOURCE_BOOTSTRAP_CORRECTION=worker_registry_to_workers
ACTUAL_WORKER_TABLE=workers

Phase 14J-CG converts the successful read-only activation inventory into a bounded activation gate plan. This prepares the next step without enabling lane workers.

## Current verified input state

The corrected bootstrap and CG inventory established:

- repository checkpoint was `eace367`
- `HEAD == origin/main == eace367`
- Phase 14J-CF tag was present at HEAD
- quick CF handoff smoke passed
- SQLite `PRAGMA quick_check` returned `ok`
- actual worker metadata table is `workers`
- canonical 8 lane metadata columns are present on `workers`
- worker count was zero
- lane-enabled worker count was zero
- non-default worker lane count was zero
- non-primary worker role count was zero
- shell `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` was unset
- service `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` was unset
- controller service was active and enabled
- no runtime activation occurred

## Activation remains blocked after CG

Activation remains blocked after this phase.

ACTIVATION_APPROVAL_REQUIRED=yes
ROLLBACK_REQUIRED_BEFORE_RUNTIME=yes
RUNTIME_ACTIVATION_BLOCKED_UNTIL_EXPLICIT_USER_APPROVAL=yes

A future runtime phase must not be bundled into this docs/smoke phase.

## Activation gate model

The next runtime-adjacent work must be split into bounded gates.

### Gate A - controller-side lane filter flag gate

Purpose:

- Test the controller-side `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` gate in a bounded way.
- Do not start CT101 lane workers.
- Do not call CT101.
- Do not call model or Ollama endpoints.
- Do not mutate production jobs.
- Do not activate router rollout or warmup execution.
- Do not enable scheduler lane dispatch or primary-worker filtering beyond the already-gated helper path unless separately approved.

Expected activation mechanism for a later approved runtime phase:

1. Capture pre-activation evidence.
2. Create a temporary systemd drop-in for `edge-queue-controller.service` that sets `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1`.
3. Reload systemd manager configuration.
4. Restart or reload `edge-queue-controller` only if explicitly approved for that runtime phase.
5. Capture post-activation evidence.
6. Run a focused activation smoke.
7. If anything fails, immediately execute the rollback path.

The exact future activation command must be generated in the later runtime phase, not in CG.

### Gate B - persistent lane worker availability gate

Purpose:

- Only after Gate A is safe, introduce an actual persistent lane worker path.
- This may require CT101 or worker-side work and must have its own explicit approval.
- CT101/model/Ollama calls remain forbidden unless that future phase explicitly approves them.

Gate B must not be mixed into Gate A.

### Gate C - scheduler lane dispatch gate

Purpose:

- Only after worker availability and rollback are proven, activate scheduler lane dispatch behavior.
- Scheduler lane dispatch must not be activated in the same phase as first controller flag activation.

### Gate D - primary-worker filtering gate

Purpose:

- Only after scheduler lane dispatch is proven safe, consider any primary-worker filtering behavior.
- Primary-worker filtering must remain blocked until no-lane job behavior and rollback are proven.

## Required pre-activation checks for the next runtime phase

Before any future runtime activation attempt, the phase must prove:

1. Repo is clean.
2. `HEAD == origin/main`.
3. Starting tag is known.
4. CF and CG focused smokes pass.
5. SQLite quick check returns `ok`.
6. Actual worker metadata table is `workers`.
7. Canonical lane metadata columns exist on `workers`.
8. `disabled_reason` is not required as a canonical Phase 14J lane metadata column.
9. Lane-enabled worker count is zero before activation unless the phase explicitly approves a worker row change.
10. Non-default lane count is zero before activation unless the phase explicitly approves a worker row change.
11. Non-primary worker role count is zero before activation unless the phase explicitly approves a worker row change.
12. `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent or disabled in shell.
13. `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent or disabled in service env.
14. Jobs table is read-only inspected only.
15. No production job mutation is required.
16. No DB mutation is required for Gate A.
17. No CT101/model/Ollama call is required for Gate A.
18. A rollback path is written before activation.
19. A post-rollback smoke exists before activation.
20. The user explicitly approves the runtime phase.

## Required activation evidence for the next runtime phase

A future runtime phase must capture:

- service active state before activation
- service enabled state before activation
- service env before activation
- shell env before activation
- DB quick check before activation
- worker lane/default-off counts before activation
- job status summary before activation
- exact activation change made
- service active state after activation
- service env after activation
- DB quick check after activation
- worker lane/default-off counts after activation
- job status summary after activation
- focused activation smoke result
- rollback smoke result if rollback is performed

## Rollback path for the next runtime phase

A future runtime phase must be able to return to the exact pre-activation defaults:

- remove or disable the temporary service env override for `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- reload systemd manager configuration if a drop-in was changed
- restart or reload `edge-queue-controller` only if that runtime phase approved service restart/reload
- verify shell flag is absent or disabled
- verify service flag is absent or disabled
- verify SQLite quick check is `ok`
- verify `workers` lane-enabled count is zero unless a later approved worker-row phase intentionally changes it
- verify scheduler lane dispatch remains disabled
- verify primary-worker filtering remains disabled
- verify CT101/model/Ollama calls did not occur unless separately approved
- verify no production job mutation occurred
- run focused rollback smoke
- capture rollback evidence in docs

## Abort rules

Abort before activation if any of these are true:

- repo is dirty
- `HEAD != origin/main`
- expected starting tag is missing
- SQLite quick check is not `ok`
- actual worker metadata table is not `workers`
- canonical lane metadata columns are missing
- service flag is already enabled before activation
- shell flag is already enabled before activation
- unexpected lane-enabled workers exist
- unexpected non-primary worker roles exist
- production job mutation would be required
- CT101/model/Ollama call would be required for Gate A
- rollback command/path is not written
- rollback smoke is missing
- user approval is not explicit

Abort after activation and roll back immediately if any of these are true:

- service does not return active
- service env does not match expected activation state
- DB quick check fails
- no-lane/default behavior is not proven safe
- lane-required behavior does not fail safe when no lane worker exists
- any unapproved job mutation occurs
- any unapproved CT101/model/Ollama call occurs
- any scheduler/primary-worker behavior changes outside the approved gate

## CG result

CG creates planning evidence only.

NEXT_SAFE_PHASE=bounded_runtime_activation_gate_preflight_or_explicit_activation_request
RUNTIME_ACTIVATION=not_performed
