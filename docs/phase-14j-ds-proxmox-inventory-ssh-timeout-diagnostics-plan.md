# Phase 14J-DS - Proxmox Inventory SSH Timeout Diagnostics Plan

PHASE_14J_DS_PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSTICS_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_proxmox_inventory_ssh_timeout_diagnostics_plan

This phase plans the next read-only diagnostics for the Phase 14J-DN dry-run HTTP 504 result.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run. No worker is started. No runtime is activated.

## Starting checkpoint

- START_HEAD=890e63a
- START_TAG=controller-phase-14j-dr-controller-power-start-worker-dry-run-504-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DR finding carried forward

- CONTROLLER_POWER_START_WORKER_DRY_RUN_504_READ_ONLY_DIAGNOSTICS_RESULT=completed
- DN_RESPONSE_DETAIL=Timed out while querying Proxmox inventory over SSH.
- DN_DRY_RUN_HTTP_STATUS=504
- DN_DRY_RUN_CALL_RESULT=completed_http_non_2xx
- DRY_RUN_504_ROOT_CAUSE_AREA=proxmox_inventory_over_ssh_timeout
- NEXT_DIAGNOSTIC_AREA=proxmox_inventory_ssh_timeout_read_only
- POWER_START_WORKER_PLAN_USES_EDGE_PROXMOX_SSH_TARGET=yes
- POWER_START_WORKER_PLAN_QUERIES_PROXMOX_INVENTORY=yes
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Diagnosis objective

PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSTICS_PLAN=ready_for_explicit_read_only_diagnostics

The next phase should determine why the controller dry-run inventory lookup timed out over SSH. It should be read-only and bounded.

The diagnostics should answer:

1. Is the configured Proxmox SSH target present without printing the value?
2. Can the controller user resolve/reach the SSH target within a short timeout?
3. Is the timeout caused by DNS, Tailscale, SSH auth, Proxmox host offline, SSH command execution, or inventory command latency?
4. Does the dry-run path use a command that can hang longer than the client timeout?
5. Would a narrower inventory command or shorter internal timeout be safer?
6. Is a source patch needed to make `/power/start-worker-plan` fail fast instead of returning 504?

## Allowed diagnostics for next phase

The next phase may perform read-only, bounded checks only:

- CHECK_GIT_STATE=yes
- CHECK_SERVICE_STATE=yes
- CHECK_DB_READ_ONLY=yes
- CHECK_EDGE_PROXMOX_SSH_TARGET_PRESENT_REDACTED=yes
- CHECK_LOCAL_NETWORK_LISTENERS=yes
- CHECK_TAILSCALE_STATUS_REDACTED=yes
- CHECK_SSH_REACHABILITY_WITH_SHORT_TIMEOUT=yes
- CHECK_PROXMOX_INVENTORY_COMMAND_WITH_SHORT_TIMEOUT=yes
- CHECK_SANITIZED_RECENT_LOGS=yes

## Strict blocks for next phase

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
- ALLOW_APP_SOURCE_MUTATION=no
- ALLOW_GITHUB_BRANCH_OR_REPO_DELETE=no
- REQUIRE_SANITIZED_OUTPUT=yes
- REQUIRE_NO_SECRET_PRINTING=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes

## Decision

Because the dry-run returned HTTP 504 from a Proxmox inventory-over-SSH timeout, guarded worker start remains blocked.

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSIS_REQUIRED=yes

## Next phase

NEXT_PHASE_NAME=phase-14j-dt-proxmox-inventory-ssh-timeout-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-DT Proxmox inventory SSH timeout read-only diagnostics with sanitized output and short timeouts, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no GitHub branch or repository deletion, no full systemd environment printing, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DS

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- PROXMOX_SSH_CALL=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

PROXMOX_INVENTORY_SSH_TIMEOUT_DIAGNOSTICS_PLAN_RESULT=ready_for_explicit_read_only_diagnostics

NEXT_SAFE_PHASE=proxmox_inventory_ssh_timeout_read_only_diagnostics_requires_approval
