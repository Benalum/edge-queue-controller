# Phase 14J-AW lane worker activation preconditions matrix

Phase 14J-AW records the preconditions matrix required before any future persistent lane worker activation.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `0272c34`
- Base tag: `controller-phase-14j-av-worker-registration-compatibility-closeout-and-next-lane-readiness-plan-2026-06-15`
- Phase 14J-AV status: complete, verified, tagged, pushed
- Repository state before 14J-AW: clean

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- change `/workers/heartbeat`
- change worker registration SQL
- change `WorkerHeartbeatRequest`
- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- restart or reload services
- call CT101
- call live model endpoints
- mutate job 23
- activate scheduler lane dispatch
- activate primary-worker filtering
- enable router model selection
- expose router output
- start warmup execution
- start persistent lane workers
- create lane worker services
- change service environment drop-ins

Schema presence is not runtime activation. Registration metadata wiring is not runtime activation. Service reload success is not lane dispatch activation. A preconditions matrix is not activation.

## Preconditions matrix

| Area | Required before activation | Current status |
| --- | --- | --- |
| Repo checkpoint | Clean repo, HEAD/origin/tag aligned | Required every phase |
| Controller health | `edge-queue-controller` active and local health 200 | Required before activation |
| DB schema | Worker metadata columns present | Satisfied by 14J-AG |
| Registration writes | INSERT and UPDATE preserve/default-off metadata | Satisfied through 14J-AO/AS |
| Worker registry | No unintended lane-enabled workers | Must remain zero |
| Primary fallback | Primary worker remains unfiltered unless explicitly replaced by fallback design | Blocked |
| No-lane jobs | Current and recent no-lane job risk must be inspected | Pending read-only evidence |
| Lane job contract | Job creation must tag lane-requiring jobs intentionally | Pending |
| Lane worker registry | Lane workers must be registered, recent, and default-safe before use | Pending |
| Dispatch gate | `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` must remain disabled until explicit activation approval | Blocked |
| Rollback | One-command disable path must be documented before activation | Pending |
| Smokes | Disabled-path, synthetic-enabled-path, and rollback smokes required | Pending |
| CT101 boundary | No CT101 mutation until separately approved | Blocked |
| Router boundary | Router rollout remains parked | Blocked |
| Warmup boundary | Warmup execution remains disabled | Blocked |

## Activation blockers that remain

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `no_lane_job_census_pending`
- `fallback_worker_contract_pending`
- `rollback_smoke_pending`
- `synthetic_enabled_lane_smoke_pending`

## Required evidence before any activation phase

A later read-only evidence phase should collect:

1. controller health
2. service environment lane flag state
3. SQLite worker registry lane metadata counts
4. current workers and their lane metadata
5. current queued/running job lane metadata
6. recent no-lane jobs after lane contract
7. fallback worker availability
8. lane worker service definitions, if any exist
9. disabled-path scheduler equivalence
10. rollback instructions

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-AX lane worker activation evidence inspection, read-only only

That phase should collect evidence only. It must not activate persistent lane workers, dispatch lanes, filter primary workers, call CT101, call models, mutate jobs, or restart services.
