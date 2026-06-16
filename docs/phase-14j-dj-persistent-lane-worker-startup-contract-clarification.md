# Phase 14J-DJ - Persistent Lane Worker Startup Contract Clarification

PHASE_14J_DJ_PERSISTENT_LANE_WORKER_STARTUP_CONTRACT_CLARIFICATION

## Scope

MUTATION_SCOPE=docs_smoke_only_worker_startup_contract_clarification

This phase clarifies the contract after Phase 14J-DI correctly blocked persistent lane worker startup under a no-production-DB-mutation constraint.

No source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No worker is started. No runtime is activated in this phase.

## Starting checkpoint

- START_HEAD=4cc6fb8
- START_TAG=controller-phase-14j-di-persistent-lane-worker-startup-execution-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DI result carried forward

- PERSISTENT_LANE_WORKER_STARTUP_EXECUTION_GUARD_RESULT=blocked_without_mutation
- DI_EXECUTION_GUARD_RESULT=blocked_without_mutation
- BLOCK_REASON=no_proven_safe_no_production_db_mutation_worker_startup_path
- PERSISTENT_LANE_WORKER_STARTUP_PERFORMED=no
- PRODUCTION_STATE_UNCHANGED_AFTER_GUARD=verified
- SERVICE_FLAG_REMAINED_UNSET=verified
- JOB_SUMMARY_UNCHANGED=verified
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified
- RUNTIME_ACTIVATION_PERFORMED=no

## Clarified startup contract

PERSISTENT_LANE_WORKER_STARTUP_CONTRACT=requires_explicit_liveness_db_mutation_allowance

A real persistent lane worker startup cannot be treated as no-production-DB-mutation, because a healthy worker is expected to update at least one of these liveness-related fields or equivalent runtime records:

- state
- computed_health
- last_seen / last_heartbeat style timestamp
- current_running_jobs or capacity-style metadata
- worker process availability registration

Therefore the next safe execution path must explicitly allow bounded liveness/state/heartbeat DB updates while continuing to block job mutation, scheduler lane dispatch activation, primary-worker filtering activation, CT101 calls, and model/Ollama endpoint calls unless separately approved.

## Contract for next plan phase

NEXT_PHASE_NAME=phase-14j-dk-bounded-worker-liveness-startup-plan

The next phase should be docs/smoke-only planning for a bounded worker startup observation with this contract:

- ALLOW_BOUNDED_WORKER_LIVENESS_DB_MUTATION=yes
- ALLOW_JOB_MUTATION=no
- ALLOW_SERVICE_RESTART_RELOAD=no
- ALLOW_CT101_CALL=no
- ALLOW_MODEL_OLLAMA_CALL=no
- ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no
- ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no
- ALLOW_14J_AG_APPLY_WRAPPER_RERUN=no
- REQUIRE_PRE_POST_JOB_SUMMARY_COMPARE=yes
- REQUIRE_PRE_POST_SERVICE_FLAG_COMPARE=yes
- REQUIRE_PRE_POST_WORKER_ROW_COMPARE=yes
- REQUIRE_STOP_OR_ROLLBACK_INSTRUCTIONS=yes
- REQUIRE_EXPLICIT_APPROVAL_BEFORE_EXECUTION=yes

## Recommended approval model for later execution

The later execution approval should explicitly say that bounded worker liveness/state/heartbeat DB updates are allowed, but production job mutation, scheduler lane dispatch, primary-worker filtering, CT101 calls, and model/Ollama calls remain blocked.

## Boundaries preserved by DJ

- SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

PERSISTENT_LANE_WORKER_STARTUP_CONTRACT_CLARIFICATION_RESULT=completed

NEXT_SAFE_PHASE=bounded_worker_liveness_startup_plan
