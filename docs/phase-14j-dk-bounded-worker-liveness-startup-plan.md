# Phase 14J-DK - Bounded Worker Liveness Startup Plan

PHASE_14J_DK_BOUNDED_WORKER_LIVENESS_STARTUP_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_bounded_worker_liveness_startup_plan

This phase plans a later bounded worker liveness startup execution after Phase 14J-DJ clarified that a real worker startup cannot remain a no-production-DB-mutation operation.

No source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No worker is started. No runtime is activated in this phase.

## Starting checkpoint

- START_HEAD=005b169
- START_TAG=controller-phase-14j-dj-persistent-lane-worker-startup-contract-clarification-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DJ contract carried forward

- PERSISTENT_LANE_WORKER_STARTUP_CONTRACT_CLARIFICATION_RESULT=completed
- PERSISTENT_LANE_WORKER_STARTUP_CONTRACT=requires_explicit_liveness_db_mutation_allowance
- DI_EXECUTION_GUARD_RESULT=blocked_without_mutation
- BLOCK_REASON=no_proven_safe_no_production_db_mutation_worker_startup_path
- PERSISTENT_LANE_WORKER_STARTUP_PERFORMED=no
- PRODUCTION_STATE_UNCHANGED_AFTER_GUARD=verified
- SERVICE_FLAG_REMAINED_UNSET=verified
- JOB_SUMMARY_UNCHANGED=verified
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified
- RUNTIME_ACTIVATION_PERFORMED=no

## Bounded worker liveness startup plan

BOUNDED_WORKER_LIVENESS_STARTUP_PLAN=ready_for_explicit_approval_execution

The next execution phase may allow only bounded worker liveness/state/heartbeat DB updates required to observe a worker startup. It must continue to block production job mutation, scheduler lane dispatch activation, primary-worker filtering activation, CT101 calls, model/Ollama calls, and rerunning the 14J-AG apply wrapper.

The next execution phase should:

1. Capture pre-execution service, DB, worker row, and job facts.
2. Verify `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is unset before execution.
3. Verify study lane metadata starts as `lane,study,1,0,offline,offline`.
4. Create a fresh SQLite backup before allowing liveness DB updates.
5. Use only a bounded worker startup observation path.
6. Allow only worker liveness/state/heartbeat-style DB updates.
7. Keep production jobs unchanged.
8. Keep scheduler lane dispatch disabled.
9. Keep primary-worker filtering disabled.
10. Avoid CT101 calls unless separately approved later.
11. Avoid model/Ollama endpoint calls.
12. Capture post-execution worker row facts.
13. Capture post-execution jobs summary.
14. Provide explicit stop/rollback instructions if a worker starts.
15. Commit/tag/push evidence only after state is known and safe.

## Allowed and blocked operations for later execution

- ALLOW_BOUNDED_WORKER_LIVENESS_DB_MUTATION=yes
- ALLOW_WORKER_LIVENESS_STATE_HEARTBEAT_UPDATES=yes
- ALLOW_PRODUCTION_JOB_MUTATION=no
- ALLOW_SERVICE_RESTART_RELOAD=no
- ALLOW_CT101_CALL=no
- ALLOW_MODEL_OLLAMA_CALL=no
- ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no
- ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no
- ALLOW_14J_AG_APPLY_WRAPPER_RERUN=no
- REQUIRE_SQLITE_BACKUP_BEFORE_LIVENESS_MUTATION=yes
- REQUIRE_PRE_POST_JOB_SUMMARY_COMPARE=yes
- REQUIRE_PRE_POST_SERVICE_FLAG_COMPARE=yes
- REQUIRE_PRE_POST_WORKER_ROW_COMPARE=yes
- REQUIRE_STOP_OR_ROLLBACK_INSTRUCTIONS=yes
- REQUIRE_EXPLICIT_APPROVAL_BEFORE_EXECUTION=yes

## Expected safe result of later execution

The expected safe result should be one of:

- worker_startup_observed_and_bounded_liveness_updates_recorded
- worker_startup_blocked_by_startup_plan_or_guard
- worker_startup_not_available_without_ct101_or_model_call

Any result must preserve:

- JOB_SUMMARY_UNCHANGED=verified
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- MODEL_OLLAMA_CALL=not_performed
- CT101_CALL=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved

## Next phase

NEXT_PHASE_NAME=phase-14j-dl-bounded-worker-liveness-startup-execution

Required approval text:

I approve Phase 14J-DL bounded worker liveness startup execution for the already-enabled study lane metadata row, allowing only bounded worker liveness/state/heartbeat DB updates, with no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DK

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

BOUNDED_WORKER_LIVENESS_STARTUP_PLAN_RESULT=ready_for_explicit_approval_execution

NEXT_SAFE_PHASE=bounded_worker_liveness_startup_execution_requires_approval
