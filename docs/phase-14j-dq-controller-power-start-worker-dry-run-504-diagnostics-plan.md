# Phase 14J-DQ - Controller Power Start-Worker Dry-Run 504 Diagnostics Plan

PHASE_14J_DQ_CONTROLLER_POWER_START_WORKER_DRY_RUN_504_DIAGNOSTICS_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_controller_power_start_worker_dry_run_504_diagnostics_plan

This phase plans diagnosis for the Phase 14J-DN controller power start-worker dry-run HTTP 504 result.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated.

## Starting checkpoint

- START_HEAD=2540e19
- START_TAG=controller-phase-14j-dp-guarded-worker-start-decision-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DP decision carried forward

- GUARDED_WORKER_START_DECISION_PLAN_RESULT=blocked_pending_dry_run_504_diagnosis
- CONTROLLER_POWER_START_WORKER_DRY_RUN_RESULT_CHECKPOINT=completed
- CONTROLLER_POWER_START_WORKER_DRY_RUN_PHASE=completed
- POWER_ENDPOINT_CALL_IN_DN=performed_dry_run_only
- PLANNED_ENDPOINT=/power/start-worker-plan
- TARGET_NAME=llms_ollama
- DRY_RUN_HTTP_STATUS=504
- DRY_RUN_CALL_RESULT=completed_http_non_2xx
- CONTROLLER_POWER_START_WORKER_DRY_RUN_RESULT=completed_http_non_2xx
- DRY_RUN_RESPONSE_JSON=yes
- DRY_RUN_RESPONSE_TOP_KEYS=detail
- GUARDED_WORKER_START_ALLOWED=no
- GUARDED_WORKER_START_DECISION=blocked_pending_dry_run_504_diagnosis

## Diagnosis plan

DRY_RUN_504_DIAGNOSTICS_PLAN=ready_for_read_only_diagnostics

The next phase should perform read-only diagnostics only. It should not call `/power/start-worker-plan` again yet and should not call any execute endpoint.

The read-only diagnostics should inspect:

1. The saved DN response body at `/tmp/phase-14j-dn-start-worker-plan-response.json`, if present.
2. The saved DN summary at `/tmp/phase-14j-dn-start-worker-plan-summary.env`, if present.
3. The sanitized source path for `/power/start-worker-plan`.
4. The bounded source path around timeout-producing operations.
5. Recent controller logs using sanitized filters only.
6. Whether the dry-run path touches Proxmox/Tailscale/SSH reachability.
7. Whether the 504 came from endpoint timeout, controller internal timeout, or upstream proxy timeout.
8. Whether increasing client timeout for dry-run only would be safe later.
9. Whether a narrower read-only endpoint or smoke should be added later.

## Diagnostics boundaries for next phase

- ALLOW_POWER_ENDPOINT_CALL=no
- ALLOW_EXECUTE_POWER_ENDPOINT_CALL=no
- ALLOW_WORKER_START=no
- ALLOW_PRODUCTION_DB_MUTATION=no
- ALLOW_PRODUCTION_JOB_MUTATION=no
- ALLOW_SERVICE_RESTART_RELOAD=no
- ALLOW_CT101_CALL=no
- ALLOW_MODEL_OLLAMA_CALL=no
- ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no
- ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no
- ALLOW_RUNTIME_ACTIVATION=no
- ALLOW_SOURCE_MUTATION=no
- REQUIRE_SANITIZED_LOG_FILTERS=yes
- REQUIRE_NO_SECRET_PRINTING=yes

## Decision

Because the dry-run returned HTTP 504, a guarded worker start remains blocked until read-only 504 diagnostics identify the cause and a safe next step.

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
DRY_RUN_504_DIAGNOSIS_REQUIRED=yes

## Next phase

NEXT_PHASE_NAME=phase-14j-dr-controller-power-start-worker-dry-run-504-read-only-diagnostics

## Boundaries preserved by DQ

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

CONTROLLER_POWER_START_WORKER_DRY_RUN_504_DIAGNOSTICS_PLAN_RESULT=ready_for_read_only_diagnostics

NEXT_SAFE_PHASE=controller_power_start_worker_dry_run_504_read_only_diagnostics
