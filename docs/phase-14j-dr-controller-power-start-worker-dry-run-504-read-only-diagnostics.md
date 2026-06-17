# Phase 14J-DR - Controller Power Start-Worker Dry-Run 504 Read-Only Diagnostics

PHASE_14J_DR_CONTROLLER_POWER_START_WORKER_DRY_RUN_504_READ_ONLY_DIAGNOSTICS

## Scope

MUTATION_SCOPE=docs_smoke_only_504_read_only_diagnostics_result_checkpoint

This phase records the completed read-only diagnostics for the Phase 14J-DN controller power start-worker dry-run HTTP 504 result.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated.

## Starting checkpoint

- START_HEAD=4b51d2d
- START_TAG=controller-phase-14j-dq-controller-power-start-worker-dry-run-504-diagnostics-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostics result

DR_DIAGNOSTICS_RESULT=completed_read_only_concise
DR_MUTATION_RESULT=none
DR_PRIOR_TIMEOUT_CAUSE=large_output_or_pipe_sigpipe

The first DR diagnostic attempt timed out because the diagnostic output was too large and hit a pipe/SIGPIPE path. The concise recovery diagnostics completed successfully.

## DN response finding

- DN_RESPONSE_EXISTS=yes
- DN_RESPONSE_JSON=yes
- DN_RESPONSE_TOP_KEYS=detail
- DN_RESPONSE_DETAIL=Timed out while querying Proxmox inventory over SSH.
- DN_SUMMARY_EXISTS=yes
- DN_DRY_RUN_CALL_RESULT=completed_http_non_2xx
- DN_DRY_RUN_HTTP_STATUS=504

## Source-path finding

- POWER_START_WORKER_PLAN_FOUND=yes
- POWER_START_WORKER_PLAN_USES_EDGE_PROXMOX_SSH_TARGET=yes
- POWER_START_WORKER_PLAN_HAS_DRY_RUN_NOTE=yes
- POWER_START_WORKER_PLAN_QUERIES_PROXMOX_INVENTORY=yes
- POWER_START_WORKER_PLAN_RETURNS_ELIGIBLE=yes
- POWER_START_WORKER_PLAN_RAISES_HTTP_EXCEPTION=yes
- POWER_START_WORKER_PLAN_DECLARED_NO_WORKER_START=yes

Key source facts observed in the read-only diagnostic:

- The dry-run endpoint is `/power/start-worker-plan`.
- The target remains `llms_ollama`.
- The dry-run endpoint says it does not start anything.
- The dry-run path reads `EDGE_PROXMOX_SSH_TARGET`.
- The 504 is caused by a Proxmox inventory-over-SSH timeout, not by a job, DB, worker-start, CT101, or model/Ollama mutation.

## Journal finding

- JOURNAL_RELEVANT_MATCH_COUNT=0

No recent sanitized controller journal lines matched the dry-run timeout path during the bounded log window.

## Safety state after diagnostics

- GIT_STATUS_AFTER=clean
- SERVICE_FLAG_REMAINED_UNSET=verified
- SQLITE_QUICK_CHECK_AFTER=ok
- JOB_SUMMARY_UNCHANGED=verified
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified
- PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified

## Decision

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
DRY_RUN_504_ROOT_CAUSE_AREA=proxmox_inventory_over_ssh_timeout
NEXT_DIAGNOSTIC_AREA=proxmox_inventory_ssh_timeout_read_only

The guarded worker start endpoint must not be called until the Proxmox inventory-over-SSH timeout is diagnosed and a safe dry-run plan returns a non-504 result.

## Next phase

NEXT_PHASE_NAME=phase-14j-ds-proxmox-inventory-ssh-timeout-diagnostics-plan

The next phase should be docs/smoke-only planning for read-only Proxmox inventory SSH timeout diagnostics. It should not call power execute endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, or activate scheduler/primary filtering.

## Boundaries preserved by DR

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

CONTROLLER_POWER_START_WORKER_DRY_RUN_504_READ_ONLY_DIAGNOSTICS_RESULT=completed

NEXT_SAFE_PHASE=proxmox_inventory_ssh_timeout_diagnostics_plan
